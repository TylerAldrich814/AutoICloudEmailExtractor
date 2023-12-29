# AppleScript for Automated Email Alerts

#### This repository hosts an AppleScript designed to streamline email monitoring and notification. The script actively searches your iCloud inbox for new emails from a specified address. Upon detection of a new email from this address, the script automatically sends a notification to a predefined phone number. This is the product of my laziness, and how badly I suck at remembering to check my emails.

### Key Features:


- This AppleScript is wrapped in a shell script that stores the timestamp of the last run cycle. The default setup ensures that this AppleScript runs at least once every 4 hours via a crontab or whenever your computer wakes up.

- When an email matching the specified address is found, the subject and body of the email are extracted, converted into a text message, and sent to the provided cellphone number.


### I've included three differnt ways to run this AppleScript automatically. Tho I'm personally using the LaunchCTL version. I had issues getting both SleepWatcher and crontab to work. Launchctl has access to Apples GUI, which allows the notifications to populate

### launchctl setup.
- Using `setup.sh` :: The script will ask you to input a timing interval.
- Following the instructions, `setup.sh` will then compile a LaunchAgent file at `~/Library/LaunchAgents/`
- The script will also Enable this generated file. If you run setup.sh a second time, the script will first unload the original LaunchAgent, remove the original file. And then regenerate and start the new file.
- To manually remove this LaunchAgent
```shell
launchctl unload ~/Library/LaunchAgents/com.YOUR_USERNAME.runemailscript.plist
rm ~/Library/LaunchAgents/com.YOUR_USERNAME.runemailscript.plist
```

### crontab setup
- Open up `./runEmailScript.sh`. You'll need to update `LOG_FILE`'s directory path.
- Next, Open up `./runEmailScript.applescript` in Apple Script Editor. You'll need to update 2 variables in this file
```shell
set targetSender to "the.email.address@to.search.for.com"
  #.........
tell application "Messages"
    set yourNumber to "+15558991199" -- Change this to the number you want to send the txt to
```
- Also, the default setup is to search all emails up to 3 days prior. You can change this in
```shell
set cutoffDate to currentDate - (3 * days)
```

- Next, You must add permissions to the shellscript.
```shell
chmod +x ./runEmailScript.sh
```
- Next, open the shellscript, update the LOG_FILE variable.
- Finally, update crontab
```shell
crontab -e
# After crontab file opens add
0 */2 * * * cd /absolute/path/to/appleScripts/emailDetector && ./runEmailScript.sh
# Save and exit
```

### SleepWatcher setup
- Install SleepWatcher. Sleepwatcher is an apple application that will run provided shellscripts for both when your computer goes to sleep and when it wakes up.
```shell
brew update && brew install sleepwatcher
```
- On MacOS Sonoma, you'll find SleepWatcher's plist file at
```shell
cd /opt/homebrew/opt/sleepwatcher/homebrew.mxcl.sleepwatcher.plist
```
- Open this file, towards the bottom you'll find these lines(note. To run a script when your computer goes to sleep, create the shell script under `<string>-s</string>`)
```html
	<string>-s</string>
	<string>/Users/homeDirectory/.sleep</string>
	<string>-w</string>
```
- Underneath `<string>-w</string>` Add:
```html
	<string>/absolute/path/to/appleScripts/emailDetector</string>

```
- Save and exit
- Finally, you'll start sleepwatcher as a service
```shell
brew services start sleepwatcher
```

