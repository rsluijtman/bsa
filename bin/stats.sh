#!/bin/bash

path=$(type -p $0)
path=${path%/*}
[ -z "$path" ] && path='.'
. $path/init


cd $ntdir
b=$(ls */blocked | while read a ; do echo ${a%/blocked} ; done)

#echo $b
echo marked blocked
ls -d $b

i=$($iptables -nL ssh | awk '/DROP/{print $4}')

#echo $i
echo in iptables
ls -d $i


for a in $b 
do
  found=0
  for j in $i
  do
    [ $a = $j ] && { found=1 ; continue ; }
  done
  if [ $found = 0 ]
  then 
    echo $a not in iptables
  fi
done


for j in $i
do
  found=0
  for a in $b 
  do
    [ $a = $j ] && { found=1 ; continue ; }
  done
  if [ $found = 0 ]
  then 
    echo $j not marked blocked
  fi
done
