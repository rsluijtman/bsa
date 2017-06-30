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
echo '======================================='

i=$($iptables -nL ssh | awk '/DROP/{print $4}')

#echo $i
echo in iptables
ls -d $i


echo '======================================='
for a in $b 
do
  found=0
  for j in $i
  do
    [ $a = $j ] && { found=1 ; continue 2 ; }
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
    [ $a = $j ] && { found=1 ; continue 2 ; }
  done
  if [ $found = 0 ]
  then 
    echo $j not marked blocked
  fi
done

echo '======================================='

for a in *
do
  [ -f $a/blocked ] && continue
  for i in $a/a*
  do
    echo ${i%/*}
  done
done | uniq -c | sort -n

echo '======================================='
for a in */blocked
do
  i=${a%/*}
  for j in $i/a*
  do
    echo ${j%/*}
  done
done | uniq -c | sort -n
