# eMagisk

Installs useful binaries: bash, nano, strace, eventrec and tcpdump. Also optionally installs Atlas services that ensure uptime.

---

## THIS IS A WIP

### TODOs

- Cleanup ATVServices.sh into separate files
- Add checks for RDM
- Add more performance optimization system props and tweaks
- Remove obsolete things
- And several others

---

## Changelog

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
