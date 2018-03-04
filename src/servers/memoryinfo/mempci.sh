#!/bin/bash
#适用于linux
#chenhanhank@icloud.com  @limei
#检查内存插槽数等信息


echo "内存插槽数量:" `dmidecode |grep -A16 "Memory Device$"|grep "Array Handle"|wc -l`
echo "支持容量总额:" `dmidecode |grep -P 'Maximum\s+Capacity'`
echo "已有内存容量:" `dmidecode | grep -P -A5 "Memory\s+Device" | grep Size | grep -v Range|head -n 1|awk '{print $2 $3}'`
echo "已有内存主频:" `dmidecode |grep -A16 "Memory Device"|grep 'Speed' |head -n 1|awk '{print $2 $3}'`
echo "已插内存条数:" `dmidecode | grep -P -A5 "Memory\s+Device" | grep Size | grep -v Range  |grep -v "No Module Installed"|wc -l`
