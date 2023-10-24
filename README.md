# eMagisk

Installs useful binaries: bash, curl, nano, strace, eventrec and tcpdump. Also optionally installs Atlas services that ensure uptime.

-----
### TODOs
- Cleanup ATVServices.sh into separate files
- Add checks for RDM
- Add more performance optimization system props and tweaks
- Remove obsolete things
- Test and add jq binary
- Log rotation
- And several others

----
## Changelog
### 9.6.0
- Merged the root@tchavei / BubbleT fork into main
- This update requires to have a new emagisk.config file
- Added "rdm_check" option to the emagisk.config file
- This option lets you choose between both Health Monitors
  - 0 = Atlas Service Health Monitor (checks if the Atlas Mapping Service is running)
  - 1 = RDM Connection Monitor (checks the lastseen status of the device at RDM and restarts Atlas Service if needed)
- Uncommented / Enabled the Ethernet Port reset for the RDM Connection Monitor again
- This update will also add the curl binary since it's needed for the RDM Connection Monitor

### 9.5.0
- Enables Play Store again as Safety Net is being dropped by Play Integrity, the latter requiring an enabled and updated Play Store.

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
