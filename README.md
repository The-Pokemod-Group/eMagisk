# eMagisk

Installs useful binaries: bash, curl, nano, strace, eventrec and tcpdump. Also optionally installs Atlas services that ensure uptime.

---

## THIS IS A WIP

This fork is even more WIP than emi's. This fork focuses on using RDM as the device's heartbeat so to speak. Instead of checking directly for atlas process health status, it indirectly checks for it by checking RDM last seen time.

If last seen time is < 10 seconds, the device is considered live and healthy. If the last seen time is greater than 10 seconds but less than 5 minutes, a warning is recorded but no action is taken.

Once the the time diff between RDM and the device is >= 5 minutes, this daemon will force restart all atlas services while killing pokemon go (atlas is responsible to spawn it again). On X96 Mini and X96W Tvs, the status LED will turn RED to indicate a possible fault. The LED will turn BLUE once the daemon detects the device is live again on RDM.

If the above procedures fails 4 times in a row (16 minutes total) then the device is considered unrecoverable and a full reboot is triggered.

---

## Installation

If you really want to install this version, you have to:

1. Download the latest release (check tags)
2. adb push the magisk module into the device
3. `magisk --install-module magiskmodule.zip`
4. copy `emagisk.config` from `https://github.com/tchavei/eMagisk/blob/master/emagisk.config` into `/data/local/tmp` of your device
5. **Edit the file to match your RDM username, password and server IP:PORT**
6. `reboot`

Note: step 3 only works on Magisk versions 21.2 and forward. If you have an earlier Magisk version, install through Magisk Manager (scrcpy into the device) or update your Magisk.

## Changelog

### 9.4.0

Added several extra RDM and Internet checks (Bubble) and beta vs production environment check

### 9.3.9

Added LED status indicator for the X96 Mini and X96W. It might work with other ATVs that have a LED status indicator and led control is located under `/sys/class/leds/led-sys`

### 9.3.8

Pulled emi's bashrc changes

### 9.3.6

Added reboot logic into the check loop. Now the daemon will force a device reboot after 4 failed attempts at restarting Atlas services. Everything is RDM based. emagisk.config is mandatory.

Cleaned up obsolete functions.

### 9.3.3

Refactored check if alive logic to be RDM based instead of PID. WIP

For this version, it is required for you to add your basic RDM info in the emagisk.config file which has to be located inside the
/sdcard/Download/ folder. A sample emagisk.config is provided in the repo.

### 9.3.2

- Completely refactored since last changelog. Targets ensuring Atlas stays online and has several health checks.
- Installation requires no manual intervention, but allows skipping the Atlas specific services with volume buttons.
- This version is the current most stable one, and works very well at ensuring Atlas errors are dealth with and ATVs don't stop scanning.

### 5.4

- Everything seems to be verkin.

### 4.0

- Suddenly, things work. `bash` runs automatically when opening an `adb shell` without the need to recompile `adbd`.
- Also, following new practices and unity versions.

### 3.6

- Can't even make a changelog.

### 2.1

- Bash completion
- Auto installs busybox utilities
- Better aliases

### v1.1

- Trying to make `bash` open by default when running `adb shell` without having to recompile `adbd`.

### v1.0

- Project forked by @esauvisky
- New PS1, PS2 and PS3.
- Different aliases.
- A custom built `bash` binary.
- Other binaries bundled in, like `eventrec` and `strace`.
