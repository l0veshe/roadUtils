#!/bin/bash
#==========================================
# Program : rsync_centos_source.sh
# Info : 定期同步官方 CentOS 源到本机
# Author: zhouchenhan@icloud.com
# Version : 2014.07.14 First Release
#==========================================

Date=`date +%Y%m%d`
LogFile=`dirname $0`"/sync_repo_source.log"
RsyncBin="/usr/bin/rsync"
RsyncPerm="-avrt --delete --exclude=4/ --exclude=4AS/ --exclude=4ES/ --exclude=4WS/ --exclude=6/ --exclude=testing/  --bwlimit=125"
Url="mirrors.ustc.edu.cn"

#============ CentOS 6.x =============
function RSYNC_CENT6
{
    RSY_NAME="CentOS 6.6"
    CentOS_6_5_Site="rsync://$Url/centos/6.6/os/x86_64/"
    CentOS_6_5_Site_Update="rsync://$Url/centos/6.6/updates/x86_64/"
    CentOS_6_5_LocalPath="/data/var/www/html/iso/CentOS/6.6/os/x86_64/"
    CentOS_6_5_LocalPath_Update="/data/var/www/html/iso/CentOS/6.6/updates/x86_64/"
    echo "---- $RSY_NAME RSYNC $Date `date +%T` Begin ----" >>$LogFile
    $RsyncBin $RsyncPerm  $CentOS_6_5_Site $CentOS_6_5_LocalPath 2>&1 >> $LogFile
    $RsyncBin $RsyncPerm  $CentOS_6_5_Site_Update $CentOS_6_5_LocalPath_Update 2>&1 >> $LogFile
    echo "---- $RSY_NAME RSYNC $Date `date +%T` End ----" >> $LogFile
}
#---------EXEC SYNC-----------------#

RSYNC_CENT6