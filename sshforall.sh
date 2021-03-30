while read h
do
  echo $h
  #echo $1
  ssh $h $1 </dev/null
done <hostlist
