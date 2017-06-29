#!/bin/bash

path=$(type -p $0)
path=${path%/*}
[ -z "$path" ] && path='.'
. $path/init


cd $ntdir
b=$(ls */blocked | while read a ; do echo ${a%/blocked} ; done)

echo $b
ls -d $b

i=$($iptables -nL ssh | awk '/DROP/{print $4}')

echo $i
ls -d $i
