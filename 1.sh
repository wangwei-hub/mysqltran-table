#!/bin/bash
#*************************************************************************
#  Author       :               wangwei
#  CreateDate   :               2020-10-16
#  Description  :               this script export table data 
#*************************************************************************
#!/bin/bash
Usage() {
cat << EOF
tran_tab
OPTIONS:
   -t    table name
   -d    destination instance db
For secrity: This scripts check the full need arguments
EOF
}
while getopts ":t:d:" opt; do
  case $opt in
    t)
      stab_name=${OPTARG}
      ;;
    d)
      ddbname=${OPTARG}
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
if [ $# != 4 ] ; then
    Usage
    exit 1;
fi

echo $stab_name
echo $ddbname

 
#获取表的创建脚本
