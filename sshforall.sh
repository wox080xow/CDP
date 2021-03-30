while read h
do
  #echo $h
  #echo $1
  ssh $h "hostname;$1" </dev/null
done <hostlist
