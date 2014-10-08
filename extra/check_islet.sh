#!/usr/bin/env bash

# Author: Jon Schipp <jonschipp@gmail.com>
# Date: 10-08-2014
########
# Examples:

# 1.) Check status of the ISLET configuration
# $ ./check_islet.sh -f /etc/islet/islet.conf -T status

# 2.) Check all configurations for images
# $ ./check_islet.sh -T available -s islet.conf,test.conf

# 3.) Count configurations marked invisible
# $./check_islet.sh -T unavailable -c 0

# NRPE

# command[check_islet_status]=/usr/local/nagios/libexec/check_islet.sh -T status
# command[check_islet_available]=/usr/bin/sudo /usr/local/nagios/libexec/check_islet.sh -T available -s islet.conf

# Nagios Exit Codes
OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3

# Default location of global config
# Set this to the proper location if your installation differs or use ``-f''
CONFIG=/etc/islet/islet.conf

# Default installation location
# Set this to the proper location if your installation differs
INSTALL_DIR=/opt/islet

# Default user
# Set this to the proper user if yours differs
USER=demo

usage()
{
cat <<EOF

Check status of ISLET configuration.

     Options:
        -f <path>               Set optional absolute path of global config (def: $CONFIG)
        -T <type>               Check type, "status/available/unavailable/print"
                                status           - Checks status of islet by verifying configuration 
				available  	 - Check available configurations for images
				unavailable 	 - Check configurations marked as invisible
	-s <item>		Item(s) to skip (sep:,) "islet.conf,test.conf"
        -c <int>                Critical value
        -w <int>                Warning value

Usage: $0 -f /etc/islet/islet.conf -T status
$0 -T available -s islet.conf,test.conf -c 0
EOF
}

argcheck() {
# if less than n argument
if [ $ARGC -lt $1 ]; then
        echo "Missing arguments! Use \`\`-h'' for help."
        exit 1
fi
}

check_values(){
if [ ${1:-$MISSING} -gt $CRIT ]; then
	echo "CRITICAL: Failed item count of ${1:-$MISSING} is greater than $CRIT"
        exit $CRITICAL
elif [ ${1:-$MISSING} -gt $WARN ]; then
	echo "WARNING: Failed item count of ${1:-$MISSING} is greater than $WARN"
        exit $WARNING
else
	echo "SUCCESS: Everything is referenced properly"
        exit $OK
fi 
}

# Declarations
CRIT=0
WARN=0

LIST_CHECK=0
AVAILABLE_CHECK=0
UNAVAILABLE_CHECK=0
VARIABLE_CHECK=0
STATUS_CHECK=0
PRINT_CHECK=0
MISSING=0
COUNT=0
ARGC=$#
LIST=()

argcheck 1

while getopts "hfc:p:s:T:w:" OPTION
do

     case $OPTION in
         h)
             usage
             ;;
         f)
             shift
             if [[ $1 == *islet.conf ]]; then
                CONFIG="$1"
             else
                echo "File name appears to be incorrect, not islet.conf)"
             fi
             ;;
         c)
             CRIT="$OPTARG"
             ;;
         p)
             PRINT="$OPTARG"
             ;;
         s)
             SKIP=$(echo "$OPTARG" | sed 's/,/ /g')
             ;;
         T)
             if [[ "$OPTARG" == status ]]; then
                        STATUS_CHECK=1 
             elif [[ "$OPTARG" == available ]]; then
			LIST_CHECK=1
                        AVAILABLE_CHECK=1
             elif [[ "$OPTARG" == unavailable ]]; then
			LIST_CHECK=1
                        UNAVAILABLE_CHECK=1
             elif [[ "$OPTARG" == variable ]]; then
                        PRINT_CHECK=1
             else
                        echo "Unknown argument type"
                        exit $UNKNOWN
             fi
             ;;
         w)
             WARN="$OPTARG"
             ;;
         \?)
             exit 1
             ;;
     esac
done

if [ $LIST_CHECK -eq 1 ] || [ $STATUS_CHECK -eq 1 ] || [ $VARIABLE_CHECK -eq 1 ] ; then

        if [ -f $CONFIG ];
        then
		source $CONFIG
	else
                 echo "ERROR: islet.conf has not been found. Update the CONFIG variable in $0 or specify the path with \`\`-f''"
                 exit $UNKNOWN
        fi
fi

if [ $UNAVAILABLE_CHECK -eq 1 ]; then
	for config in $(find $CONFIG_DIR -type f -name "*.conf")
	do
		name=$(basename $CONFIG_DIR/$config)

		CONTINUE=0
		for i in $SKIP
		do
			if [[ "$name" == "$i" ]]; then
				CONTINUE=1
			fi
		done

		if [ $CONTINUE -eq 1 ]; then
			continue
		fi

		if grep -q 'VISIBLE="no"' $config 2>/dev/null
		then
			LIST+=("$name")
			let COUNT++
		fi
	done

	if [ $COUNT -gt 0 ]; then
		echo "Invisible items: ${LIST[@]}"
	fi

	check_values $COUNT
fi

if [ $AVAILABLE_CHECK -eq 1 ]; then
	for config in $(find $CONFIG_DIR -type f -name "*.conf")
	do
		name=$(basename $CONFIG_DIR/$config)
		
		CONTINUE=0
		for i in $SKIP
		do
			if [[ "$name" == "$i" ]]; then
				CONTINUE=1
			fi
		done

		if [ $CONTINUE -eq 1 ]; then
			continue
		fi

		source $config
		docker images $IMAGE | grep -q $IMAGE
		if [ $? -eq 0 ];
		then
			echo "Image is available for $name"
		else
			echo "Error: missing image for $name"
			let MISSING++
		fi
	done

	check_values
fi

if [ $STATUS_CHECK -eq 1 ]; then

	for dir in $CONFIG_DIR $INSTALL_DIR
	do
		if [ ! -d $dir ]
		then
			echo "Error: $dir does not exist or is not accessible!"
			let MISSING++
		fi
	done

	for file in $LIBZK $SHELL $LAUNCH_CONTAINER $DB
	do
		if [ ! -f $file ]
		then
			echo "Error: $file does not exist or is not accessible!"
			let MISSING++
		fi
	done

	if ! getent passwd $USER 1>/dev/null
	then
		echo "Error: $USER doesn't exist!"
		let MISSING++
	fi

	if ! getent passwd $USER | grep -q $SHELL
	then
		echo "Error: ${USER}'s shell is different than declared in ${CONFIG}!"
		let MISSING++
	fi

	check_values
fi
