#!/usr/bin/env sh

nocolor="\033[0m"
bold="\033[1m"

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

  Examples:      ${me} -c \"SETCONF bandwidthrate=1mb\"
                 tor-controller -v -s 0 -c \"GETCONF User\"
                 tor-controller -v -s 0 -P 9051 -p foobar -c \"GETCONF bandwidthrate\"
"
  exit 1
}

list_streams(){
  # shellcheck disable=SC2086
  listen_stream="$(tor-controller -s 0 -v -w -c "SETEVENTS STREAM" ${cli_args})"
  listen_stream="$(printf '%s\n' "${listen_stream}" | sed "/250 OK/d;/250 closing connection/d")"
  printf '%s\n' "${listen_stream}" | while IFS="$(printf '\n')" read -r stream_line || [ -n "${stream_line}" ]; do
    stream_code="$(printf '%s\n' "${stream_line}" | cut -d " " -f1)"
    stream_event="$(printf '%s\n' "${stream_line}" | cut -d " " -f2)"
    stream_id="$(printf '%s\n' "${stream_line}" | cut -d " " -f3)"
    stream_status="$(printf '%s\n' "${stream_line}" | cut -d " " -f4)"
    circuit_id="$(printf '%s\n' "${stream_line}" | cut -d " " -f5)"
    target="$(printf '%s\n' "${stream_line}" | cut -d " " -f6)"
    if [ "${stream_code}" = "650" ] && [ "${stream_event}" = "STREAM" ]; then
      if [ "${stream_status}" = "SENTCONNECT" ]; then
        target_clear="$(printf '%s\n' "${stream_line}" | cut -d " " -f6)"
      elif [ "${stream_status}" = "REMAP" ]; then
        target_clear="$(printf '%s\n' "${target} (${target_clear})")"
      elif [ "${stream_status}" = "SUCCEEDED" ]; then
        [ -n "${target_clear}" ] && target="${target_clear}"
        # shellcheck disable=SC2086
        circuit_all="$(tor-controller -s 0 -v -c "GETINFO circuit-status" ${cli_args})"
        circuit="$(printf '%s\n' "${circuit_all}" | grep "^${circuit_id} " | sed "/250 OK/d;/250+circuit-status=/d;/250 closing connection/d")"
        circuit_status="$(printf '%s\n' "${circuit}" | awk '{print $2}')"
        circuit_path="$(printf '%s\n' "${circuit}" | awk '{print $3}')"
        circuit_purpose="$(printf '%s\n' "${circuit}" | awk '{print $5}' | sed "s/PURPOSE=//")"
        [ -z "${circuit_status}" ] && break
        if [ "${circuit_status}" = "BUILT" ]; then
          printf %s"\n${bold}------------------------------------------------------------------------------------------${nocolor}\n"
          printf %s"${bold}Stream: ${stream_id}, Target: ${target}${nocolor}\n"
          printf %s"${bold}Circuit: ${circuit_id}, Purpose: ${circuit_purpose}${nocolor}\n"
          printf %s"${bold}n. fingerprint                              address        nickname     locale${nocolor}\n"
          printf %s"${bold}------------------------------------------------------------------------------------------${nocolor}\n"
          hop=0
          for relay in $(printf '%s\n' "${circuit_path}" | tr "," " "); do
            hop=$((hop+1))
            #[ ${hop} -gt 3 ] && break
            relay="$(printf '%s\n' "${relay}" | tr -d "$" | tr "~" " ")"
            relay_fingerprint="$(printf '%s\n' "${relay}" | cut -d " " -f1)"
            relay_nickname="$(printf '%s\n' "${relay}" | cut -d " " -f2)"
            # shellcheck disable=SC2086
            relay_status="$(tor-controller -s 0 -v -c "GETINFO ns/id/${relay_fingerprint}" ${cli_args})"
            relay_host="$(printf '%s\n' "${relay_status}" | grep "^r " | cut -d " " -f7)"
            # shellcheck disable=SC2086
            relay_locale="$(tor-controller -s 0 -v -c "GETINFO ip-to-country/${relay_host}" ${cli_args})"
            relay_locale="$(printf '%s\n' "${relay_locale}" | grep "250-ip-to-country/${relay_host}=" | sed "s/.*=//")"
            printf %s"${hop}. ${relay_fingerprint} ${relay_host} ${relay_nickname} ${relay_locale}\n"
          done
          printf %s"${bold}------------------------------------------------------------------------------------------${nocolor}\n"
          printf "\n"
        fi
      fi
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

list_streams
