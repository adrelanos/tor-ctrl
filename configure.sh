#!/usr/bin/env sh

me="${0##*/}"

case "${1}" in
  install)
    [ "$(id -u)" -ne 0 ] && printf '%s\n' "${me}: run as root." && exit 1
    for file in usr/bin/*; do
      [ -f "${file}" ] && cp "${file}" /usr/bin/
    done
    for mandir in "/usr/local/man/man8" "/usr/local/share/man/man8" "/usr/share/man/man8"; do
      [ -d "${mandir}" ] && cp auto-generated-man-pages/tor-ctrl.8 "${mandir}" && break
    done
  ;;
  man)
    command -v pandoc >/dev/null || printf '%s\n' "Install 'pandoc' to create manual pages"
    pandoc -s -f markdown-smart -t man man/tor-ctrl.8.md -o auto-generated-man-pages/tor-ctrl.8
  ;;
  *) printf '%s\n' "Usage: [install|man|help]"
esac