title: MySQL MMM 部署配置
date: 2014-09-14 19:32:13
tags: [mysql,centos,mmm,mysql数据库]
categories: MYSQL
---
----

###MMM简介

    MMM即Master-Master Replication Manager for MySQL（mysql主主复制管理器）关于mysql主主复制配置的监控、故障转移和管理的一套可伸缩的脚本套件（在任何时候只有一个节点可以被写入），这个套件也能对居于标准的主从配置的任意数量的从服务器进行读负载均衡，所以你可以用它来在一组居于复制的服务器启动虚拟ip，除此之外，它还有实现数据备份、节点之间重新同步功能的脚本。
    MySQL本身没有提供replication failover的解决方案，通过MMM方案能实现服务器的故障转移，从而实现mysql的高可用。
    MMM项目来自 Google：http://code.google.com/p/mysql-master-master
    官方网站为：http://mysql-mmm.org
    Mmm主要功能由下面三个脚本提供

    1. mmm_mond 负责所有的监控工作的监控守护进程，决定节点的移除等等
    2. mmm_agentd 运行在mysql服务器上的代理守护进程，通过简单远程服务集提供给监控节点
    3. mmm_control 通过命令行管理mmm_mond进程

###一、实验准备

系统: CentOS6.5
---------------------------------------
functiont |	ip | hostname
monitoring_host	| 192.168.174.136 |	monitor
master1	| 192.168.174.134 |	db1
master2	| 192.168.174.135 | db2
--------------------------------------

### 二、搭建MM,双MYSQL互为主从模式Replication

1. db1 db2安装mysql数据库并修改配置文件

```bash
# yum install mysql mysql-server -y
# vim /etc/my.cn
```

db1配置文件如下

```bash
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
log-error=/var/lib/mysql/mysql.err
log = /var/lib/mysql/query_log.log
log-slow-queries = /var/lib/mysql/slow_query_log.log
user=mysql
default-character-set=utf8
init_connect='SET NAMES utf8'
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
log-bin=mysql-bin     #开启binlog日志用于主从数据复制
server-id=1
binlog-do-db=iccstm1   #你要用于主从复制的数据库名称，多个用逗号隔开
binlog-ignore-db=mysql  #数据库名称
replicate-do-db=iccstm1
replicate-ignore-db=mysql
log-slave-updates  #此数据库宕机，备用数据库接管
slave-skip-errors=all   #跳过错误，继续执行复制
sync_binlog=1
auto_increment_increment=2
auto_increment_offset=1 #這樣A的auto_increment字段産生的數值是：1, 3, 5, 7, …等奇數ID
[client]
default-character-set=utf8
[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
```

db2配置文件如下(基本一致，server-id=2 这个不可同db1一致)

```bash
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
log-error=/var/lib/mysql/mysql.err
log = /var/lib/mysql/query_log.log
log-slow-queries = /var/lib/mysql/slow_query_log.log
user=mysql
default-character-set=utf8
init_connect='SET NAMES utf8'
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
log-bin=mysql-bin     #开启binlog日志用于主从数据复制
server-id=2
binlog-do-db=iccstm1   #你要用于主从复制的数据库名称，多个用逗号隔开
binlog-ignore-db=mysql  #数据库名称
replicate-do-db=iccstm1
replicate-ignore-db=mysql
log-slave-updates  #此数据库宕机，备用数据库接管
slave-skip-errors=all   #跳过错误，继续执行复制
sync_binlog=1
auto_increment_increment=2
auto_increment_offset=1 #這樣A的auto_increment字段産生的數值是：1, 3, 5, 7, …等奇數ID
[client]
default-character-set=utf8
[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
```

2.在MYSQL内部启用同步

取得master值


db1:

```bash
mysql> show master status\G
*************************** 1. row ***************************
            File: mysql-bin.000005
        Position: 526
    Binlog_Do_DB: iccstm1
Binlog_Ignore_DB: mysql
1 row in set (0.00 sec)
db2:
mysql> show master status\G
*************************** 1. row ***************************
            File: mysql-bin.000005
        Position: 526
    Binlog_Do_DB: iccstm1
Binlog_Ignore_DB: mysql
1 row in set (0.00 sec)
master_log_file对应File，master_log_pos对应Position
```

db1 db2互相提升访问权限

```bash
Mysql> grant all privileges on *.* to 'root'@'%' identified by '1' with grant option;
```

db2:

```bash
mysql> grant replication slave on *.* to 'replication'@'%' identified by '1';
mysql> flush privileges;
```

db1:

```bash
mysql> change master to master_host='192.168.174.135', master_user='replication', master_password='1',master_log_file='mysql-bin.000005',master_log_pos=526;
mysql> grant replication slave on *.* to 'replication'@'%' identified by '1';
mysql> flush privileges;
```

```bash
mysql> change master to master_host='192.168.174.134', master_user='replication', master_password='1',master_log_file='mysql-bin.000005',master_log_pos=526;
```

db1,db2分别查看服务器主从状态:

```bash
mysql>start slave;
mysql>show slave status\G
```
如果有以下两个结果

```bash
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
```

主从成功。

可以建立

```bash
mysql> create database iccstm1;
mysql> use iccstm1;
mysql> create table testTab(NAME set char(2));
```

在另外一台主机查看。

### 三、安装配置MySQL-MMM

1.在monitor、db1、db2上安装mmm，并配置：mmm_common.conf、mmm_agent.conf以及mmm_mon.conf文件
首先安装epel源
适合各个操作系统的epel源列表:http://mirrors.fedoraproject.org/publiclist/EPEL/

```bash
wget http://mirrors.yun-idc.com/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -Uvh epel-release-6-8.noarch.rpm
yum -y install mysql-mmm*
```

配置mmm代理和监控账号的权限

在db1和db2上分别执行：

```bash
mysql> GRANT REPLICATION CLIENT ON *.* TO 'mmm_monitor'@'192.168.174.%' IDENTIFIED BY '1';
mysql> GRANT SUPER, REPLICATION CLIENT, PROCESS ON *.* TO 'mmm_agent'@'192.168.174.%'   IDENTIFIED BY '1';
mysql> flush privileges;
```

配置mysql-mmm

所有的配置选项都集合在了一个叫/etc/mysql-mmm/mmm_common.conf的单独文件中，系统中所有主机的该文件内容都是一样的, 配置完后不要忘记了拷贝这个文件到所有的主机（包括监控主机）！，内容如下：

```bash
active_master_role      writer
 
<host default>
    cluster_interface       eth0
    pid_path                /var/run/mysql-mmm/mmm_agentd.pid
bin_path                /usr/libexec/mysql-mmm/
#同步的帐号（这些要和前面设置的保持一致！）
    replication_user        replication  
    replication_password    123456    #同步的密码
    agent_user              mmm_agent   #mmm-agent用户名
    agent_password          1    #mmm-agent用户密码
</host>
 
<host db1>
    ip      192.168.172.134     #db1的ip
    mode    master
    peer    db2
</host>
 
<host db2>
    ip      192.168.172.135      #db2的ip
    mode    master
    peer    db1
</host>
 
<role writer>
    hosts   db1, db2
    ips     192.168.172.152      #设置写如的虚拟IP
    mode    exclusive
</role>
 
<role reader>
    hosts   db1, db2
    ips     192.168.1.153, 192.168.1.154     #设置读取的虚拟IP
    mode    balanced
</role>
```

在数据库主机上我们需要编辑/etc/mysql-mmm/mmm_agent.conf文件，根据其他主机的不同更改db1的值（db2就将db1更改成db2）：

```bash
include mmm_common.conf
```

this db1
在监控主机上我们需要编辑/etc/mysql-mmm/mmm_mon.conf文件：

```bash
include mmm_common.conf
 
<monitor>
    ip                  127.0.0.1
    pid_path            /var/run/mysql-mmm/mmm_mond.pid
    bin_path            /usr/libexec/mysql-mmm
    status_path         /var/lib/mysql-mmm/mmm_mond.status
    ping_ips            192.168.1.134,192.168.1.135  #监控服务器ip
    auto_set_online     60
 
    # The kill_host_bin does not exist by default, though the monitor will
    # throw a warning about it missing.  See the section 5.10 "Kill Host
    # Functionality" in the PDF documentation.
    #
    # kill_host_bin     /usr/libexec/mysql-mmm/monitor/kill_host
    #
</monitor>
 
<host default>
    monitor_user        mmm_monitor    #mmm_monitor用户名
    monitor_password    1 #mmm_monitor密码
</host>
debug 0
```

启动MMM

启动代理：

（在数据库服务器上db1、db2）编辑/etc/default/mysql-mmm-agent来开启：

`ENABLED=1`
然后启动它：


`/etc/init.d/mysql-mmm-agent start`
启动监控（在监控机上）：


`/etc/init.d/mysql-mmm-monitor start`
利用mmm_control监控mysql服务器状态：

```bash
[root@136 ~]# mmm_control show
  db1(192.168.174.134) master/ONLINE. Roles: reader(192.168.174.153)
  db2(192.168.174.135) master/ONLINE. Roles: reader(192.168.174.154), writer(192.168.174.152)
  ```

测试看两个mysql服务器能否实现故障自动切换

停掉作为写的db1上的mysql，查看写的服务器会不会自动转移到db2上去

mmm_control命令简介

```bash
[root@server3 mysql-mmm]# mmm_control help
Valid commands are:
    help                              - show this message
   #查看帮助信息
ping                              - ping monitor
#ping监控
show                              - show status
#查看状态信息
checks [<host>|all [<check>|all]] - show checks status
#显示检查状态，包括（ping、mysql、rep_threads、rep_backlog）
set_online <host>                 - set host <host> online
#设置某host为online状态
set_offline <host>                - set host <host> offline
#设置某host为offline状态
mode                              - print current mode.
#打印当前的模式，是ACTIVE、MANUAL、PASSIVE？
#默认ACTIVE模式
set_active                        - switch into active mode.
#更改为active模式
set_manual                        - switch into manual mode.
#更改为manual模式
set_passive                       - switch into passive mode.
#更改为passive模式
    move_role [--force] <role> <host> - move exclusive role <role> to host <host>
       #更改host的模式，比如更改处于slave的mysql数据库角色为write  
   (Only use --force if you know what you are doing!)
set_ip <ip> <host>                - set role with ip <ip> to host <host>
#为host设置ip，只有passive模式的时候才允许更改！
```
