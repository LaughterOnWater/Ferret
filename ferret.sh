#!/bin/bash
# ferret.sh
# A simple script to determine whether someone has been 
# tampering with your hosted service.
#
# Copyright (c) 2012, Chris Sparnicht
# Laughter On Water
# http://low.li/contact
# All rights reserved.
#
# This code is licensed under this BSD license:
# The license text can be found at
# http://www.opensource.org/licenses/BSD-3-Clause
#
# Redistribution and use in source and binary forms, 
# with or without modification, are permitted provided 
# that the following conditions are met:
#
#  * Redistributions of source code must retain the 
#	above copyright notice, this list of conditions 
#	and the following disclaimer.
#  * Redistributions in binary form must reproduce 
#	the above copyright notice, this list of 
#	conditions and the following disclaimer in the 
#	documentation and/or other materials provided 
#	with the distribution.
#  * Neither the name of the Organization 
#	'Laughter On Water' nor the names of its 
#	contributors(Chris Sparnicht or others) may be 
#	used to endorse or promote products derived from 
#	this software without specific prior 
#	written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS 
# AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED 
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO 
# EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS 
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (
# INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
# OF THE USE OF THIS SOFTWARE, EVEN IF 
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Instructions:
# Move this script in your home directory, perhaps
# where you have other shell scripts that you have
# either created, perhaps '~/admin/scripts'.
# Create an alias in your .bash_profile 
# alias ferret="~/admin/scripts/ferret.sh"
# Manually add the alias in shell for your current
# session and give it a try:
# $ ferret -h
# Good luck!
#
# Please let me know if you found this script useful
# on the web page for ferret.
# http://low.li/story/2012/04/ferret


# Variable(s)
SHOW_VARS=0 # For troubleshooting variables. 0 to hide, 1 to show.

function readme {
	# This is the extended readme for clear explanation of 
	# how this script works.
	echo "##############
# FERRET 1.0 #
##############

NAME
	ferret - discover various information from dreamhost logs

SYNOPSIS
	ferret [ -c | -i | -l | -m | -h ] OR [ -u | -e domain ]

DESCRIPTION
	Ferret is based on the Detection Intrusion wiki page found here:
	http://wiki.dreamhost.com/Detecting_intrusions
	
This script is provided mostly for small and dev sites that 
	get hardly any traffic but want to quickly check against 
	the possibility of intrustion by hackers. If you get a lot of
	traffic, this script is too basic for your needs and you should
	hire someone to manage your site.

	- check out which IPs have been logging in how much,
	- checks for file modification time (could be time consuming)
	- list and count all unique requests
	- scrub for large files

OPTIONS

	-c Check for large folder sizes. Anything out of the ordinary.

	-m Check file modification times. 
	
	-i Check what IP addresses are visiting your domain most.

	-l List user's domains with error logs

	-u List and count all unique requests in the past 30 days
	
	-e List and count all unique requests that created a 404 response
	
	-h This help text.
	
EXAMPLES
	First, use 'ferret -l' to list all domains that have 
	access/error logs. Then check what requests have been 
	happening on both access and error logs.
		'ferret -u domain.com' or 'ferett -e domain.com'
	If there are odd queries, or queries that ask for things 
	that shouldn't exist, you may need to look closer at this site
	
	Next let's look at a list of recent unique IP's to see if we 
	have someone making a lot of visits that don't make sense.
		'ferret -i domain.com'
	Suppose there is an IP that visited a thousand times, but 
	you have no idea who or why, especially when nobody else is 
	visiting more than 15 times. Once you know the IP you 
	can 'host ###.###.###.###' to find out 
	more about the IP.
	
	If you haven't edited any documents recently, use 'ferret -m' 
	to see which files have been most recently modified. 
	If you think the IP is fishy you can block them in 
	your .htaccess file for this domain.
	
	"
}

function shortreadme {
	# If condition and / or file existence fail, say this.
	echo "ferret [ -c | -i | -l | -m ] OR [ -u | -e domain ]
	"
}

function lastarg() {	
	# If the second argument is not a file folder, fail.
	if [ $arg ] 
	then
		URI=$arg 
		
		MY_SITE=$URI
		LOGS_PATH=$HOME/logs/$MY_SITE/http
		ERROR_LOG=$LOGS_PATH/error.log.0
		ACCESS_LOG=$LOGS_PATH/access.log.0
		if [ -f $ERROR_LOG ]
		then
			ELOG=1
		else
			ELOG=0
			ERROR_LOG=
			LOGS_PATH=
		fi
		
		if [ -f $ACCESS_LOG ]
		then
			ALOG=1
		else
			ALOG=0
			ACCESS_LOG=
			LOGS_PATH=
		fi
		
		
		
	fi
	
}

function validateargs { 
	# If more than one argument is called, fail.
	let "ARGCHK=IPS+MODS+VERRORS+UNQ+CHKD+LSTLOGS+HELP"

	if [ $ARGCHK = 1 ]
	then
		echo # Do nothing.
	elif [ $ARGCHK > 1 ]
	then
		echo "Oops...
		"
		shortreadme
	else
		shortreadme
	fi
}

function checkDiskUsage {
	/usr/bin/find $HOME -maxdepth 1 -type d -exec du -s {} \; \
   | /usr/bin/sort -nr \
   | /usr/bin/awk -v HOME="$HOME/?" '{
    $1 = $1/1000;
    if ($1 > 1000) {
        $1 = $1/1000
        UNIT="G"
    } else {
        UNIT="M"
    }
    sub(HOME,"",$2);
    printf "%.2f%s\t%s\n", $1, UNIT, $2
   }'
}

function showUnique {
if [ -s $ACCESS_LOG ]
then
	/usr/bin/awk '{
		# to list the entire request, not just the base,
		# replace the following two lines with: a[$7]++
		split($7,req,"/");
		a[req[2]]++
	}END{
		for(i in a){
			print a[i]"\t"i
		}
	}' $ACCESS_LOG \
	| /usr/bin/sort -nr
else
	echo "Access log contains no recent records."
fi
}

function showUniqueErrors {
if [ -s $ERROR_LOG ]
then
/usr/bin/awk '$9==404 {
   a[$7]++
}END{
   for(i in a){
       print a[i]"\t"i
   }
}' $ERROR_LOG \
| /usr/bin/sort -nr
else
	echo "Error log contains no recent records."
fi
}

function showModTimes {
/usr/bin/find $HOME -mtime -2 -type f \
   | /bin/sed -r 's|^(\/[^\/]+){2}||' \
   | /usr/bin/awk '
        # the following line skips any directories which change often and you are sure do not represent a threat
        /\/(\.git|\.svn|cronjobs|cache|objects|logs|tmp)\// ||
        # the following line skips any file types which you are sure do not represent a threat
        /\.(txt|log|zip|prop|meta|gif|png|gz|po|mo|ico)$/ ||
        /^\./ {
            next;
        }
        {   
            print;
        }'
}

function listLogFolders {
	ls -d $HOME/logs/
}

function listIPs {
	if [ -s $ACCESS_LOG ]
	then
		tail -10000 $ACCESS_LOG | awk '{print $1}' | sort | uniq -c | sort -n
	else
		echo "Access Log contains no current log data."
	fi
}

function showVars {
	if [ $SHOW_VARS = 1 ]
	then
		echo "ARGCHK = $ARGCHK"
		echo "Index = $index"
		echo "IPS = $IPS"
		echo "VERRORS = $VERRORS"
		echo "MODS = $MODS"
		echo "UNQ = $UNQ"
		echo "CHKD = $CHKD"
		echo "LSTLOGS = $LSTLOGS"
		echo "HELP = $HELP"
		echo "URI = $URI"
		echo "MY_SITE = $MY_SITE"
		echo "ALOG = $ALOG"
		echo "ELOG = $ELOG"
		echo "LOGS_PATH = $LOGS_PATH"
		echo "ERROR_LOG = $ERROR_LOG"
		echo "ACCESS_LOG = $ACCESS_LOG"
	fi
}

# Shell wrapper for no argument...
E_BADARGS=65

if [ ! -n "$1" ]
then
  # echo "Usage: `$0` [ argument ] or [ argument domain ]"
	echo "No arguments passed. Please read:
	"
	shortreadme
	exit $E_BADARGS
fi


# Begin basic parsing of arguments...
index=1          # Initialize count
for arg in $* # Role through each case for every argument separated by a space. 
do
  case "$arg" in
	# if -i
	-i)
		IPS=1
		;;
	# if -e
	-e)
		VERRORS=1
		;;
	# if -m
	-m)
		MODS=1
		;;
	# if -u
	-u)
		UNQ=1
		;;
	# if -c
	-c)
		CHKD=1
		;;
	# if -help
	-l)
		LSTLOGS=1
		;;
	# if -usage, use usage function
	-h)
		HELP=1
		;;
	# second (last argument) verify...
	*)
		lastarg
	;;
  esac
  let "index+=1"
done         # end the 'for' loop.

# Validate.
validateargs

# Show variables if $SHOW_VARS is set.
showVars

# Parse what to do .
if [ "$index" = "2" ] && [ "$ARGCHK" = "1" ] && [ "$CHKD" = "1" ]
then # -c
	echo "Now determining folder sizes for this user.
Please wait..."
	checkDiskUsage
elif [ "$index" = "3" ] && [ "$ARGCHK" = "1" ] && [ "$IPS" = "1" ] && [ "$ALOG" = "1" ]
then # - i  domain
	echo "List of available domain folders with logs:"
	listIPs
elif [ "$index" = "3" ] && [ "$ARGCHK" = "1" ] && [ "$UNQ" = "1" ] && [ "$ALOG" = "1" ]
then # -u domain
	echo "Find unique requests in access log for $URI.
Please wait..."
	showUnique
elif [ "$index" = "3" ] && [ "$ARGCHK" = "1" ] && [ "$VERRORS" = "1" ] && [ "$ELOG" = "1" ]
then # - e domain
	echo "Find unique requests in error log for $URI.
Please wait..."
	showUniqueErrors
elif [ "$index" = "2" ] && [ "$ARGCHK" = "1" ] && [ "$MODS" = "1" ]
then # - m 
	echo "Finding recently modified documents.
Please wait..."
	showModTimes
elif [ "$index" = "2" ] && [ "$ARGCHK" = "1" ] && [ "$HELP" = "1" ]
then # - h 
	readme
elif [ "$index" = "2" ] && [ "$ARGCHK" = "1" ] && [ "$LSTLOGS" = "1" ]
then # - l 
	echo "List of available domain folders with logs:"
	ls $HOME/logs/
else
	echo "Parameters may be incorrect.
Please type 'ferret -h' to get help."
fi

# Done.
echo "
.done.
"
exit 0
