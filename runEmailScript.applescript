-- This Applescript takes in a single Email Address. It will search your
-- iCloud email account for any emails from this email address no older
-- than 3 days from the current data( You can change this range in 'curoffDate')
-- If any emails are found. We take the subject and body of the email. Convert it
-- into a Text message. And Send it your specified apple phone number, using Apple
-- Messenger. Note: The only downside of this; when you send the message. You'll
-- notice in your phone that you'll have a 'Sent' copy of the message and a 'received'
-- copy of the message in your text messages. Since you're sending this to your phone
-- number From your phone number.

-- Remember:: You'll need to update both 'targetSender' and 'youNumber' variables before
--            running this script.

display notification "Running Email Script"
tell application "Mail"
	set targetSender to "THE.EMAIL.ADDRESS@WHO_YOU_WANT_TO_SEARCH_FOR.com"
	set currentDate to current date
	set cutoffDate to currentDate - (3 * days)
	set debug to false

	set inboxMessages to messages of inbox
	set foundEmail to false
	set emailContent to ""

	repeat with msg in inboxMessages
		if sender of msg contains targetSender and (date received of msg) > cutoffDate then
			set emailSubject to subject of msg
			set emailBody to content of msg -- Ensure this is correct
			set emailContent to "Subject: " & emailSubject & "
" & emailBody
			set foundEmail to true
			exit repeat
		end if
	end repeat
end tell

tell application "Messages"
	set yourNumber to "+15558994200" -- Change to your phone number
	if foundEmail then
		send emailContent to participant yourNumber
	else
		if debug then
			send "This is a test message from AppleScripts" to participant yourNumber
		end if
	end if
end tell
