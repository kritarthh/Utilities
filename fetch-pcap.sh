#!/bin/bash
usage() {
    cat <<EOM
    Usage:
    $(basename $0) <env> <server-name> <call-uuid>

    Examples:
    $(basename $0) dev debian-ms1 11111-11111-1111-1111

EOM
    exit 1
}

[ -z $1 ] && { usage; }

uuid="$3"
server="$1-voice-us-west-1-$2-$1.voice.plivodev.com"
dt=`date '+%Y-%m-%d'`
echo "fetching $uuid.pcap ($dt) from $server"
scp kritarth@$server:/mnt/data/vpmtr-spool/mainspool/$dt/$uuid.pcap .
