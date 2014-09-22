#!/usr/bin/env bash
# Kill containers which grow to 1GB our more
CONTAINERS=$(docker ps -s | awk 'BEGIN { FS="[ ]{3,}" } $7 ~ / [GT]B/ { print $1 }')

if [ ! -z "$CONTAINERS" ]
then
        for ID in $CONTAINERS
        do
                echo 'echo "Warning: Max. disk space reached. Destroying container..."' | docker attach $ID
                docker stop $ID
                logger -t "docker" "disk_limit.sh: Container $ID was greater than 1GB. Stopped"
        done
fi
