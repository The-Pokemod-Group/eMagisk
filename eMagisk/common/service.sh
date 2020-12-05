#!/system/bin/sh
# Do NOT assume where your module will be located.
# ALWAYS use $MODDIR if you need to know where this script
# and module is placed.
# This will make sure your module will still work
# if Magisk change its mount point in the future
MODDIR=${0%/*}

logfile=/data/local/tmp/emagisk.log
log() {
    echo "$(date -u +"%Y-%m-%d %H:%M:%S") eMagisk | ${*}" >>$logfile
    /system/bin/log -t eMagisk -p i "${@}"
}

# wait until data is decrypted and system is ready
# credit: Advanced Charging Controller Daemon (accd)
log "Waiting for complete boot"
# wait until data is decrypted and system is ready
until [ -d /sdcard/Download ]; do
    sleep 10
done
pgrep zygote >/dev/null && {
    until [ .$(getprop sys.boot_completed) = .1 ]; do
        sleep 10
    done
}
log "System boot completed"

if [ -f "$MODDIR/ATVServices.sh" ]; then
    sleep 10
    log "Sourcing ATVServices.sh"
    . "$MODDIR/ATVServices.sh"
fi
