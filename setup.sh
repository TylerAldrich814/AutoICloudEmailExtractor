#!/bin/zsh

# Setup script for Adding a LaunchAgent to Library/LaunchAgents. This methods
# better than using crontab, since LaunchAgents are allowed access to Apples GUI.
#
# All this script does is request a time frame for how often you want the script to run.
# Then, this script will take the example.com.yourusername.runemailscript.plist file.
# Replace a few directories and the minute timeframe.
# Save it @ ~/Library/LaunchAgents/com.USERNAME.runemailscript.plist
# And finally, Activate the plist file via launchctl
#
# LaunchCTL Logging files
#  echo logs -> /tmp/com.USERNAME.runemailscript.out
#   err logs -> /tmp/com.USERNAME.runemailscript.err
get_current_timestamp(){
  date '+%Y-%m-%d %H:%M:%S'
}
log(){
  echo "$(get_current_timestamp) :: $1"
}
cat_file(){
  if [ ! -f "$1" ]; then
    echo "File not found: $1"
    exit 1
  fi

  longest=0
  while IFS= read -r line; do
    line_len=${#line}
    if [[ line_len -ge longest ]]; then
      longest=$line_len
    fi
  done <$1

  longest=$((longest + 10))
  breakline=$(printf '_%.0s' $(seq 1 $(( $longest + 5 ))))
  echo "$breakline"
  echo "|$(printf ' %.0s' $(seq 1 $(( $longest + 3))))|"
  while IFS= read -r line; do
    length=${#line}
    padding=$(printf ' %.0s' $(seq 1 $(( $longest - $length))))
    echo "|   $line$padding|"
  done < $1
  echo $breakline
}


USERNAME=$(whoami)

LCTL_ERR_FILE="/tmp/com.$USERNAME.runemailscript.err"
LCTL_OUT_FILE="/tmp/com.$USERNAME.runemailscript.out"

MODE=$1
in_debug=0

while [ "$1" != "" ]; do
  log $1
  case $1 in
    -d | --debug )
      log "in debug mode"
      in_debug=1
      ;;
    -e | --error )
      if [[ $in_debug -eq 1 ]]; then
        log "Reading Err Log: $LCTL_ERR_FILE"
        cat_file "$LCTL_ERR_FILE"
      fi
      ;;
    -o | --out )
      if [[ $in_debug -eq 1 ]]; then
        log "Reading Out log: $LCTL_OUT_FILE"
        cat_file "$LCTL_OUT_FILE"
      fi
      ;;
    * )
      if [[ $in_debug -eq 1 ]]; then
        return 0
      fi
      ;;
  esac
  shift
done
if [[ $in_debug -eq 1 ]]; then
  echo $in_debug
  log "In debug - exiting"
  return 0
fi


function create_plist(){
  MINUTES=$1

  TEMPLATE_PLIST="${PWD}/example.com.yourusername.runemailscript.plist"
  TEMPLATE_PLIST="${TEMPLATE_PLIST/#\~/$HOME}"

  TARGET_PLIST="$HOME/Library/LaunchAgents/com.$USERNAME.runemailscript.plist"
  TARGET_PLIST="${TARGET_PLIST/#\~/$HOME}"

  PATH_TO_SCRIPT="${PWD}/runemailscript.sh"
  SEARCH_AND_REPLACE="s|yourusername|$USERNAME|g; s|path/to/your/script.sh|$PATH_TO_SCRIPT|g; s|MINUTES|$MINUTES|g;"

  mkdir -p ~/Library/LaunchAgents/

  # -> First check to see if $TARGET_PLIST exists:
  #    If so, renove file, and unload from launchctl
  if [ -f "$TARGET_PLIST" ]; then
    echo " -> Disabling and Removing old plist file before installing updated plist"
    launchctl unload $TARGET_PLIST
    rm $TARGET_PLIST
  fi

  sed $SEARCH_AND_REPLACE "$TEMPLATE_PLIST" > "$TARGET_PLIST"

  echo " -> Plist file created at $TARGET_PLIST"
  echo " -> Loading generating plist file.."
  launchctl load $TARGET_PLIST
  echo " -> Verifying that the Plist was loaded"
  echo "$(launchctl list | grep com.$USERNAME.runemailscript)"
}

function main(){
  local interval
  echo "How often would you liek to run the script?"
  echo "Example Inputs: 1d, 1h, 1m, 2d2h, 2h30m, 2d30m, 7d12h30m"
  read -r interval

  #if [[ $interval =~ ^([0-9]+h)?([0-9]+m)?$ ]]; then
  if [[ $interval =~ ^([0-9]+d)?([0-9]+h)?([0-9]+m)?$ ]]; then

    days=$(echo $interval | grep -o '[0-9]\+d' | grep -o '[0-9]\+' )
    hours=$(echo $interval | grep -o '[0-9]\+h' | grep -o '[0-9]\+')
    minutes=$(echo $interval | grep -o '[0-9]\+m' | grep -o '[0-9]\+')

    # Default values if not specified
    [[ -z $days    ]] && days=0
    [[ -z $hours   ]] && hours=0
    [[ -z $minutes ]] && minutes=0

    msg="You chose to run the script every"
    if [[ $days -ge 1 ]]; then
      msg="$msg $days days"
    fi
    if [[ $hours -ge 1 ]]; then
      if [[ $minutes -eq 0 ]]; then
        msg="$msg, and $hours hours"
      else
        msg="$msg, $hours hours"
      fi
    fi
    if [[ $minutes -ge 1 ]]; then
      msg="$msg, and $minutes minutes"
    fi

    total_seconds=$((days * 24 * 3600 + hours * 3600 + minutes * 60))
    msg="$msg, or every $total_seconds seconds."
    echo $msg

    create_plist $total_seconds

  else
    echo "Invalid Format: Please enter a number followed by 'h' for hours or 'm' for minutes."
    return 1
  fi
}

main
