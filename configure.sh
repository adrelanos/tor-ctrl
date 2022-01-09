#!/usr/bin/env sh

me="${0##*/}"

case "${1}" in
  install)
    [ "$(id -u)" -ne 0 ] && printf '%s\n' "Run ${me} as root." && exit 1
    cp bin/tor-ctrl /usr/local/bin/
    cp man/tor-ctrl.8 /usr/local/man/man8/
  ;;
  man)
    command -v pandoc >/dev/null || printf '%s\n' "Install 'pandoc' to create manual pages"
    pandoc -s -f markdown-smart -t man docs/tor-ctrl.8.md -o man/tor-ctrl.8
  ;;
  *) printf '%s\n' "Usage: [install|man|help]"
esac