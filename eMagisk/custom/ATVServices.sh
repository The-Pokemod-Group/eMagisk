#!/system/bin/sh
ATLASPKG=com.pokemod.atlas.beta
POGOPKG=com.nianticlabs.pokemongo
UNINSTALLPKGS="com.ionitech.airscreen cm.aptoidetv.pt com.netflix.mediaclient org.xbmc.kodi com.google.android.youtube.tv"

force_restart() {
    # killall -9 $POGOPKG
    killall -9 $ATLASPKG
    # monkey -p $ATLASPKG 1
    sleep 5s
    am stopservice $ATLASPKG/com.pokemod.atlas.services.MappingService
    am startservice $ATLASPKG/com.pokemod.atlas.services.MappingService
    # monkey -p $POGOPKG 1
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
        # currentVersion="$(dumpsys package $POGOPKG|awk -F'=' '/versionName/{print $2}')"
        # remoteVersion=$(wget http://storage.googleapis.com/pokemod/Atlas/version -O-)

        # TODO: Atlas

        sleep 1h
    done
}

# checkUpdates &

echo "$UNINSTALLPKGS" | tr ' ' '\n' | while read -r item; do
    if ! dumpsys package "$item" | \grep -qm1 "Unable to find package"; then
        log "Uninstalling $item..."
        pm uninstall "$item"
    fi
done

# log "Enabling Play Store"
# pm disable com.android.vending
# TODO:
if [ "$(pm list packages -e com.android.vending)" = "package:com.android.vending" ]; then
    log "Disabling Play Store"
    pm disable-user com.android.vending
fi

if ! magiskhide status; then
    log "Enabling MagiskHide"
    magiskhide enable
fi

if ! magiskhide ls | grep -m1 $POGOPKG; then
    log "Adding PoGo to MagiskHide"
    magiskhide add $POGOPKG
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
        count=0
        while :; do
            sleep 60

            if ! pidof "$ATLASPKG:mapping"; then
                log "Atlas Mapping Service is off for some reason! Restarting..."
                is_atlas_running=0
                count=0
                force_restart
            else
                is_atlas_running=1
            fi

            if ! pidof $POGOPKG; then
                if [ $is_atlas_running -eq 1 ]; then
                    count=$((count+1))
                    log "PoGo is not running, but Atlas is. If this happens again during 5 minutes will restart! ($count)"
                fi
                if [ $count -gt 5 ]; then
                    log "Happened five times. Restarting everything!"
                    count=0
                    force_restart
                fi
            else
                count=0
            fi

            if ! pidof adbd; then
                log "ADBD wasn't running! Starting service..."
                start adbd
            fi
        done
    ) &
else
    log "Atlas isn't installed on this device! The daemon will stop."
fi
