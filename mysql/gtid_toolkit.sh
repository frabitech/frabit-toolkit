#! /bin/bash
#---------------------------------------------------- Head info -------------------------------------------
# author          : zhangl (blylei@163.com)
# create datetime : 2021-12-28
# funcation       : fix MySQL【Oracle's or Percona】 gtid issue
# script name     : gtid_toolkit.sh
#-----------------------------------------------------------------------------------------------------------
#-------------------------------------------------- Modified logs ------------------------------------------
# Version      People   Date             Notes
# V1.0.0       zhangl   2021-12-28      create this script
#-----------------------------------------------------------------------------------------------------------

DESCRIPTION="Exit 0 if node1 can auto-position on node2."

set -eu

db_user=''
db_passwd=''
db_port=3306



## inject-empty
## reset-master
## desc-topo

usage() {
  echo "usage: $0 [options] node1 node2"
  echo "      ${DESCRIPTION}"                                           1>&2
  echo "      -a      Enable auto-pos if node1 can auto-post on node2 " 1>&2
  echo "      -h      Print this help"                                  1>&2
  exit $1
}

ENABLE_AUTO_POS=""

conn_init(){
  # 根据数据库IP地址，创建连接
  local host="$1"
  mysql -u "$db_user"

}

while getopts "a" opt; do
  case "$opt" in
    a) ENABLE_AUTO_POS="yes"
       shift
       ;;
    h) usage 0 ;;
    *) usage 1 ;;
  esac
done

node1="$1"
node2="$2"

gtid_purged=$(mysql -h $node2 -sse "SELECT @@global.gtid_purged")
gtid_missing=$(mysql -h $node1 -sse "SELECT GTID_SUBTRACT('$gtid_purged', @@global.gtid_executed)")

if [[ "$gtid_missing" ]]; then
  echo "$node1 cannot auto-position on $node2, missing GTID sets $gtid_missing" >&2
  exit 1
fi

if [[ $ENABLE_AUTO_POS ]]; then
  echo "OK, $node1 can auto-position on $node2, enabling..."
  mysql -h $node1 -e "STOP SLAVE; CHANGE MASTER TO MASTER_AUTO_POSITION=1; START SLAVE;"
  sleep 1
  mysql -h $node1 -e "SHOW SLAVE STATUS\G"
  echo "Auto-position enabled on $node1. Verify replica is running in output above."
else
  echo "OK, $node1 can auto-position on $node2. Use option -a to enable, or execute:"
  echo "    mysql -h $node1 -e \"STOP SLAVE; CHANGE MASTER TO MASTER_AUTO_POSITION=1; START SLAVE;\""
  echo "    mysql -h $node1 -e \"SHOW SLAVE STATUS\G\""
fi