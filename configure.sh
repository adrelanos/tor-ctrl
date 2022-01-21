#!/usr/bin/env sh

me="${0##*/}"
toplevel="$(git rev-parse --show-toplevel)"
torctrl_version="$("${toplevel}/usr/bin/tor-ctrl" -V)"

error_msg(){
  printf %s"${me}: ${1}\n" >&2
  exit 1
}

# case "$()" in
#   Linux) prefix="/usr";;
#   *[Bb][Sd][Dd]|*) prefix="/usr/local";;
# esac

case "${1}" in
  install)
    [ "$(id -u)" -ne 0 ] && error_msg "${1} as root"
    for file in "${toplevel}"/usr/bin/*; do
      [ -f "${file}" ] && cp "${file}" /usr/bin/
    done
    for mandir in "/usr/local/man/man8" "/usr/local/share/man/man8" "/usr/share/man/man8"; do
      manual="${toplevel}/auto-generated-man-pages/tor-ctrl.8"
      [ -d "${mandir}" ] && [ -f "${manual}" ] && cp "${manual}" "${mandir}" && break
    done
  ;;
  remove)
    [ "$(id -u)" -ne 0 ] && error_msg "${1} as root"
    rm -f /usr/local/man/man8/tor-ctrl.8 /usr/local/share/man/man8/tor-ctrl.8 /usr/share/man/man8/tor-ctrl.8
    for file in "${toplevel}"/usr/bin/*; do
      [ -f "${file}" ] && rm -f "/usr/bin/${file##*/}" "/usr/local/bin/${file##*/}"
    done
  ;;
  man)
    command -v pandoc >/dev/null || error_msg "Install 'pandoc' to create manual pages"
    [ "$(id -u)" -eq 0 ] && printf '%s\n' "${me}: don't generate the manual as root" && exit 1
    pandoc -s -f markdown-smart -V header="Tor System Manager's Manual" -V footer="${torctrl_version}" -t man "${toplevel}/man/tor-ctrl.8.md" -o "${toplevel}/auto-generated-man-pages/tor-ctrl.8"
    sed -i'' "s/default_date/$(date +%Y-%m-%d)/" "${toplevel}/auto-generated-man-pages/tor-ctrl.8"
  ;;
  check)
    command -v shellcheck >/dev/null || error_msg "Install 'shellcheck' to linter scripts"
    shellcheck "${toplevel}"/usr/bin/*
  ;;
  *) printf '%s\n' "Usage: [install|remove|man|check|help]" && exit 1
esac
