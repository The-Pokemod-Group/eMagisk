#!/system/bin/sh
ATLASPKG=com.pokemod.atlas
UNINSTALLPKGS="com.ionitech.airscreen cm.aptoidetv.pt com.netflix.mediaclient org.xbmc.kodi com.google.android.youtube.tv"

force_restart() {
    am stopservice $ATLASPKG/.MappingService
    killall -9 $ATLASPKG/.MappingService
    killall -9 com.nianticlabs.pokemongo
    sleep 3s
    monkey -p com.pokemod.atlas 1
    sleep 3s
    am startservice $ATLASPKG/.MappingService
    monkey -p com.nianticlabs.pokemongo 1
}

download() {
    until wget --user-agent="Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6" "$1" -O "$2"; do
        rm -rf "$2"
        log "Download of ${1##*/} failed! Trying again..."
        sleep 10s
    done
}

checkUpdates() {
    while :; do
        log "Checking for updates..."

        until ping -c1 8.8.8.8 >/dev/null 2>/dev/null; do
            sleep 10s
        done

        currentVersion=$(cat "$MODDIR/version_lock")
        remoteVersion=$(wget http://storage.googleapis.com/pokemod/Atlas/version -O-)
        if [ ."$remoteVersion" != "." ] && [ "$remoteVersion" -gt "$currentVersion" ]; then
            log "There's a new version of eMagisk!"
            log "Updating from $currentVersion to $remoteVersion"

            download "http://storage.googleapis.com/pokemod/Atlas/3-eMagisk.zip" "<SDCARD>/eMagisk.zip"
            if [ -e "<SDCARD>/eMagisk.zip" ]; then
                log "Downloaded new version, rebooting to recovery and installing..."
                rm -rf "<SDCARD>/TWRP"
                mkdir -p /cache/recovery
                touch /cache/recovery/command
                echo '--update_package=<SDCARD>/eMagisk.zip' >>/cache/recovery/command
                echo '--wipe_cache' >>/cache/recovery/command
                sleep 10s
                reboot recovery
            else
                log "Something wrong happened and the file couldn't be downloaded!"
            fi
        elif [ ."$currentVersion" = ."$remoteVersion" ]; then
            log "eMagisk is up to date! Current version is $currentVersion"
        elif [ ."$remoteVersion" = "." ]; then
            log "Couldn't check for update, something wrong with the server :/"
            log "currentVersion: $currentVersion | remoteVersion: $remoteVersion"
        else
            log "Some error happened!"
            log "currentVersion: $currentVersion | remoteVersion: $remoteVersion"
        fi

        # WIP Pogo
        # currentVersion="$(dumpsys package com.nianticlabs.pokemongo|awk -F'=' '/versionName/{print $2}')"
        # remoteVersion=$(wget http://storage.googleapis.com/pokemod/Atlas/version -O-)

        # TODO: Atlas

        sleep 1h
    done
}

checkUpdates &

echo "$UNINSTALLPKGS" | tr ' ' '\n' | while read -r item; do
    if ! dumpsys package "$item" | \grep -qm1 "Unable to find package"; then
        log "Uninstalling $item..."
        pm uninstall "$item"
    fi
done

log "Enabling Play Store"
pm enable com.android.vending
# TODO:
# if [ "$(pm list packages -e com.android.vending)" = "package:com.android.vending" ]; then
#     log "Disabling Play Store"
#     pm disable-user com.android.vending
# fi

if ! magiskhide status; then
    log "Enabling MagiskHide"
    magiskhide enable
fi

if ! magiskhide ls | grep -m1 com.nianticlabs.pokemongo; then
    log "Adding PoGo to MagiskHide"
    magiskhide add com.nianticlabs.pokemongo
fi

for package in $ATLASPKG com.android.shell; do
    packageUID=$(dumpsys package "$package" | grep userId | head -n1 | cut -d= -f2)
    policy=$(sqlite3 /data/adb/magisk.db "select policy from policies where package_name='$package'")
    if [ "$policy" != 2 ]; then
        log "$package current policy is $policy. Adding root permissions..."
        if ! sqlite3 /data/adb/magisk.db "DELETE from policies WHERE package_name='$package'" ||
            ! sqlite3 /data/adb/magisk.db "INSERT INTO policies (uid,package_name,policy,until,logging,notification) VALUES($packageUID,'$package',2,0,1,1)"; then
            log "ERROR: Could not add $package (UID: $packageUID) to Magisk's DB."
        fi
    else
        log "Root permissions for $package are OK!"
    fi
done

# Set atlas mock location permission as ignore
if ! appops get $ATLASPKG android:mock_location | grep -qm1 'No operations'; then
    log "Removing mock location permissions from $ATLASPKG"
    appops set $ATLASPKG android:mock_location 2
fi

# Disable all location providers
if ! settings get; then
    log "Checking allowed location providers as 'shell' user"
    allowedProviders=".$(su shell -c settings get secure location_providers_allowed)"
else
    log "Checking allowed location providers"
    allowedProviders=".$(settings get secure location_providers_allowed)"
fi

if [ "$allowedProviders" != "." ]; then
    log "Disabling location providers..."
    if ! settings put secure location_providers_allowed -gps,-wifi,-bluetooth,-network >/dev/null; then
        log "Running as 'shell' user"
        su shell -c 'settings put secure location_providers_allowed -gps,-wifi,-bluetooth,-network'
    fi
fi

## TODO: Double check if this really makes any difference
# if [ "$(settings get global hdmi_control_enabled)" != "0" ]; then
#     settings put global hdmi_control_enabled 0
# fi

if [ "$(settings get global stay_on_while_plugged_in)" != 3 ]; then
    log "Setting Stay On While Plugged In"
    settings put global stay_on_while_plugged_in 3
fi

# Health Service
if [ "$(pm list packages $ATLASPKG)" = "package:$ATLASPKG" ]; then
    (
        is_atlas_running=0
        while :; do
            PID=$(pidof "$ATLASPKG:mapping")
            if [ $? -eq 1 ]; then
                log "Atlas Mapping Service is off for some reason! Restarting..."
                is_atlas_running=0
                force_restart
                continue
            else
                is_atlas_running=1
            fi

            while true; do
                PID=$(pidof com.nianticlabs.pokemongo)
                if [ $? -ne 1 ]; then
                    # FIXME: change from here or from Atlas?
                    if [ $(cat /proc/$PID/oom_adj) -ne -17 ] || [ $(cat /proc/$PID/oom_score_adj) -ne -1000 ]; then
                        echo "Setting PoGo oom params to unkillable values..."
                        echo -17 >/proc/$PID/oom_adj
                        echo -1000 >/proc/$PID/oom_score_adj
                    fi
                fi
                sleep 1m
            done
            else
                log "PoGo is not running!"
                if [ $is_atlas_running -eq 1 ]; then
                    log "Atlas is running though, so will let it start PoGo instead!"
                    monkey -p com.nianticlabs.pokemongo 1
                else
                    log "Atlas is not even running! Resetting everything!"
                    force_restart
                    continue
                fi
            fi

            sleep 1m
        done
    ) &
else
    log "Atlas isn't installed on this device! The daemon will stop."
fi
