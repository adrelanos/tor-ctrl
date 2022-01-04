#!/usr/bin/env sh

me="${0##*/}"

usage(){
  printf '%s\n' "usage: ${me} [-CaPp] [argument]

  -C [path]      path to tor's control socket
                 default: /run/tor/control
                 notice: do not forget to adjust your torrc

  -a [path]      path to tor's control_auth_cookie
                 default: found via PROTOCOLINFO command, COOKIEFILE=/path
                 notice: do not forget to adjust your torrc

  -P [port]      tor ControlPort
                 default: 9051

  -p [pwd]       use password [var] instead of Tor's control_auth_cookie
                 default: not used
                 notice: do not forget to adjust your torrc
"
  exit 1
}

list_circuits(){
  # shellcheck disable=SC2086
  circuit_all="$(tor-controller -s 0 -c "GETINFO circuit-status" ${cli_args})"
  circuit_all="$(printf '%s\n' "${circuit_all}" | sed "/250 OK/d;/250+circuit-status=/d;/250 closing connection/d")"
  printf '%s\n' "${circuit_all}" | while IFS="$(printf '\n')" read -r circuit || [ -n "${circuit}" ]; do
    circuit_id="$(printf '%s\n' "${circuit}" | awk '{print $1}')"
    circuit_status="$(printf '%s\n' "${circuit}" | awk '{print $2}')"
    circuit_path="$(printf '%s\n' "${circuit}" | awk '{print $3}')"
    circuit_purpose="$(printf '%s\n' "${circuit}" | awk '{print $5}' | sed "s/PURPOSE=//")"
    [ -z "${circuit_status}" ] && break
    if [ "${circuit_status}" = "BUILT" ]; then
      printf '%s\n' "Circuit: ${circuit_id}, status: ${circuit_status}, purpose: ${circuit_purpose}"
      r=0
      for relay in $(printf '%s\n' "${circuit_path}" | tr "," " "); do
        r=$((r+1))
        #[ ${r} -gt 3 ] && break
        relay="$(printf '%s\n' "${relay}" | tr -d "$" | tr "~" " ")"
        relay_fingerprint="$(printf '%s\n' "${relay}" | awk '{print $1}')"
        relay_nickname="$(printf '%s\n' "${relay}" | awk '{print $2}')"
        # shellcheck disable=SC2086
        relay_status="$(tor-controller -s 0 -c "GETINFO ns/id/${relay_fingerprint}" ${cli_args})"
        relay_host="$(printf '%s\n' "${relay_status}" | grep "^r " | cut -d " " -f7)"
        printf '%s\n' "${r}. ${relay_fingerprint} (${relay_nickname}, ${relay_host})"
      done
      printf "\n"
    fi
  done
}

while getopts ":a:C:p:P:h" Option; do
  case ${Option} in
    a) tor_cookie="${OPTARG}";;
    p) tor_password="${OPTARG}";;
    C) tor_control_unix="${OPTARG}";;
    P) tor_control_port="${OPTARG}";;
    h|*) usage;;
  esac
done

cli_args=""
[ -n "${tor_cookie}" ] && cli_args="${cli_args} -a ${tor_cookie}"
[ -n "${tor_password}" ] && cli_args="${cli_args} -p ${tor_password}"
[ -n "${tor_control_unix}" ] && cli_args="${cli_args} -C ${tor_control_unix}"
[ -n "${tor_control_port}" ] && cli_args="${cli_args} -P ${tor_control_port}"

list_circuits