# eMagisk

Standalone arm64-only Magisk shell module.

It installs bash, nano, curl, sqlite3, strace, tcpdump, eventrec, and stackplz, then seeds the packaged shell config into external storage:
- `.bashrc`
- `.inputrc`
- `.bash-completion/`

The installer preserves existing user dotfiles by only seeding files that are missing.

## Compatibility

`v4.0` starts a new standalone compatibility line for this branch.

- `arm64` only
- standalone branch only
- payload and release flow intentionally diverge from the old mixed-ABI / Atlas-era module history

----
## Changelog

### 4.0
- Breaking compatibility reset for the standalone branch.
- Standardizes the payload as arm64-only.
- Ships the validated standalone shell/tooling set: `bash`, `nano`, `curl`, `sqlite3`, `strace`, `tcpdump`, `eventrec`, and `stackplz`.
- Seeds `.bashrc`, `.inputrc`, and `.bash-completion/` into external storage without overwriting existing user files.
- Uses the `[build]`-gated GitHub release flow for publishing release zips.

----
## Legacy History

Older `9.x` / `10.x` entries below refer to the earlier Atlas-oriented eMagisk line and are preserved only as historical context.

### 10.0.0
- Removes everything related to Atlas

### 9.5.0
- Enables Play Store again as Safety Net is being dropped by Play Integrity, the latter requiring an enabled and updated Play Store.

### 9.3.2
- Completely refactored since last changelog. Targets ensuring Atlas stays online and has several health checks.
- Installation requires no manual intervention, but allows skipping the Atlas specific services with volume buttons.
- This version is the current most stable one, and works very well at ensuring Atlas errors are dealth with and ATVs don't stop scanning.

### 5.4
- Everything seems to be verkin.

### 4.0 (legacy line)
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
