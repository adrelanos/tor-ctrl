#!/usr/bin/env sh

me="${0##*/}"
toplevel="$(git rev-parse --show-toplevel)"
torctrl_version="$("${toplevel}/usr/bin/tor-ctrl" -V)"

case "${1}" in
  install)
    [ "$(id -u)" -ne 0 ] && printf '%s\n' "${me}: install as root." && exit 1
    for file in usr/bin/*; do
      [ -f "${file}" ] && cp "${file}" /usr/bin/
    done
    for mandir in "/usr/local/man/man8" "/usr/local/share/man/man8" "/usr/share/man/man8"; do
      [ -d "${mandir}" ] && cp auto-generated-man-pages/tor-ctrl.8 "${mandir}" && break
    done
  ;;
  man)
    command -v pandoc >/dev/null || printf '%s\n' "Install 'pandoc' to create manual pages"
    [ "$(id -u)" -eq 0 ] && printf '%s\n' "${me}: don't generate the manual as root" && exit 1
    pandoc -s -f markdown-smart -V header="Tor System Manager's Manual" -V footer="${torctrl_version}" -t man man/tor-ctrl.8.md -o auto-generated-man-pages/tor-ctrl.8
    sed -i'' "s/default_date/$(date +%Y-%m-%d)/" auto-generated-man-pages/tor-ctrl.8
  ;;
  *) printf '%s\n' "Usage: [install|man|help]"
esac