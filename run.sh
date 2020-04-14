#!/bin/bash

export CATALINA_HOME=/usr/share/tomcat7
export CATALINA_BASE=/var/lib/tomcat7

/usr/local/bin/R CMD Rserve --vanilla
service postgresql start
/usr/share/tomcat7/bin/catalina.sh run
