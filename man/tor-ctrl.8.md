% TOR-CTRL(8) tor-ctrl manual
% tor-ctrl was written by Stefan Behte (stefan.behte@gmx.net), later developed by and Patrick Schleizer (adrelanos@riseup.net) and further improved by nyxnor (nyxnor@protonmail.com)
% default_date

# NAME

tor-ctrl - Interact with Tor's controller via command line tool

# SYNOPSIS

**tor-ctrl** [**-qVw**] [**-p** *pwd*] [**-s** *socket*] [**-t** *time*] [[**-c**|**--**] *command*]

# DESCRIPTION

**tor-ctrl** is a command line tool for setting up stream for communication from the Tor Controller's (client) to a Tor process (server). The client send commands using TCP sockets or Unix-domain sockets and receive replies from the server.
The following configuration lines must be inserted to your torrc and tor reloaded to apply the changes.

In order to get this to work, define the socket that will control the tor process, can be a TCP socket *ControlPort 9051* or a Unix-domain socket *ControlSocket /path/to/socket*.

To secure the controller, you must setup and authentication method, which can be a cookie
*CookieAuthentication 1* or if you want a fixed password, hash a password with *echo "HashedControlPassword $(tor --hash-password yourpassword)"* and use the same output given as the configuration line.

# OPTIONS

[**-c**|**--**] [*command*]
: command to execute. If the command option is *-c*, you must "quote" your command. If the command option is *--*, option parsing will stop, meaning that any option specified after it won't be parsed, the benefit is that it becomes unnecessary to quote your command. To use different commands together, you must make shell escape to a new line with *\\\\n*.

**-s** *socket*
: Tor's control socket. Accept *TCP socket* in the format [*addr:*]*port* (examples: 9051, 127.0.0.1:9051). Accept *Unix-domain socket* in the following format [*unix:*]*path* (examples: /run/tor/control, unix:/run/tor/control). (Default: 9051).

**-p** *pwd*
: Use password instead of tor's cookie. (Default: not used).

**-t** *time*
: Sleep N seconds after each command sent. (Default for socat/nc: 0 second, Default for telnet: 1 second).

**-w**
: Wait for confirmation with an enter pressed to end the connection after sending the command. Useful when you want to be warned about events, example is when the command is *SETEVENTS STREAM* (Default: not set)

**-q**
: Quiet mode. (Default: not set).

**-V**
: Print version information and exit.

# DEBUGGING OPTIONS

**-d**
: Debug mode. The shell shall write to standard error a trace for each command after it expands the command and before it executes it. (Default: not set).

**-r**
: Dry-run mode. Show what would be done, without sending commands to the controller. (Default: not set).

# EXIT CODES

**0**
: Success.

**>0**
: Fail.

# EXAMPLES

Check your tor software version:
```
tor-ctrl GETINFO version
```

Get your SocksPort configuration and check where tor is listening for socks connections:
```
tor-ctrl -s 9051 -p foobar -- GETCONF SocksPort \\n GETINFO net/listeners/socks
```

Set bandwidth rate:
```
tor-ctrl -q SETCONF bandwidthrate=1mb
```

For setting the bandwidth for specific times of the day, I suggest calling tor-ctrl via cron. e.g: set the bandwidth to 100kb at 07:00 and to 1mb at 22:00. You can use notations like 1mb, 1kb or the number of bytes:
```
0 22 * * * /path/to/tor-ctrl -c "SETCONF bandwidthrate=1mb"

0 7 * * *  /path/to/tor-ctrl -c "SETCONF bandwidthrate=100kb"
```

# WWW

https://gitweb.torproject.org/torspec.git/tree/control-spec.txt

# DISCLAIMER

This package is produced independently of, and carries no guarantee from, The
Tor Project.

# SEE ALSO

tor(1)

# BUGS

Not expected, please report them at https://github.com/nyxnor/tor-ctrl/issues

# LICENSE

Copyright (C) 2007 by Stefan Behte

Portion Copyright (C) 2013 - 2020 ENCRYPTED SUPPORT LP <adrelanos@riseup.net>

Portion Copyright (C) 2021 - 2022 nyxnor <nyxnor@protonmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

On Debian systems, the full text of the GNU General Public
License version 3 can be found in the file
`/usr/share/common-licenses/GPL-3'.
