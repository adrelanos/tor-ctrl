# tor-ctrl - control the tor process on the cli

Command line tool for setting up stream for communication from the Tor Controller's (client) to a Tor process (server). The client send commands using TCP sockets or Unix-domain sockets and receive replies from the server.

This package is produced independently of, and carries no guarantee from, The Tor Project.

## Table of contents

* [History](#history)
* [Features](#features)
* [Configuration](#configuration)
  * [Control method](#control-method)
  * [Authentication method](#authentication-method)
  * [Apply the changes](#apply-the-changes)
* [Installation](#installation)
  * [Requirements](#requirements)
  * [How to install tor-ctrl on any unix system](#how-to-install-tor-ctrl-on-any-unix-system)
  * [How to build deb package from source sode](#how-to-build-deb-package-from-source-sode)
    * [Build the package](#build-the-package)
    * [Install the package](#install-the-package)
    * [Clean up](#clean-up)
* [Usage](#usage)
  * [Circuits](#circuits)
  * [Streams](#streams)
  * [Debugging](#debugging)
    * [Permission denied](#permission-denied)
    * [Unkown](#unknown)

## History

**tor-ctrl** was created by Stefan Behte, later developed by Patrick Schleizer and further improved by nyxnor.

## Features

**ControlPort**/**ControlSocket**: the following socket types are accepted to connect to the controller:
* Unix-domain socket, specified as `[unix:]path`
* TCP socket, specified as `[addr:]port`

Autodetects the socket by reading the tor configuration.
If still unknown, will try TCP socket 127.0.0.1:9051.

**Authentication methods**:
* ~~SAFECOOKIE~~ (on the work, help wanted)
* COOKIE - discover it by sending PROTOCOLINFO, so no need to specify the file.
* HASHEDPASSWORD - needs to be specifiedo on the command line

## Configuration

The configuration lines below must be set inside your tor configuration file (torrc).

### Control method

This will be the socket that allows those connections to control the Tor process. Choose between `ControlPort` and `ControlSocket` (setting both means either control can be used).

**TCP socket**:
```sh
ControlPort 9051
```

**Unix domain socket**:
```sh
ControlSocket /var/run/tor/control
## or
#ControlPort unix:/var/lib/tor/control
```

### Authentication method

This is will be the method you will authenticate to the controller. Choose between `CookieAuthentication` and `HashedControlPassword` (Setting both authentication methods means either method is sufficient to authenticate to Tor)

**Cookie**:
```sh
CookieAuthentication 1
```

**Password**
Change `YOUR_PASSOWRD`, but maintain it double quoted)
```
printf '%s\n' "HashedControlPassword $(tor --hash-password "YOUR_PASSOWRD")"
```
the result of the above operation should be used as the configuration line.

### Apply the changes

If you have made any changes to the tor run commands file (torrc), you will need to send a HUP signal to tor as root to apply the new configuration:
```sh
pkill -sighup tor
## or
#ps -o user,pid,command -A | grep -E "/usr/bin/tor|/usr/local/bin/tor"
#kill -hup PID_FROM_ABOVE
```

If you have tor running with `SandBox 1`, you will need to restart tor.

## Installation

### Requirements

At least one of each item is necessary:

* Networking tool: **nc**/**socat**/**telnet**
* Hex converter: **xxd**/**hexdump**/**od**


### How to install tor-ctrl on any unix system

Install the script and the manual:
```sh
sudo ./configure.sh install
```

### How to build deb package from source sode

#### Build the package

Install developer scripts:
```sh
sudo apt install -y devscripts
```

Install build dependencies.
```sh
sudo mk-build-deps --remove --install
```
If that did not work, have a look in `debian/control` file and manually install all packages listed under Build-Depends and Depends.

Build the package without signing it (not required for personal use) and install it.
```sh
dpkg-buildpackage -b
```

#### Install the package

The package can be found in the parent folder.
Install the package:
```sh
sudo dpkg -i ../tor-ctrl_*.deb
```

#### Clean up

Delete temporary debhelper files in package source folder as well as debhelper artifacts:
```sh
sudo rm -rf tor-ctrl-build-deps_*.buildinfo tor-ctrl-build-deps_*.changes \
debian/tor-ctrl.debhelper.log debian/tor-ctrl.substvars \
debian/.debhelper debian/files \
debian/debhelper-build-stamp debian/tor-ctrl
```

Delete debhelper artifacts from the parent folder (including the .deb file):
```sh
sudo rm -f ../tor-ctrl_*.deb ../tor-ctrl_*.buildinfo ../tor-ctrl_*.changes
```

## Usage

It is required to read the [tor manual](https://gitweb.torproject.org/tor.git/tree/doc/man/tor.1.txt) and the [control-spec](https://gitweb.torproject.org/torspec.git/tree/control-spec.txt).

Read tor-ctrl's manual:
```sh
man tor-ctrl
```

See usage:
```sh
tor-ctrl -h
```

Run your first command: get your tor user:
```sh
tor-ctrl GETCONF User
```

### Circuits

Switch to clean circuits:
```sh
tor-ctrl SIGNAL NEWNYM
```

Get your circuits (raw):
```sh
tor-ctrl GETINFO circuit-status
```

That is not very clean to read, too much information, so lets organize it:
```sh
tor-ctrl-circuit
```

### Streams

Start listening for streams:
```sh
tor-ctrl -w SETEVENTS STREAM
```
From another terminal, connect via Tor to where you wish
```sh
curl -x socks5h://127.0.0.1:9050 https://check.torproject.org/api/ip
```
Return to the script and and watch the streams. Use the interrupt signal (Ctrl+C) to stop.

And if we could see the streams and to which circuit they are attached to and what is their target?
```sh
tor-ctrl-stream
```
From another terminal, connect via Tor to where you wish:
```sh
curl -x socks5h://127.0.0.1:9050 github.com
```
Return to the script and use the interrupt signal (Ctrl+C) to print out the stream events received.

### Debugging

#### Permission denied

If you receive permission denied, probably you are not running tor-ctrl with the user that can connect to tor's controller socket, which is the tor user.

On Tails:
```sh
sudo -u debian-tor tor-ctrl GETINFO version
```
On OpenBSD:
```sh
doas -u _tor tor-ctrl GETINFO version
```

#### Unknown

If the response is unexpected, run with option `-r` to get the information that will be used to connect to tor's controller. If they are correct, use option `-d` to debug the script and be very verbose.

**Warning: You should review the information before posting on a issue, because it can contain the authentication string (password and cookie hex) and the control host, in the case the host is external (not localhost), anyone with both information will be able to authenticate to your controller. If you haven't set the authentication method and the control host is external and shared, this is far worse as there is no authentication string, so strongly recommended to configure an [authentication method for your controller](#authentication-method).**
