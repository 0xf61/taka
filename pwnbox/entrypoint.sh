#!/bin/bash
set -e

service dbus start
rm -f /var/run/xrdp/xrdp.pid /var/run/xrdp/xrdp-sesman.pid /var/run/xrdp/xrdp-sesman.socket
/usr/sbin/xrdp-sesman
/usr/sbin/xrdp

tail -f /dev/null
