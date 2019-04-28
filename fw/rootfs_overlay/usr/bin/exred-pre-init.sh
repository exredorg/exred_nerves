#!/bin/sh

# this is not working, /root is read only at this pre-init stage !!!

echo "----- BEGIN exred pre init -----"

#if [ ! -f /root/data/exred.sqlite3 ]; then
#	echo "setting up default database"
#	mkdir -p /root/data
#	cp /var/exred_data/exred.sqlite3 /root/data
#fi

echo "----- END exred pre init -------"

/usr/bin/redis-server &

exit 0

