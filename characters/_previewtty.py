#!/usr/bin/env python3
"""Run a command in a pty at a fixed size, replay its output through a tiny
terminal emulator, print the final screen as plain text (SGR stripped).
Non-invasive check that cursor-addressed layouts land where intended.

  _previewtty.py [--cols N] [--rows N] [--at SECONDS] -- CMD ARGS...

--at: kill the child this many seconds in and render whatever is on screen
      (default: let it finish).
"""
import os
import pty
import re
import select
import signal
import sys
import time

cols, rows, at = 100, 44, None
args = sys.argv[1:]
while args and args[0].startswith("--"):
    k = args.pop(0)
    if k == "--cols":
        cols = int(args.pop(0))
    elif k == "--rows":
        rows = int(args.pop(0))
    elif k == "--at":
        at = float(args.pop(0))
    elif k == "--":
        break
if args and args[0] == "--":
    args.pop(0)

pid, fd = os.forkpty()
if pid == 0:
    os.environ["COLUMNS"] = str(cols)
    os.environ["LINES"] = str(rows)
    os.environ.setdefault("COLORTERM", "truecolor")
    os.environ.setdefault("TERM", "xterm-256color")
    os.execvp(args[0], args)

try:
    import fcntl
    import struct
    import termios
    fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", rows, cols, 0, 0))
except Exception:
    pass

buf = b""
start = time.time()
while True:
    if at is not None and time.time() - start > at:
        os.kill(pid, signal.SIGKILL)
        break
    r, _, _ = select.select([fd], [], [], 0.2)
    if fd in r:
        try:
            chunk = os.read(fd, 65536)
        except OSError:
            break
        if not chunk:
            break
        buf += chunk
    else:
        done, _ = os.waitpid(pid, os.WNOHANG)
        if done:
            try:
                while True:
                    c = os.read(fd, 65536)
                    if not c:
                        break
                    buf += c
            except OSError:
                pass
            break
try:
    os.waitpid(pid, 0)
except OSError:
    pass

text = buf.decode("utf-8", "replace")
grid = [[" "] * cols for _ in range(rows)]
cr = cc = 0
i = 0
CSI = re.compile(r"\x1b\[([0-9;?]*)([A-Za-z])")


def clampr():
    global cr, cc
    cr = max(0, min(rows - 1, cr))
    cc = max(0, min(cols - 1, cc))


while i < len(text):
    ch = text[i]
    if ch == "\x1b":
        m = CSI.match(text, i)
        if not m:
            i += 1
            continue
        params, cmd = m.group(1), m.group(2)
        nums = [int(x) for x in params.split(";") if x.isdigit()]
        if cmd == "H" or cmd == "f":
            cr = (nums[0] - 1) if len(nums) >= 1 else 0
            cc = (nums[1] - 1) if len(nums) >= 2 else 0
            clampr()
        elif cmd == "A":
            cr -= nums[0] if nums else 1
        elif cmd == "B":
            cr += nums[0] if nums else 1
        elif cmd == "C":
            cc += nums[0] if nums else 1
        elif cmd == "D":
            cc -= nums[0] if nums else 1
        elif cmd == "J":
            n = nums[0] if nums else 0
            if n == 2:
                grid = [[" "] * cols for _ in range(rows)]
                cr = cc = 0
            elif n == 0:
                for x in range(cc, cols):
                    grid[cr][x] = " "
                for y in range(cr + 1, rows):
                    grid[y] = [" "] * cols
        elif cmd == "K":
            n = nums[0] if nums else 0
            if n == 0:
                for x in range(cc, cols):
                    grid[cr][x] = " "
            elif n == 1:
                for x in range(0, cc + 1):
                    grid[cr][x] = " "
            elif n == 2:
                grid[cr] = [" "] * cols
        clampr()
        i = m.end()
        continue
    if ch == "\r":
        cc = 0
    elif ch == "\n":
        cr += 1
        if cr >= rows:
            grid.pop(0)
            grid.append([" "] * cols)
            cr = rows - 1
    elif ch == "\t":
        cc = min(cols - 1, (cc // 8 + 1) * 8)
    elif ch >= " ":
        clampr()
        grid[cr][cc] = ch
        cc += 1
        if cc >= cols:
            cc = 0
            cr += 1
            if cr >= rows:
                grid.pop(0)
                grid.append([" "] * cols)
                cr = rows - 1
    i += 1

sep = "+" + "-" * cols + "+"
print(sep)
for row in grid:
    print("|" + "".join(row).rstrip().ljust(cols) + "|")
print(sep)
