#!/bin/bash

usage(){
  echo $program -bdhint
  exit 0
}

path=$(type -p $0)
path=${path%/*}
[ -z "$path" ] && path='.'
. $path/init


if [ $# = 0 ]
then
  all=1
else
  all=0
  blocked=0
  ipt=0
  diff=0
  nsort=0
  tsort=0
fi

rx='^-*(.)(.*)$'
while [ $# -gt 0 ]
do
  param=$1
  shift
  while [[ $param =~ $rx ]]
  do
    opt=${BASH_REMATCH[1]}
    param=${BASH_REMATCH[2]}
    case $opt in
      b) blocked=1
         ;;
      d) diff=1
         ;;
      h) usage
         ;;
      i) ipt=1
         ;;
      n) nsort=1
         ;;
      t) tsort=1
         ;;
      *) echo unknown parameter $opt
         usage
         ;;
    esac
  done

done

cd $ntdir

needborder=0
border='======================================='

declare -A b
if [ "$blocked" = 1 -o $all = 1 ]
then
  for a in */blocked
  do
    t=${a%/blocked}
    b[$t]=$(stat --printf %Y $a)
  done
  echo marked blocked
  ls -d ${!b[@]}
  needborder=1

fi

declare -A i
if [ "$ipt" = 1 -o $all = 1 ]
then
  for a in $($iptables -nL ssh | awk '/DROP/{print $4}' )
  do
    if [ -n ${b[$a]} ]
    then
      i[$a]=${b[$a]}
    else
      i[$a]=$(stat --printf %Y $a)
    fi
  done
  if [ $needborder = 1 ]
  then
    echo $border
    needborder=0
  fi
  echo in iptables
  ls -d ${!i[@]}
  needborder=1
fi

output=0
if [ "$diff" = 1 -o $all = 1 ]
then

  for a in ${!b[@]}
  do
    if [ -z "${i[$a]}" ]
    then
      if [ $needborder = 1 ]
      then
        echo $border
        needborder=0
      fi 
      echo $a not in iptables
      output=1
    fi
  done

  for j in ${!i[@]}
  do
    if [ -z "${b[$j]}" ]
    then
      if [ $needborder = 1 ]
      then
        echo $border
        needborder=0
      fi 
      echo $j not marked blocked
      output=1
    fi
  done
fi
if [ $output = 1 ]
then
  needborder=1
fi

if [ "$nsort" = 1 -o "$all" = 1 ]
then

  if [ $needborder = 1 ]
  then
    echo $border
    needborder=0
  fi
  echo noted
  for a in *
  do
    [ -f $a/blocked ] && continue
    for t in $a/a*
    do
      echo ${t%/*}
    done
  done | uniq -c | sort -n

  echo $border

  echo blocked
  for a in */blocked
  do
    t=${a%/*}
    for j in $t/a*
    do
      echo ${j%/*}
    done
  done | uniq -c | sort -n
  needborder=1
fi

if [ "$tsort" = 1 -a "$blocked" = 1  -o "$all" = 1 ]
then
  if [ $needborder = 1 ]
  then
    echo $border
    needborder=0
  fi
  #ls -dt ${!b[@]}
  printf "%-16s    %s\n" "address" "blocked on"
  for k in ${!b[*]}
  do
    echo ${b[$k]} $k
  done | sort -n | while read t a 
    do
      printf "%-16s    %s\n" $a "$( date -d @$t )"
    done
 
fi
