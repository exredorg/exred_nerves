/bin/sh

echo "----- BEGIN exred pre init -----"

if [ ! -f /root/data/exred.sqlite3 ]; then
	mkdir -p /root/data
	cp /var/exred_data/exred.sqlite3 /root/data
fi

echo "----- END exred pre init -------"

