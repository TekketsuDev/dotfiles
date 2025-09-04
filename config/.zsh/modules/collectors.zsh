# ================================
# ~/.zsh/modules/collectors.zsh
# ================================

extract() {
  if [ $# -lt 2 ]; then
    echo "Usage: extract + _usr | _passw | _email | _iban + <file>"
    return 1
  fi
  case "$1" in
    _usr)
      grep -i "user\|invalid\|authentication\|login" "$2";;
    _passw)
      grep -i "pwd\|passw" "$2";;
    _email)
      grep -E -o "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b" "$2";;
    _iban)
      egrep -a -o "\bISBN(?:-1[03])?:? (?=[0-9X]{10}$|(?=(?:[0-9]+[- ]){3})[- 0-9X]{13}$|97[89][0-9]{10}$|(?=(?:[0-9]+[- ]){4})[- 0-9]{17}$)(?:97[89][- ]?)?[0-9]{1,5}[- ]?[0-9]+[- ]?[0-9]+[- ]?[0-9X]\b" *.txt > "$2";;
  esac
}

search() {
  if [ $# -lt 1 ]; then
    echo "Usage: search +  _latest | _user | _group | _readable | _writable"
    return 1
  fi
  case "$1" in
    _latest)
      find / -maxdepth 5 -type f -printf "%T@ %Tc | %p \n" 2>/dev/null | \
        grep -Ev "\| /(proc|dev|run|var/log|boot|sys/)" | sort -nr | less;;
    _user)
      find / -maxdepth 10 -user $(id -u) -printf "%T@ %Tc | %p \n" 2>/dev/null | \
        grep -Ev "\| /(proc|dev|run|var/log|boot|sys/)" | sort -nr;;
    _group)
      find / -maxdepth 10 -group $(id -g) -printf "%T@ %Tc | %p \n" 2>/dev/null | \
        grep -Ev "\| /(proc|dev|run|var/log|boot|sys/)" | sort -nr;;
    _readable)
      find / -type d -maxdepth 4 -readable -printf "%T@ %Tc | %p \n" 2>/dev/null | \
        grep -Ev "\| /(proc|dev|run|var/log|boot|sys/)" | sort -nr;;
    _writable)
      find / -type d -maxdepth 10 -writable -printf "%T@ %Tc | %p \n" 2>/dev/null | \
        grep -Ev "\| /(proc|dev|run|var/log|boot|sys/)" | sort -nr;;
  esac
}

checkconn() {
  local ip=$1
  if [[ -z "$ip" ]]; then
    echo "Usage: checkconn <IP_ADDRESS>"
    return 1
  fi
  echo "🔍 Checking established connections for IP: $ip"
  sudo lsof -i -nP | grep -E "$ip.*ESTABLISHED"
}

