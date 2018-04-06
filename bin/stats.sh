#!/bin/bash

usage(){
  echo $program -bdhint
  echo -b: blocked acording db
  echo -d: show diff between db and iptables
  echo -h: this help
  echo -i: blocked by iptables
  echo -n: noted addresses
  echo -q: questionable
  echo -t: sorted by time
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
  noted=0
  nsort=0
  tsort=0
  quest=0
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
      n) noted=1
         ;;
      q) quest=1 
         ;;
      t) tsort=1
         ;;
      *) echo unknown parameter $opt
         usage
         ;;
    esac
  done

done


needborder=0
border='======================================='

# b: noted blocked
declare -A b
# n: only noted
declare -A n
if [ "$blocked" = 1 -o "$noted" = 1  -o $all = 1 ]
then
  cd $ntdir
  for a in *
  do
    if [ -f $a/blocked ]
    then
      b[$a]=$(stat --printf %Y $a/blocked)
    else
      n[$a]=$(stat --printf %Y $a)
    fi
  done
  echo marked blocked
  ls -d ${!b[@]}
  needborder=1

fi

# i: from iptables
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

if [ "$noted" = 1 -o "$nsort" = 1 -o "$all" = 1 ]
then

  if [ $needborder = 1 ]
  then
    echo $border
  fi
  echo noted
  for a in *
  do
    [ -f $a/blocked ] && continue
#    n[$a]=$(stat --printf %Y $a)
    for t in $a/a*
    do
      echo ${t%/*}
    done
  done | uniq -c | sort -n
  needborder=1
fi

if [ "$tsort" = 1 -a "$noted" = 1  -o "$all" = 1 ]
then
  if [ $needborder = 1 ]
  then
    echo $border
  fi
  printf "%-16s    %s\n" "address" "noted on"
  for k in ${!n[*]}
  do
    echo ${n[$k]} $k
  done | sort -n | while read t a
    do
      printf "%-16s    %s\n" $a "$( date -d @$t )"
    done

  echo $border
fi

############

if [ "$blocked" = 1 -o "$all" = 1 ]
then
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
  echo $border

  printf "%-16s    %s\n" "address" "blocked on"
  for k in ${!b[*]}
  do
    echo ${b[$k]} $k
  done | sort -n | while read t a
    do
      printf "%-16s    %s\n" $a "$( date -d @$t )"
    done

fi

if [ "$quest" = 1 -o "$all" = 1 ]
then
  echo $border

  # show address, time blocked, number of times noted after blocked, last time noted
  cd $ntdir 
  declare -a names # declare array
  for a in */blocked
  do
    d=${a%/b*}
    cd $d
    names=($(ls -t))
    top=$((n-1))
    last=${names[0]}
    if [ $last != blocked ]
    then
      et=$(stat --printf %Y $last)
      tb=$(stat --printf %Y blocked)
      dt=$((et-tb))       
      # number of tmes noted after blocked:

      for (( i=0 ; i<${#names[*]};i++ ))
      do
        [ ${names[$i]} = blocked ] && break
      done
     
      printf "%-16s %3d %6ds   %s\n" $d $i $dt "$(date -d @$et +"%Y-%m-%d %H:%M")"
    fi
    cd ..
  done
fi
