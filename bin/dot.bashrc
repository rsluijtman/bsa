  # whitelist your source addres, so it will not be blocked by accident

  rx='(\S+) '
  if [[ "$SSH_CLIENT" =~ $rx ]]
  then 
    a=${BASH_REMATCH[1]}
    /usr/local/bsa/bin/whitelist $a
  fi

