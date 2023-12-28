#!/bin/zsh
# -----------------------------------------------------------------------------
# # This shell file is designed to run every two hours as a cron job.
#  - First, you must give this shell script executable permissions:
#      $ chmod +x ./runEmailScript.sh
#  - Next, to schedule this script as a cron job, run this command:
#      $ crontab -e
#  - This will open up a basic text editor. The page should be blank if you've
#    never created a crontab before.
#  - Add this line to the empty file:
#  	   0 */2 * * * /path/to/your/script.sh
#  	 Note: The first '0' is the 'minutes' field.
#  	  - '*/2' in the 'hours' field means the script will run every two hours.
#  	    The asterisk '*' stands for 'every hour', and the '/2' modifies this
#  	    to mean 'every 2 hours'.
#  	  - The subsequent '*'s represent 'every day of the month', 'every month',
#  	    and 'every day of the week', respectively. This ensures that the cron
#  	    job will run every day at 2-hour intervals, starting at 12 AM. If you
#  	    wake your MacBook up at 5 PM, then the next run will be at 6 PM, and
#  	    so on.
# -----------------------------------------------------------------------------

# NOTE: You'll need to update the path for 'LOG_FILE' to where
#       you've clone this repo to. Remember, the '~' to Shell, means
#       your User Home Directory.
LOG_FILE="~/Development/appleScripts/emailDetector/runLog"
LOG_FILE="${LOG_FILE/#\~/$HOME}"

APPLESCRIPT_PATH="./runEmailScript.applescript"

# Even tho crontab will run this script every 2 hours. This is only to make
# sure that the actual AppleScript is ran at least once per day. If you want
# to scan your iCloud Emails more than once per day, then change this variable.
#   - Right now, this appleScript will run every 4 hours, or 2 cronTab jobs.
EMAIL_SCAN_INCREMENT=4 #Hours

get_current_timestamp(){
  date '+%Y-%m-%d %H:%M:%S'
}

update_log(){
  now="$(get_current_timestamp)"
  echo "$now" > "$LOG_FILE"
}

check_internet(){
  ping -c 1 8.8.8.8 > /dev/null 2>&1
  return $?
}

if [ -s "$LOG_FILE" ]; then
  # Read the last run time from the log
  last_run=$(cat "$LOG_FILE")

  # Convert last run time and current time to seconds since Unix epoch
  last_run_sec=$(date -j -f "%Y-%m-%d %H:%M:%S" "$last_run" "+%s")
  current_time_sec=$(date "+%s")

  diff_hours=$(( (current_time_sec - last_run_sec) / 3600 ))


  if [ $diff_hours -ge $EMAIL_SCAN_INCREMENT ]; then
    # check for interner connectivity
    if check_internet; then
      osascript "$APPLESCRIPT_PATH"
      update_log
    fi
  fi
else
  # First time running this script. We'll grab the current time, subtract 24 hours.
  # and rerun the script. That way we force the script to scan the emails on the first run.
  current_time=$(date '+%Y-%m-%d %H:%M:%S')
  subtracted_time=$(date -j -v-24H -f "%Y-%m-%d %H:%M:%S" "$current_time" "+%Y-%m-%d %H:%M:%S")
  echo "$subtracted_time" > "$LOG_FILE"

  # Re-Run the same script
  ./runEmailScript.sh
fi

