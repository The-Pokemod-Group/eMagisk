#!/system/bin/sh
PACKAGE=com.pokemod.atlas

download() {
    until
        wget \
            --user-agent="Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6" \
            -c "$1" \
            -O "$2"
    do
        log "Download of ${1##*/} incomplete! Trying again..."
        sleep 5s
    done
}

checkUpdates() {
    while :; do
        log "Checking for updates..."

        until ping -c1 8.8.8.8 >/dev/null 2>/dev/null; do
            sleep 5s
        done

        currentVersion=$(sed -n "s/^versionCode=//p" $MODDIR/module.prop)
        remoteVersion=$(wget http://storage.googleapis.com/pokemod/Atlas/version -O-)
        if [ ."$remoteVersion" != "." ] && [ "$remoteVersion" != "$currentVersion" ]; then
            log "There's a new version of eMagisk!"
            log "Updating from $currentVersion to $remoteVersion"

            download "http://storage.googleapis.com/pokemod/Atlas/3-eMagisk.zip" "<SDCARD>/eMagisk.zip" 2>&1
            if unzip -l "<SDCARD>/eMagisk.zip"; then
                log "Downloaded new version, rebooting and installing..."
                mkdir -p /cache/recovery
                touch /cache/recovery/command
                echo '--update_package=<SDCARD>/eMagisk.zip' >>/cache/recovery/command
                echo '--wipe_cache' >>/cache/recovery/command
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

# pol=$(sqlite3 /data/adb/magisk.db "select policy from policies where package_name='com.android.shell'")
# if [ "$pol" != 2 ]; then
#     log "Adding root permissions to shell"
#     sqlite3 /data/adb/magisk.db "DELETE from policies WHERE package_name='com.android.shell'"
#     sqlite3 /data/adb/magisk.db "INSERT INTO policies (uid,package_name,policy,until,logging,notification) VALUES($suid,'com.android.shell',2,0,1,1)"
# fi

# Set atlas as mock location
if appops get $PACKAGE android:mock_location android:mock_location; then
    log "Setting Atlas as mock location"
    appops set $PACKAGE android:mock_location allow
fi

# Set GPS location provider:
if ! settings get secure location_providers_allowed | grep -q gps; then
    log "Enabling GPS location provider"
    settings put secure location_providers_allowed +gps
fi

## TODO: Double check if this really makes any difference
if [ "$(settings get global hdmi_control_enabled)" != "0" ]; then
    settings put global hdmi_control_enabled 0
fi

if [ "$(settings get global stay_on_while_plugged_in)" != 3 ]; then
    log "Setting Stay On While Plugged In"
    settings put global stay_on_while_plugged_in 3
fi

# Run in background and kep pogo open
if [ "$(pm list packages $PACKAGE)" = "package:$PACKAGE" ]; then
    (
        while :; do
            PID=$(pidof "$PACKAGE")
            if [ $? -eq 1 ]; then
                log "Atlas not enabled..."
                # FIXME: do it here or in atlas?
                am start-foreground-service $PACKAGE.MappingService
            fi

            PID=$(pidof com.nianticlabs.pokemongo)
            if [ $? -ne 1 ]; then
                log "Setting PoGo oom params to unkillable values..."
                # FIXME: change from here or from Atlas?
                echo -17 >/proc/$PID/oom_adj
                echo -1000 >/proc/$PID/oom_score_adj
            else
                log "ERROR: PoGO is dead :("
                # FIXME: respawn from here or from Atlas?
            fi
            sleep 30
        done
    ) &
else
    log "Atlas isn't installed on this device! The daemon will stop."
fi
