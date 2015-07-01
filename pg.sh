#!/bin/bash
source $1

fast=0
[ "${2}" = "--fast" ] && fast=1
[ "${3}" = "--fast" ] && fast=1
[ "${4}" = "--fast" ] && fast=1

log=0
[ "${2}" = "--log" ] && log=1 
[ "${3}" = "--log" ] && log=1
[ "${4}" = "--log" ] && log=1


port_num=`snmpget ${SNMP_AUTH} -OQ ${SNMP_IP} .1.3.6.1.2.1.2.1.0 | awk -F '=' '{ print $2 }' | xargs`

oid=".1.3.6.1.2.1.2.2.1.16"

fetch_fast(){
	local res=""
	local start=""
	local end=""
	start=`date +%s%N`
	res=$(snmpbulkget ${SNMP_AUTH} -OQ -Cr${2} ${SNMP_IP} ${1} | awk -F '= ' '{ print $2 }')
	end=`date +%s%N`
	for i in $res; do
		echo $start $end $i
	done
}
fetch_compat(){
	local ret=""
	local oid="${1}"
	local start=""
	local end=""
	for i in `seq -s ' ' 1 ${2}` ; do 
		start=`date +%s%N`
		ret=`snmpgetnext ${SNMP_AUTH} -OQ ${SNMP_IP} ${oid}`
		end=`date +%s%N`
		echo ${start} ${end} `echo ${ret} | awk -F '=' '{ print $2 }'`
		oid=`echo $ret | awk -F '=' '{ print $1 }' | xargs`
	done
}

[ "${fast}" -eq 1 ] && res=`fetch_fast .1.3.6.1.2.1.2.2.1.16 $port_num` \
	|| res=`fetch_compat .1.3.6.1.2.1.2.2.1.16 $port_num`
# echo "${res}"
sleep 1
[ "${fast}" -eq 1 ] && resb=`fetch_fast .1.3.6.1.2.1.2.2.1.16 $port_num` \
	|| resb=`fetch_compat .1.3.6.1.2.1.2.2.1.16 $port_num`

[ "${log}" -eq 1 ]  && \
	as='{ 
	tdiff=(($4-$1)+($5-$2))/2 * 10^-9;
#	print $1, $2 ": " $3 " ; " $4, $5 ": " $6,  "->", tdiff, $6-$3, ($6-$3)/tdiff
	print log((($6-$3)/tdiff)*8)/log(10)
}' || as='{
	tdiff=(($4-$1)+($5-$2))/2 * 10^-9;
	print (($6-$3)/tdiff)*8
}'

paste -d' ' <(echo "${res}") <(echo "${resb}") |  awk "${as}"
