#!/bin/bash
#*************************************************************************
#  Author       :               wangwei
#  CreateDate   :               2020-09-27
#  Description  :               this script using the Transportable Tablespaces
#                               archive move data 
#
#*************************************************************************
#!/bin/bash

Usage() {
cat << EOF
tran_tab
OPTIONS:
   -t      table name
   -d    destination instance db
   -s    source instance db
For secrity: This scripts check the full need arguments
EOF
}
while getopts ":t:d:s:" opt; do
  case $opt in
    t)
      stab_name=${OPTARG}
      ;;
    d)
      ddbname=${OPTARG}
      ;;
    s)
      sdbname=${OPTARG}
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      Usage
      exit 1
      ;;
  esac
done
if [ $# != 6 ] ; then
    Usage
    exit 1;
fi

echo $stab_name >> 1.txt
echo $ddbname >> 1.txt
echo $sdbname >> 1.txt
 
#获取表的创建脚本

shost=172.xx.xx.xx
sport=3306
suser=root
spassword=xxx@123edc
sdatadir=/data/mysql/mysql3306/data/
smysql_path=/usr/local/mysql/bin/mysql

#ddbname=guiyu_dispatch
dhost=17.xx.xx.xx
dport=3306
duser=root
dpassword=xxx@123edc
ddatadir=/data/mysql/mysql3306/data/
dmysql_path=/usr/local/mysql/bin/mysql

host='172.xx.xx.xx'
sshport='18044'
hostuser='root'
hostpassword='xx123@'



#获取表的创建脚本
$smysql_path -h$shost -P$sport -u$suser -p$spassword --skip-column-names $sdbname -e "show create table $stab_name \G" >./.$stab_name.sql
sed -i '1,2d' ./.$stab_name.sql
sed -i '$a ;' ./.$stab_name.sql
#在目标实例上创建表
strsql=`cat ./.$stab_name.sql`
echo $strsql
$dmysql_path -h$dhost -P$dport -u$duser -p$dpassword $ddbname -e "$strsql"

#On the destination instance, discard the tablespace
$dmysql_path -h$dhost -P$dport -u$duser -p$dpassword $ddbname -e "ALTER TABLE $stab_name DISCARD TABLESPACE;"

#On the source instance, run FLUSH TABLES ... FOR EXPORT 
$smysql_path -h$shost -P$sport -u$suser -p$spassword $sdbname -e "FLUSH TABLES $stab_name FOR EXPORT;select sleep(30)" &

#Copy the .ibd file and .cfg metadata file from the source instance to the destination instance
sshpass -p $hostpassword scp -P$sshport -o StrictHostKeyChecking=no $sdatadir/$sdbname/$stab_name.{cfg,ibd} $hostuser@$host:$ddatadir/$ddbname/

#修改文件权限
sshpass -p $hostpassword ssh -p$sshport $hostuser@$host "chown mysql:mysql -R $ddatadir/$ddbname/$stab_name.{ibd,cfg}"

#On the source instance, use UNLOCK TABLES to release the locks
$smysql_path -h$shost -P$sport -u$suser -p$spassword $sdbname -e "UNLOCK TABLES;"

#On the destination instance, import the tablespace:
$dmysql_path -h$dhost -P$dport -u$duser -p$dpassword $ddbname -e "ALTER TABLE $stab_name IMPORT TABLESPACE;"
