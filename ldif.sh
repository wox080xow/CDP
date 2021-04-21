#!/bin/bash


ls /etc/openldap/schema/*.ldif > lsldif
while read l
do
  #echo $l
  ldapadd -Y EXTERNAL -H ldapi:/// -f $l
done < lsldif
rm -f lsldif
echo "import LDAP schema"
