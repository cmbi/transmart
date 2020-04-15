#!/bin/bash
source /root/transmart/transmart-data/vars

export CATALINA_HOME=/usr/share/tomcat7
export CATALINA_BASE=/var/lib/tomcat7

nohup make -C /root/transmart/transmart-data/solr start > ~/transmart/transmart-data/solr.log 2>&1 &
/usr/local/bin/R CMD Rserve --vanilla
service postgresql start
/usr/share/tomcat7/bin/catalina.sh run
