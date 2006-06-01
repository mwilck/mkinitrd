#!/bin/bash
# 
# <client-ip>:<server-ip>:<gw-ip>:<netmask>:<hostname>:<device>:<autoconf>
#

# Calculate the prefix to a given netmask
calc_prefix() {
    local netmask=$1
    local prefix

    set -- $(IFS=.; echo $netmask)

    # Analyze each block
    prefix=0
    while [ "$1" ] && (( $1 == 255 )); do
	prefix=$(($prefix + 8))
	shift
    done
    # Bit-shift first non-zero block
    if [ "$1" ] && (( $1 > 0 )); then
	mask=$1
	prefix=$(($prefix + 8))
	while (( ($mask & 0x1) == 0 )) ; do
	    mask=$(( $mask >> 1 ))
	    prefix=$(($prefix - 1))
	done
    fi
    echo $prefix
}

ipcfg=$(echo $1 | sed 's/::/:_:/g')

set -- $(IFS=: ; echo $ipcfg )

client=$1
shift
if [ "$1" != "_" ] ; then
    peer=$1
fi
shift
if [ "$1" != "_" ] ; then
    gateway=$1
fi
shift
if [ "$1" != "_" ] ; then
    netmask=$1
fi
shift
if [ "$1" != "_" ] ; then
    hostname=$1
fi
shift
if [ "$1" != "_" ] ; then
    dev=$1
else
    dev=eth0
fi
shift
if [ "$1" != "_" ] ; then
    mode=$1
fi
shift

if [ "$mode" ] ; then
    echo "Ignoring mode $mode, using static configuration"
fi

# Calculate the prefix
prefix=${client%%*/}
if [ "$prefix" == "$client" ] ; then
    if [ -n "$netmask" ] ; then
	prefix=$(calc_prefix $netmask)
    else
	prefix=24
    fi
fi

# Configure the interface
if [ "$peer" ] ; then
    /sbin/ip addr add ${client} peer ${peer}/$prefix dev $dev
else
    /sbin/ip addr add ${client}/${prefix} dev $dev
fi
/sbin/ip link set $dev up

if [ "$gateway" ]; then
    /sbin/ip route add to default via ${gateway}
fi
