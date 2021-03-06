#!/bin/sh -e
#
# Copyright (c) 2014 Robert Nelson <robertcnelson@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

get_device () {
	machine=$(cat /proc/device-tree/model | sed "s/ /_/g")
	case "${machine}" in
	TI_AM335x_BeagleBone)
		SOC="omap-psp"
		;;
	*)
		echo "Machine: [${machine}]"
		SOC="armv7"
		;;
	esac
}

latest_version () {
	if [ ! "x${SOC}" = "x" ] ; then
		cd /tmp/
		if [ -f /tmp/LATEST-${SOC} ] ; then
			rm -f /tmp/LATEST-${SOC} || true
		fi
		if [ -f /tmp/install-me.sh ] ; then
			rm -f /tmp/install-me.sh || true
		fi

		wget ${mirror}/${dist}-${arch}/LATEST-${SOC}
		if [ -f /tmp/LATEST-${SOC} ] ; then
			latest_kernel=$(cat /tmp/LATEST-${SOC} | grep ${kernel} | awk '{print $3}' | awk -F'/' '{print $6}')
			if [ "xv${current_kernel}" = "x${latest_kernel}" ] ; then
				echo "v${current_kernel} is latest"
			else
				wget $(cat /tmp/LATEST-${SOC} | grep ${kernel} | awk '{print $3}')
				if [ -f /tmp/install-me.sh ] ; then
					if [ "x${rcn_mirror}" = "xenabled" ] ; then
						sed -i -e 's:disabled:enabled:g' /tmp/install-me.sh
					fi
					/bin/bash /tmp/install-me.sh
				else
					echo "error: kernel: ${kernel} not on mirror"
				fi
			fi
		fi
	fi
}

specific_version () {
	cd /tmp/
	if [ -f /tmp/install-me.sh ] ; then
		rm -f /tmp/install-me.sh || true
	fi
	wget ${mirror}/${dist}-${arch}/${kernel_version}/install-me.sh
	if [ -f /tmp/install-me.sh ] ; then
		if [ "x${rcn_mirror}" = "xenabled" ] ; then
			sed -i -e 's:disabled:enabled:g' /tmp/install-me.sh
		fi
		/bin/bash /tmp/install-me.sh
	else
		echo "error: kernel: ${kernel_version} doesnt exist"
	fi
}

checkparm () {
	if [ "$(echo $1|grep ^'\-')" ] ; then
		echo "E: Need an argument"
		exit
	fi
}

dist=$(lsb_release -cs)
arch=$(dpkg --print-architecture)
current_kernel=$(uname -r)

kernel="STABLE"
mirror="http://rcn-ee.net/deb"
unset rcn_mirror
unset kernel_version
# parse commandline options
while [ ! -z "$1" ] ; do
	case $1 in
	--use-rcn-mirror)
		mirror="http://rcn-ee.homeip.net:81/dl/mirrors/deb"
		rcn_mirror="enabled"
		;;
	--kernel)
		checkparm $2
		kernel_version="$2"
		;;
	--beta-kernel)
		kernel="TESTING"
		;;
	--exp-kernel)
		kernel="EXPERIMENTAL"
		;;
	esac
	shift
done

get_device
if [ "x${kernel_version}" = "x" ] ; then
	latest_version
else
	specific_version
fi
#
