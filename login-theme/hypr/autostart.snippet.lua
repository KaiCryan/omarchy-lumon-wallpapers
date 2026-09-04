-- Lumon login theme: start the unlock watcher (plays the Severance theme on
-- every unlock) and, if LOCK_ON_LOGIN, lock the screen at boot so a cold
-- login gets it too.
o.exec_on_start("lumon-login-theme login")
