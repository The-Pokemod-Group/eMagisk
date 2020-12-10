#!/system/bin/sh
ATLASPKG=com.pokemod.atlas

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

        currentVersion=$(cat $MODDIR/version_lock)
        remoteVersion=$(wget http://storage.googleapis.com/pokemod/Atlas/version -O-)
        if [ ."$remoteVersion" != "." ] && [ "$remoteVersion" != "$currentVersion" ]; then
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

        sleep 1h
    done
}

checkUpdates &

if ! magiskhide status; then
    log "Enabling MagiskHide"
    magiskhide enable
fi

if ! magiskhide ls | grep -m1 com.nianticlabs.pokemongo; then
    log "Adding PoGo to magiskhide"
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

# Set GPS location provider:
if ! settings get secure location_providers_allowed | grep -q gps; then
    log "Enabling GPS location provider"
    settings put secure location_providers_allowed +gps
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
        while :; do
            PID=$(pidof "$ATLASPKG:mapping")
            if [ $? -eq 1 ]; then
                log "Atlas Mapping Service is off for some reason! Restarting..."
                am startservice $ATLASPKG/.MappingService
            fi

            PID=$(pidof com.nianticlabs.pokemongo)
            if [ $? -ne 1 ]; then
                if [ $(cat /proc/$PID/oom_adj) -ne -17 ] || [ $(cat /proc/$PID/oom_score_adj) -ne -1000 ]; then
                    log "Setting PoGo oom params to unkillable values..."
                    echo -17 >/proc/$PID/oom_adj
                    echo -1000 >/proc/$PID/oom_score_adj
                fi
            else
                log "ERROR: PoGO is dead :("
                # FIXME: respawn from here or from Atlas?
            fi
            sleep 1m
        done
    ) &
else
    log "Atlas isn't installed on this device! The daemon will stop."
fi
