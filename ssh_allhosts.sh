#/bin/bash

while read h
do
    now=$(date +'%Y-%m-%d %H:%M:%S')
    ssh $h "echo $now login from $HOSTNAME >> /root/ssh_successed" </dev/null
done < /root/hostlist
