#!/bin/bash

##
## This script is designed to help connect to Vassar's eduroam network.
##

##
## Copyright (c) 2018 by Ian Leinbach
## This code is licensed under the MIT License.
##
## Permission is hereby granted, free of charge, to any person obtaining a copy of
## this software and associated documentation files (the "Software"), to deal in
## the Software without restriction, including without limitation the rights to
## use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
## the Software, and to permit persons to whom the Software is furnished to do so,
## subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in
## all copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
## FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
## COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
## IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
## CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
##

abort() {
	echo "Aborting $0 :(" 
	exit 1
}

echo -n "Checking for nmcli ... "
if [[ $(hash nmcli 2> /dev/null) -ne 0 ]]; then
	echo "NOT FOUND"
	abort
fi
echo "FOUND"

if [ "$#" -ne 2 ]; then
	echo "USAGE: $0 [interface] [identity]"
	echo "  [identity] should be your Vassar email."
	echo "  [interface] should be one of your network interfaces:"
	ip link show | sed -n 's/^[0-9]\+: \(.*\):.*/    ==> \1/p'
	abort
fi

INTERFACE="$1"
IDENTITY="$2"

echo -n "Checking for an existing eduroam connection ... "
if [[ $(nmcli connection show | grep -q ^eduroam\s.*) -eq 0 ]]; then
	echo "FOUND"
	echo -n "Removing old eduroam connection ... "
	nmcli connection delete id "eduroam" > /dev/null 2>&1
	echo "DONE"
else
	echo "NOT FOUND"
fi

echo -n "Adding eduroam connection ... "

nmcli connection add type wifi \
con-name "eduroam"             \
ifname "$INTERFACE"            \
ssid "eduroam" --              \
wifi-sec.key-mgmt wpa-eap      \
802-1x.eap peap                \
802-1x.phase2-auth mschapv2    \
802-1x.identity "$IDENTITY"    > /dev/null 2>&1

if [ $? -eq 0 ]; then
	echo "DONE"
else
	echo "FAILED"
	abort
fi

nmcli --ask connection up eduroam
