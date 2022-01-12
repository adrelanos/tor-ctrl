% tor-ctrl(8) Interact with Tor's controller via command line tool
% tor-ctrl was written by Stefan Behte (stefan.behte@gmx.net), later developed by and Patrick Schleizer (adrelanos@riseup.net) and futher improved by nyxnor (nyxnor@protonmail.com)
% September 2069

# NAME

tor-ctrl(8) - Interact with Tor's controller via command line tool

# SYNOPSIS

**tor-ctrl** [**-wq**] [**-s** *socket*] [**-p** *pwd*] [**-t** *time*] [[**-c**|**--**] *command*]

# DESCRIPTION

**tor-ctrl** is a commandline tool for executing commands on a tor server via the controlport.  In order to get this to work, add define the socket that will control the tor process, can be a tcp socket *ControlPort 9051* or a unix domain socket *ControlSocket /path/to/socket*. To secure the controller, you must setup and authentication method, which can be a cookie
*CookieAuthentication 1* or if you want a fixed password, hash a password with *echo "HashedControlPassword $(tor --hash-password yourpassword)"* and use the same output given. These configuration lines must be inserted to your torrc and tor reloaded after making changes.

# OPTIONS

[**-c**|**--**] [*command*]
: command to execute. If the command option is *-c*, you must "quote" your command. If the command option is *--*, option parsing will stop, meaning you any option specified after it won't be parsed, the benefit is that it becomes uncessary to quote your command.

**-s** [*socket*]
: Tor's control socket. Accept *tcp socket* in the format [*addr:*]*port* (examples: 9051, 127.0.0.1:9051). Accept *unix domain socket* in the following format [*unix:*]*path* (examples: /run/tor/control, unix:/run/tor/control). (Default: 9051).

**-p** [*pwd*]
: Use password instead of tor's cookie. (Default: not used).

**-t** [*time*]
: sleep [var] seconds after each command sent. (Default for socat/nc: 0 second, Default for telnet: 1 second).

**-w**
: Wait for confirmation with an enter pressed to end the connection after sending the command. Usefult when you want to be warned about events, example is when the command is *SETEVENTS STREAM* (Default: not set)

**-q**
: Quiet mode. (Default: not set).

# EXIT CODES

**0**
: Fail

**>0**
: Success.

# EXAMPLES

tor-ctrl -q -- SETCONF bandwidthrate=1mb

tor-ctrl "GETINFO version"

tor-ctrl -s 9051 -p foobar -- GETCONF bandwidthrate

For setting the bandwidth for specific times of the day, I suggest calling tor-ctrl via cron, e.g.:

`0 22 * * * /path/to/tor-ctrl -c "SETCONF bandwidthrate=1mb"`

`0 7 * * *  /path/to/tor-ctrl -c "SETCONF bandwidthrate=100kb"`

This would set the bandwidth to 100kb at 07:00 and to 1mb at 22:00.  You can use notations like 1mb, 1kb or the number of bytes.

# WWW

https://gitweb.torproject.org/torspec.git/tree/control-spec.txt

# DISCLAIMER

This package is produced independently of, and carries no guarantee from, The
Tor Project.

# LICENSE

Copyright (c) 2007 by Stefan Behte

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
