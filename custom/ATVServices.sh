#!/system/bin/sh

# Base stuff we need

POGOPKG=com.nianticlabs.pokemongo
UNINSTALLPKGS="com.ionitech.airscreen cm.aptoidetv.pt com.netflix.mediaclient org.xbmc.kodi com.google.android.youtube.tv"
CONFIGFILE='/data/local/tmp/emagisk.config'

# Check if this is a beta or production device

check_beta() {    
    if [ "$(pm list packages com.pokemod.atlas.beta)" = "package:com.pokemod.atlas.beta" ]; then
        log "Found Atlas developer version!"
        ATLASPKG=com.pokemod.atlas.beta
    elif [ "$(pm list packages com.pokemod.atlas)" = "package:com.pokemod.atlas" ]; then
        log "Found Atlas production version!"
        ATLASPKG=com.pokemod.atlas
    else
        log "No Atlas installed. Abort!"
        exit 1
    fi
}

# This is for the X96 Mini and X96W Atvs. Can be adapted to other ATVs that have a led status indicator

led_red(){
    echo 0 > /sys/class/leds/led-sys/brightness
}

led_blue(){
    echo 1 > /sys/class/leds/led-sys/brightness
}

# Stops Atlas and Pogo and restarts Atlas MappingService

force_restart() {
    am stopservice $ATLASPKG/com.pokemod.atlas.services.MappingService
    am force-stop $POGOPKG
    am force-stop $ATLASPKG
    sleep 5
    am startservice $ATLASPKG/com.pokemod.atlas.services.MappingService
    log "Services were restarted!"
}

# Recheck if $CONFIGFILE exists and has data. Repulls data and checks the RDM connection status.

configfile_rdm() {
    if [[ -s $CONFIGFILE ]]; then
        log "$CONFIGFILE exists and has data. Data will be pulled."
        source $CONFIGFILE
        export rdm_user rdm_password rdm_backendURL
    else
        log "Failed to pull the info. Make sure $($CONFIGFILE) exists and has the correct data."
    fi

    # RDM connection check

    rdmConnect=$(curl -i -s -k -u $rdm_user:$rdm_password "$rdm_backendURL/api/get_data?show_devices=true" | awk -F\/ '{print $2}' | awk -F" " '{print $3}' | sed -n '1p')
    if [[ $rdmConnect = "OK" ]]; then
        log "RDM connection status: $rdmConnect"
        log "RDM Connection was successful!"
        led_blue
    elif [[ $rdmConnect = "Unauthorized" ]]; then
        log "RDM connection status: $rdmConnect -> Recheck in 4 minutes"
        log "Check your $CONFIGFILE values, credentials and rdm_user permissions!"
        led_red
        sleep $((240+$RANDOM%10))
    elif [[ $rdmConnect = "Internal" ]]; then
        log "RDM connection status: $rdmConnect -> Recheck in 4 minutes"
        log "The RDM Server couldn't response properly to eMagisk!"
        led_red
        sleep $((240+$RANDOM%10))

    elif [[ -z $rdmConnect ]]; then
        log "RDM connection status: $rdmConnect -> Recheck in 4 minutes"
        log "Check your ATV internet connection!"
        led_red
        counter=$((counter+1))
        if [[ $counter -gt 4 ]];then
            log "Critical restart threshold of $counter reached. Rebooting device..."
            reboot
            # We need to wait for the reboot to actually happen or the process might be interrupted
            sleep 60 
        fi
        sleep $((240+$RANDOM%10))
    else
        log "RDM connection status: $rdmConnect -> Recheck in 4 minutes"
        log "Something different went wrong..."
        led_red
        sleep $((240+$RANDOM%10))
    fi
}

# Adjust the script depending on Atlas production or beta

check_beta

# Wipe out packages we don't need in our ATV

echo "$UNINSTALLPKGS" | tr ' ' '\n' | while read -r item; do
    if ! dumpsys package "$item" | \grep -qm1 "Unable to find package"; then
        log "Uninstalling $item..."
        pm uninstall "$item"
    fi
done

# Disable playstore alltogether (no auto updates)

if [ "$(pm list packages -e com.android.vending)" = "package:com.android.vending" ]; then
    log "Disabling Play Store"
    pm disable-user com.android.vending
fi

# Enable Magiskhide if not enabled

if ! magiskhide status; then
    log "Enabling MagiskHide"
    magiskhide enable
fi

# Add pokemon go to Magisk hide if it isn't

if ! magiskhide ls | grep -m1 $POGOPKG; then
    log "Adding PoGo to MagiskHide"
    magiskhide add $POGOPKG
fi

# Give all atlas services root permissions

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

# Make sure the device doesn't randomly turn off

if [ "$(settings get global stay_on_while_plugged_in)" != 3 ]; then
    log "Setting Stay On While Plugged In"
    settings put global stay_on_while_plugged_in 3
fi


# Health Service by Emi and Bubble with a little root touch

if [ "$(pm list packages $ATLASPKG)" = "package:$ATLASPKG" ]; then
    (
        log "eMagisk v$(cat "$MODDIR/version_lock"). Starting health check service in 4 minutes..."
        counter=0
        rdmDeviceID=1
        log "Start counter at $counter"
        while :; do
            sleep $((240+$RANDOM%10))
            configfile_rdm        

            if [[ $counter -gt 3 ]];then
            log "Critical restart threshold of $counter reached. Rebooting device..."
            reboot
            # We need to wait for the reboot to actually happen or the process might be interrupted
            sleep 60 
            fi

            log "Started health check!"
            atlasDeviceName=$(cat /data/local/tmp/atlas_config.json | awk -F\" '{print $12}')
	        rdmDeviceInfo=$(curl -s -k -u $rdm_user:$rdm_password "$rdm_backendURL/api/get_data?show_devices=true&formatted=true"  | awk -F\[ '{print $2}' | awk -F\}\,\{\" '{print $'$rdmDeviceID'}')
            rdmDeviceName=$(curl -s -k -u $rdm_user:$rdm_password "$rdm_backendURL/api/get_data?show_devices=true&formatted=true" | awk -F\[ '{print $2}' | awk -F\}\,\{\" '{print $'$rdmDeviceID'}' | awk -Fuuid\"\:\" '{print $2}' | awk -F\" '{print $1}')
	
	        until [[ $rdmDeviceName = $atlasDeviceName ]]
	        do
		        $((rdmDeviceID++))
		        rdmDeviceInfo=$(curl -s -k -u $rdm_user:$rdm_password "$rdm_backendURL/api/get_data?show_devices=true&formatted=true" | awk -F\[ '{print $2}' | awk -F\}\,\{\" '{print $'$rdmDeviceID'}')
		        rdmDeviceName=$(curl -s -k -u $rdm_user:$rdm_password "$rdm_backendURL/api/get_data?show_devices=true&formatted=true" | awk -F\[ '{print $2}' | awk -F\}\,\{\" '{print $'$rdmDeviceID'}' | awk -Fuuid\"\:\" '{print $2}' | awk -F\" '{print $1}')
		
		        if [[ -z $rdmDeviceInfo ]]; then
                    log "Probably reached end of device list or encountered a different issue!"
                    log "Set RDM Device ID to 1, recheck RDM connection and repull $CONFIGFILE"
			        rdmDeviceID=1
                    #repull rdm values + recheck rdm connection
                    configfile_rdm
			        rdmDeviceName=$(curl -s -k -u $rdm_user:$rdm_password "$rdm_backendURL/api/get_data?show_devices=true&formatted=true" | awk -F\[ '{print $2}' | awk -F\}\,\{\" '{print $'$rdmDeviceID'}' | awk -Fuuid\"\:\" '{print $2}' | awk -F\" '{print $1}')
		        fi	
	        done
	
	        log "Found our device! Checking for timestamps..."
	        rdmDeviceLastseen=$(curl -s -k -u $rdm_user:$rdm_password "$rdm_backendURL/api/get_data?show_devices=true&formatted=true" | awk -F\[ '{print $2}' | awk -F\}\,\{\" '{print $'$rdmDeviceID'}' | awk -Flast_seen\"\:\{\" '{print $2}' | awk -Ftimestamp\"\: '{print $2}' | awk -F\, '{print $1}' | sed 's/}//g')
		if [[ -z $rdmDeviceLastseen ]]; then
			log "The device last seen status is empty!"
		else
	        	now="$(date +'%s')"
	        	calcTimeDiff=$(($now - $rdmDeviceLastseen))
	
	        	if [[ $calcTimeDiff -gt 300 ]]; then
		        	log "Last seen at RDM is greater than 5 minutes -> Atlas Service will be restarting..."
		        	force_restart
                		led_red
                		counter=$((counter+1))
                		log "Counter is now set at $counter. device will be rebooted if counter reaches 4 failed restarts."
	        	elif [[ $calcTimeDiff -le 10 ]]; then
		        	log "Our device is live!"
                		counter=0
                		led_blue
	        	else
		        	log "Last seen time is a bit off. Will check again later."
                	counter=0
                	led_blue
	        	fi
		fi
            log "Scheduling next check in 4 minutes..."
        done
    ) &
else
    log "Atlas isn't installed on this device! The daemon will stop."
fi
