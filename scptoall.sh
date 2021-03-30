while read h
do
  ssh $h hostname </dev/null
  scp $1 $h:$1 </dev/null
done <hostlist
