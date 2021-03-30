#/bin/bash

while read h
do
    ping -c 4 $h | grep -A 1 'ping statistics'
done < hostlist

while read i
do
    ping -c 4 $i | grep -A 1 'ping statistics'
done < iplist
