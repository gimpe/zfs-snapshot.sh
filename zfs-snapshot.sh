#!/usr/local/bin/bash
 
# FROM: http://andyleonard.com/2010/04/07/automatic-zfs-snapshot-rotation-on-freebsd/
 
# Path to ZFS executable:
ZFS=/sbin/zfs
 
# Parse arguments:
TARGET=$1
SNAP=$2
COUNT=$3
 
# Function to display usage:
usage() {
    scriptname=`/usr/bin/basename $0`
    echo "$scriptname: Take and rotate snapshots on a ZFS file system"
    echo
    echo "  Usage:"
    echo "  $scriptname target snap_name count"
    echo
    echo "  target:    ZFS file system to act on"
    echo "  snap_name: Base name for snapshots, to be followed by a '.' and"
    echo "             an integer indicating relative age of the snapshot"
    echo "  count:     Number of snapshots in the snap_name.number format to"
    echo "             keep at one time.  Newest snapshot ends in '.0'."
    echo
    exit
}
 
# Basic argument checks:
if [ -z $COUNT ] ; then
    usage
fi
 
if [ ! -z $4 ] ; then
    usage
fi
 
# Get the TARGET mountpoint
TARGET_MOUNT=$($ZFS get -H -o value mountpoint $TARGET)
 
# Snapshots are number starting at 0; $max_snap is the highest numbered
# snapshot that will be kept.
max_snap=$(($COUNT -1))
 
# Clean up oldest snapshot:
if [ -d ${TARGET_MOUNT}/.zfs/snapshot/${SNAP}.${max_snap} ] ; then
    $ZFS destroy -r ${TARGET}@${SNAP}.${max_snap}
fi
 
# Rename existing snapshots:
dest=$max_snap
while [ $dest -gt 0 ] ; do
    src=$(($dest - 1))
    if [ -d ${TARGET_MOUNT}/.zfs/snapshot/${SNAP}.${src} ] ; then
        $ZFS rename -r ${TARGET}@${SNAP}.${src} ${TARGET}@${SNAP}.${dest}
    fi
    dest=$(($dest - 1))
done
 
# Create new snapshot:
$ZFS snapshot -r ${TARGET}@${SNAP}.0
