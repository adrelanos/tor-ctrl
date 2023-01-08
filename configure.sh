#!/usr/bin/env sh

me="${0##*/}"
toplevel="$(git rev-parse --show-toplevel)"
script_name="tor-ctrl"
script_version="$("${toplevel}/usr/bin/${script_name}" -V)"

error_msg(){
  printf %s"${me}: ${1}\n" >&2
  exit 1
}

usage(){
  printf %s"Usage: ${me} [install|remove|build-deb|install-deb|clean-deb|man|check]

Common:
 install       install on any unix system
 remove        remove the scripts and its manual from your system
 help          print this help message

Debian packaging:
  build-deb    build the debian package
  install-deb  install the debian package
  clean-deb    clean deb artifacts and package

Developer:
  man          generate manual pages
  check        check syntax
"
  exit 1
}

case "${1}" in

  install)
    [ "$(id -u)" -ne 0 ] && error_msg "${1} as root"
    for file in "${toplevel}"/usr/bin/*; do
      [ -f "${file}" ] && install "${file}" /usr/bin/
    done
    for mandir in "/usr/local/man/man8" "/usr/local/share/man/man8" "/usr/share/man/man8"; do
      manual="${toplevel}/auto-generated-man-pages/${script_name}.8"
      [ -d "${mandir}" ] && [ -f "${manual}" ] && install "${manual}" "${mandir}" && break
    done
  ;;

  remove)
    [ "$(id -u)" -ne 0 ] && error_msg "${1} as root"
    rm -f "/usr/local/man/man8/${script_name}.8" "/usr/local/share/man/man8/${script_name}.8" "/usr/share/man/man8/${script_name}.8"
    for file in "${toplevel}"/usr/bin/*; do
      [ -f "${file}" ] && rm -f "/usr/bin/${file##*/}" "/usr/local/bin/${file##*/}"
    done
  ;;

  build-deb)
    [ "$(id -u)" -ne 0 ] && error_msg "${1} as root"
    command -v mk-build-deps >/dev/null || { apt update -y && apt install -y devscripts ; }
    mk-build-deps --remove --install
    dpkg-buildpackage -b --no-sign
  ;;

  install-deb)
    [ "$(id -u)" -ne 0 ] && error_msg "${1} as root"
    package_highest_version="$(find ../ -maxdepth 1 -type f -name "${script_name}*.deb" | head -n 1)"
    dpkg -i "${package_highest_version}"
  ;;

  clean-deb)
    rm -rf -- *-build-deps_*.buildinfo *-build-deps_*.changes \
    debian/*.debhelper.log debian/*.substvars \
    debian/.debhelper debian/files \
    debian/debhelper-build-stamp "debian/${script_name}" \
    ../"${script_name}"_*.deb ../"${script_name}"_*.buildinfo ../"${script_name}"_*.changes
  ;;

  man)
    command -v pandoc >/dev/null || error_msg "Install 'pandoc' to create manual pages"
    [ "$(id -u)" -eq 0 ] && printf '%s\n' "${me}: don't generate the manual as root" && exit 1
    pandoc -s -f markdown-smart -V header="Tor System Manager's Manual" -V footer="${script_version}" -t man "${toplevel}/man/${script_name}.8.md" -o "${toplevel}/auto-generated-man-pages/${script_name}.8"
    sed -i'' "s/default_date/$(date +%Y-%m-%d)/" "${toplevel}/auto-generated-man-pages/${script_name}.8"
  ;;

  check)
    command -v shellcheck >/dev/null || error_msg "Install 'shellcheck' to linter scripts"
    shellcheck "${toplevel}"/usr/bin/*
  ;;

  *) usage;;
esac
