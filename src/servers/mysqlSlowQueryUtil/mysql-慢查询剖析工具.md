title: mysql 慢查询剖析工具 shell
date: 2014-09-14 19:47:24
tags: [mysql,慢查询,scritp,shell,linux]
categories: MYSQL
---
----
```bash
#单条剖析
mysql> SET profiling = 1;
mysql> SELETCT ...慢查询语句
mysql> SHOW PROFILES; 得到序号
mysql> SHOW PROFILE FOR QUERY 1;

#mysql出现问题，首先使用,开销很低.mysql  -uroot -p -e ''
SHOW STATUS
SHOW PROCESSLIST
SHOW INNODB STATUS

#每秒查询数，正在执行查询的线程数、正在运行的线程数
mysqladmin ext -uroot -p -i1 |awk  '/Queries/{q=$4-qp;qp=$4}/Threads_connected/{tc=$4}/Threads_running/{printf "%5d %5d %5d\n", q, tc, $4}'

#查询正在工作的线程状态并排序
mysql  -uroot -p -e 'SHOW PROCESSLIST\G'|grep State:|sort|uniq -c|sort -rn

#计算slow_log出现及排序
awk '/^# Time:/{print $3, $4, c;c=0}/^# User/{c++}' slow-query.log

#mysql打开临时文件汇总
awk '/mysql.*tmp/{total+=$7;}/^Sun Mar 28/ && total{print "%s %7.2f MB\n", $4, total/1024/1034;total=0;}' lsof.txt

#查看系统调用情况
strace -cfp $(pidof mysqld)
```

