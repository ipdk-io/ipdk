#!/bin/sh
#
# NOTE: Taken from this gist:
#
# https://gist.github.com/smoser/635897f845f7cb56c0a7ac3018a4f476
#

Usage() {
    cat <<EOF
Usage: ${0##*/} release

   release is like 'xenial' or 'artful'.
    - Downloads an image from cloud-image.ubuntu.com
    - converts it to raw format (from qcow2)
EOF
}
fail() { echo "$@" 1>&2; exit 1; }

rel="$1"
[ "$1" = "-h" ] || [ "$1" = "--help" ] && { Usage; exit 0; }
[ -n "$rel" ] || { Usage 1>&2; fail "Must give release"; }

#arch="amd64"
burl="${_PROTO:-https}://cloud-images.ubuntu.com/daily/server"
fname=$rel-server-cloudimg-amd64.img
ofname="$fname"

# trusty and xenial have a '-disk1.img' while
# other releases have just 'disk.img'
case "$rel" in
    precise|trusty|xenial) ofname="$rel-server-cloudimg-amd64-disk1.img";;
esac

raw="${fname%.img}.raw"
if [ ! -f "$fname" ]; then
    url="$burl/$rel/current/$ofname"
    echo "downloading $url to $fname"
    wget -nc "$url" -O "$fname.tmp" &&
        mv "$fname.tmp" "$fname" || exit
    rm -f "$raw"
fi
if [ ! -f "$raw" ]; then
    echo "converting $fname to raw in $raw"
    qemu-img convert -O raw "$fname" "$raw.tmp" &&
        mv "$raw.tmp" "$raw" || exit
    rm -f "$fname"
fi

echo "dist: $ofname"
echo "raw:  $raw"

# vi: ts=4 expandtab
