#!/usr/bin/env sh

me="${0##*/}"

[ "$(id -u)" -ne 0 ] && printf '%s\n' "Run ${me} as root." && exit 1

cp bin/tor-controller /usr/local/bin/