##########################################################################################
# Config Flags
##########################################################################################

# Set to true if you do *NOT* want Magisk to mount
# any files for you. Most modules would NOT want
# to set this flag to true
SKIPMOUNT=false

# Set to true if you need to load system.prop
PROPFILE=true

# Set to true if you need post-fs-data script
POSTFSDATA=false

# Set to true if you need late_start service script
LATESTARTSERVICE=true

##########################################################################################
# Replace list
##########################################################################################

# List all directories you want to directly replace in the system
# Check the documentations for more info why you would need this

# Construct your list in the following format
# This is an example
REPLACE_EXAMPLE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

# Construct your own list here
REPLACE="
"

##########################################################################################
#
# Function Callbacks
#
# The following functions will be called by the installation framework.
# You do not have the ability to modify update-binary, the only way you can customize
# installation is through implementing these functions.
#
# When running your callbacks, the installation framework will make sure the Magisk
# internal busybox path is *PREPENDED* to PATH, so all common commands shall exist.
# Also, it will make sure /data, /system, and /vendor is properly mounted.
#
##########################################################################################
##########################################################################################
#
# The installation framework will export some variables and functions.
# You should use these variables and functions for installation.
#
# ! DO NOT use any Magisk internal paths as those are NOT public API.
# ! DO NOT use other functions in util_functions.sh as they are NOT public API.
# ! Non public APIs are not guranteed to maintain compatibility between releases.
#
# Available variables:
#
# MAGISK_VER (string): the version string of current installed Magisk
# MAGISK_VER_CODE (int): the version code of current installed Magisk
# BOOTMODE (bool): true if the module is currently installing in Magisk Manager
# MODPATH (path): the path where your module files should be installed
# TMPDIR (path): a place where you can temporarily store files
# ZIPFILE (path): your module's installation zip
# ARCH (string): the architecture of the device. Value is either arm, arm64, x86, or x64
# IS64BIT (bool): true if $ARCH is either arm64 or x64
# API (int): the API level (Android version) of the device
#
# Availible functions:
#
# ui_print <msg>
#     print <msg> to console
#     Avoid using 'echo' as it will not display in custom recovery's console
#
# abort <msg>
#     print error message <msg> to console and terminate installation
#     Avoid using 'exit' as it will skip the termination cleanup steps
#
# set_perm <target> <owner> <group> <permission> [context]
#     if [context] is empty, it will default to "u:object_r:system_file:s0"
#     this function is a shorthand for the following commands
#       chown owner.group target
#       chmod permission target
#       chcon context target
#
# set_perm_recursive <directory> <owner> <group> <dirpermission> <filepermission> [context]
#     if [context] is empty, it will default to "u:object_r:system_file:s0"
#     for all files in <directory>, it will call:
#       set_perm file owner group filepermission context
#     for all directories in <directory> (including itself), it will call:
#       set_perm dir owner group dirpermission context
#
##########################################################################################
##########################################################################################
# If you need boot scripts, DO NOT use general boot scripts (post-fs-data.d/service.d)
# ONLY use module scripts as it respects the module status (remove/disable) and is
# guaranteed to maintain the same behavior in future Magisk releases.
# Enable boot scripts by setting the flags in the config section above.
##########################################################################################

# Set what you want to display when installing your module

print_modname() {
    version=$(sed -n "s/^version=//p" $TMPDIR/module.prop)
    versionCode=$(sed -n "s/^versionCode=//p" $TMPDIR/module.prop)
    ui_print "░░░░░░░░░░░░░░░░░░░░░░░▒▒█████▒▒▒░░░░░░░░░░░░░░░░░░░░"
    ui_print "░░░░░░░░░░░░░░░░░▒▒██████████████████▒▒░░░░░░░░░░░░░░"
    ui_print "░░░░░░░░░░░░░░█▒█▒▒▒██░░░░░░░░░██▒███████▒█░░░░░░░░░░"
    ui_print "░░░░░░░░░░░░░▒█░░░░░░░░░░░░░░░░░░░░░▒▒██████░░░░░░░░░"
    ui_print "░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒████▒░░░░░░░"
    ui_print "░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒████▒░░░░░"
    ui_print "░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒████░░░░"
    ui_print "░░░░░░░░░░░░░░░░░░░░░░██░░░░░░░██░░░░░░░░░░░░▒████░░░"
    ui_print "░░░░░░░░░░░░░░░░░░░▒███▒░░░░░░░░▒██▒▒░░░░░░░░░▒███▒░░"
    ui_print "░░░░░░░░░░░░░░░░░░▒████▒░░▒▒▒░▒░▒███▒░░░░░░░░░▒████░░"
    ui_print "░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒███▒░▒░░████▒░░▒███▒░░░░░░░░▒████░░"
    ui_print "░░██████████████████▒▒░░███████▒░░▒████████████████░░"
    ui_print "░░██████████████████▒▒░░███████▒░░▒████████████████░░"
    ui_print "░░▒███▒░░░░░░░░░░▒███▒▒▒▒░████░░░▒███▒░░░░░░░░░░░░░░░"
    ui_print "░░░███▒░░░░░░░░░░░▒████▒▒░░░░░░▒▒███░░░░░░░░░░░░░░░░░"
    ui_print "░░░████▒░░░░░░░░░░░▒▒███░░░░░░░░██▒▒░░░░░░░░░░░░░░░░░"
    ui_print "░░░█████▒░░░░░░░░░░░░▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"
    ui_print "░░░░▒████▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"
    ui_print "░░░░░░█▒████▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"
    ui_print "░░░░░░░░▒█████▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"
    ui_print "░░░░░░░░░░▒▒█████▒█░░░░░░░░░░░░░░░░░░░▒▒▒░░░░░░░░░░░░"
    ui_print "░░░░░░░░░░░░▒▒████████▒▒█▒▒▒▒▒▒█▒▒▒▒██▒▒░░░░░░░░░░░░░"
    ui_print "░░░░░░░░░░░░░░░░░▒▒████████████████▒▒░░░░░░░░░░░░░░░░"
    ui_print ""
    ui_print " ___________________________________________________"
    ui_print "|                                                   |"
    ui_print "|             >   e M a g i s k   <                 |"
    ui_print "|                                                   |"
    ui_print "|                      by emi                       |"
    ui_print "|                                                   |"
    ui_print "|                                                   |"
    ui_print "|                                                   |"
    ui_print " ___________________________________________________"
    ui_print "|                                                   |"
    ui_print "|       Utility binaries, bash, pre-configs         |"
    ui_print "|                    all in one.                    |"
    ui_print "|                $version                           |"
    ui_print "|                                                   |"
    ui_print "|                                                   |"
    ui_print "|        by emi (@emi#0001) - emi@pokemod.dev       |"
    ui_print "|         Pokemod.dev  | Discord.gg/Pokemod         |"
    ui_print "|___________________________________________________| "
    ui_print " "
}

# Copy/extract your module files into $MODPATH in on_install.

on_install() {
    ui_print "- Extracting module files"
    unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2
    unzip -o "$ZIPFILE" 'custom/*' -d $TMPDIR >&2

    if [ -d /system/xbin ]; then
        BIN=/system/xbin
        mv $MODPATH/system/bin "$MODPATH$BIN"
    else
        BIN=/system/bin
    fi
    ui_print "- Setting BIN: $BIN."

    # Detect device ABI
    case "$ARCH" in
        arm)
            ui_print "- Detected architecture: arm"
            mv $MODPATH$BIN/nano.bin-arm $MODPATH$BIN/nano
            mv $MODPATH$BIN/bash-arm $MODPATH$BIN/bash
            ;;
        arm64)
            ui_print "- Detected architecture: arm64"
            mv $MODPATH$BIN/nano.bin-arm64 $MODPATH$BIN/nano
            mv $MODPATH$BIN/bash-arm64 $MODPATH$BIN/bash
            ;;
        x86)
            ui_print "- Detected architecture: x86 (unsupported)"
            abort "x86 is not supported."
            ;;
        x64)
            ui_print "- Detected architecture: x64 (unsupported)"
            abort "x64 is not supported."
            ;;
        *)
            ui_print "- Detected architecture: unknown"
            abort "Unsupported architecture: $ARCH"
            ;;
    esac

    # Cleanup unused binaries
    rm -f $MODPATH$BIN/nano.bin-*
    rm -f $MODPATH$BIN/bash-*

    ui_print "- Setting up mkshrc for the detected environment."
    if [ -d /sdcard ]; then
        SDCARD=/sdcard
    elif [ -d /storage/emulated/0 ]; then
        SDCARD=/storage/emulated/0
    fi
    ui_print "- Setting SDCARD: $SDCARD."

    sed -i "s|<SDCARD>|$SDCARD|g" $MODPATH/system/etc/mkshrc
    sed -i "s|<BIN>|$BIN|g" $MODPATH/system/etc/mkshrc

    ui_print "- Module files installed successfully!"
}

set_permissions() {
    set_perm_recursive $MODPATH 0 0 1755 0744
    set_perm_recursive $MODPATH$BIN 0 0 1755 0777
}
