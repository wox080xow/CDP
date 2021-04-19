

## 一、[[#前置作業]]
#### [[#安裝與設定Kerberos Server]]
#### [[#安裝JCE POLICY]]
#### [[#創建Kerberos的database與principal]]
#### [[#啟動KDC Key Distribution Center]]
#### [[#安裝Kerberos Client]]
## 二、[[#CDP啟用Kerberos]]
## 三、[[#注意事項]]

[前置作業](#前置作業)

[安裝JCE POLICY](#安裝JCE\ POLICY)

## 前置作業
#### 安裝與設定Kerberos Server
1. 安裝Kerberos Server
	 - 選定一台主機安裝
	 - Cloudera Manager需要openldap-clients
	```
	yum -y install krb5-server krb5-libs openldap-clients
	```
1. 設定`/etc/krb5.conf`
	 - 以下範例假設安裝Kerberos Server的主機FQDN為`cfori-m1.us-central1-a.c.eternal-ruler-310501.internal`
	 - Kerberos的realm一定要是大寫的，如`US-CENTRAL1-A.C.ETERNAL-RULER-310501.INTERNAL`
	 - 每行前面有無空白只是排版美觀，不會影響設定
	```
	[libdefaults]
	default_realm = US-CENTRAL1-A.C.ETERNAL-RULER-310501.INTERNAL
	dns_lookup_kdc = false
	dns_lookup_realm = false
	ticket_lifetime = 86400
	renew_lifetime = 604800
	forwardable = true
	default_tgs_enctypes = aes256-cts-hmac-sha1-96
	default_tkt_enctypes = aes256-cts-hmac-sha1-96
	permitted_enctypes = aes256-cts-hmac-sha1-96
	udp_preference_limit = 1
	kdc_timeout = 3000

	[realms]
	US-CENTRAL1-A.C.ETERNAL-RULER-310501.INTERNAL = {
	kdc = cfori-m1.us-central1-a.c.eternal-ruler-310501.internal
	admin_server = cfori-m1.us-central1-a.c.eternal-ruler-310501.internal
	}

	[domain_realm]
	.us-central1-a.c.eternal-ruler-310501.internal = US-CENTRAL1-A.C.ETERNAL-RULER-310501.INTERNAL
	us-central1-a.c.eternal-ruler-310501.internal = US-CENTRAL1-A.C.ETERNAL-RULER-310501.INTERNAL

	[logging]
	kdc = FILE:/var/log/krb5kdc.log
	admin_server = FILE:/var/log/kadmin.log
	default = FILE:/var/log/krb5lib.log
	```
1. 設定`/var/kerberos/krb5kdc/kdc.conf`
	```
	default_realm = US-CENTRAL1-A.C.ETERNAL-RULER-310501.INTERNA

	[kdcdefaults]
	v4_mode = nopreauth
	kdc_ports = 0

	[realms]
	 US-CENTRAL1-A.C.ETERNAL-RULER-310501.INTERNAL = {
	  kdc_ports = 88
	  admin_keytab = /etc/kadm5.keytab
	  master_key_type = aes256-cts
	  database_name = /var/kerberos/krb5kdc/principal
	  acl_file = /var/kerberos/krb5kdc/kadm5.acl
	  max_life = 10h 0m 0s
	  max_renewable_life = 7d 0h 0m 0s
	  supported_enctypes = arcfour-hmac:normal des3-hmac-sha1:normal des-cbc-crc:normal des:normal des:v4 des:norealm des:onlyrealm des:afs3
	  default_principal_flags = +preauth
	 }
	 ```

1. 設定`/var/kerberos/krb5kdc/kadm5.acl`
	```
	*/admin@CW.COM	    *
	```

#### 安裝JCE POLICY
CDP要求Kerberos要使用aes256加密，這的加密法需要另外下載
1. 下載jce_policy-8.zip
	 - 需要登入ORACLE手動下載解壓縮，在傳到安裝Kerberos的主機
	 	https://www.oracle.com/webapps/redirect/signon?nexturl=https://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip
	 - 注意！使用CLI可以下載，但是檔案不完整無法解壓縮...
1. 把`jar`檔放到正確位置
	```
	mkdir $JAVA_HOME/lib/security
	cp local_policy.jar US_export_policy.jar $JAVA_HOME/lib/security
	```

#### 創建Kerberos的database與principal
1. 建立database
	```
	kdb5_util create -s
	```
1. 建立principal
	進入本地的kadmin shell
	```
	kadmin.local
	```
	建立Kerberos的管理員principal
	```
	kadmin.local:  addprinc root/admin
	```
	建立Cloudera Manager的principal
	- 密碼設定為cloudera-scm
	- @後面是Kerberos的realm
	```
	kadmin.local:  -pw cloudera-scm cloudera-scm/admin@US-CENTRAL1-A.C.ETERNAL-RULER-310501.INTERNAL
	```
	離開kadmin shell
	```
	kadmin.local:  exit
	```
#### 啟動KDC(Key Distribution Center)
接下來可以啟動KDC了！
```
systemctl start krb5kdc.service
systemctl start kadmin.service
systemctl enable krb5kdc.service
systemctl enable kadmin.service
```

#### 安裝Kerberos Client
1. 安裝Kerberos Client
	 - 叢集裡所有主機都要安裝
	```
	while read h;do ssh $h "hostname;yum -y install krb5-workstation krb5-libs" </dev/null;done < hostlist
	```
1. 上傳設定檔`/etc/krb5.conf`
	 - 叢集裡所有主集都要有Kerberos這台主機的`etc/krb5.conf`
	```
	while read h;do scp /etc/krb5.comf $h:/etc/krb5.conf;done < hostlist
	```



## CDP啟用Kerberos
#### 啟用Kerberos
 - 在建立CDP前
	建立時可以看到啟用Kerberos的提示
	![[Screen Shot 2021-04-19 at 11.47.40.png]]
	使用Wizard啟用Kerberos
	1. Getting Started
		選擇MIT KDC
	1. Enter KDC Information
	1. Manage krb5.conf
	1. Enter Account Credentials
		
	1. Command Details
 - 建立好CDP後
	進入建立好的叢集（Cluster）頁面
	1. 三的點點
	2. Enable Kerberos
	![[Screen Shot 2021-04-19 at 12.20.06.png]]
	
## 注意事項


