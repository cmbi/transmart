FROM ubuntu:16.04

# Install dependencies
RUN apt-get update && apt-get install -y curl zip unzip sudo default-jre postgresql libbz2-dev liblzma-dev libpcre2-dev libcurl4-gnutls-dev wget g++ gfortran zlib1g-dev libpcre++-dev make ant maven tomcat7

# Add a sudo user for transmart
RUN adduser transmart && adduser transmart sudo

# Set up install script
ARG TRANSMART_VERSION=16.3
RUN mkdir /deps
WORKDIR /deps
RUN curl http://library.transmartfoundation.org/release/release16_3_0_artifacts/Scripts-release-${TRANSMART_VERSION}.zip -o /deps/Scripts-release-${TRANSMART_VERSION}.zip
RUN unzip /deps/Scripts-release-${TRANSMART_VERSION}.zip && mv /deps/Scripts-release-${TRANSMART_VERSION} /root/Scripts

# Download transmart-data
RUN mkdir -p /root/transmart
WORKDIR /root/transmart
RUN curl http://library.transmartfoundation.org/release/release16_3_0_artifacts/transmart-data-release-${TRANSMART_VERSION}.zip -o transmart-data-release-${TRANSMART_VERSION}.zip
RUN unzip transmart-data-release-${TRANSMART_VERSION}.zip && mv transmart-data-release-${TRANSMART_VERSION} transmart-data

# Download transmart-ETL
RUN mkdir -p /root/transmart/transmart-data/env
WORKDIR /root/transmart/transmart-data/env
RUN curl http://library.transmartfoundation.org/release/release16_3_0_artifacts/tranSMART-ETL-release-${TRANSMART_VERSION}.zip -o tranSMART-ETL-release-${TRANSMART_VERSION}.zip
RUN unzip tranSMART-ETL-release-${TRANSMART_VERSION}.zip && mv tranSMART-ETL-release-${TRANSMART_VERSION} transmart-ETL

# Install the latest version of R
RUN wget https://lib.ugent.be/CRAN/src/base/R-3/R-3.6.3.tar.gz && tar xzf R-3.6.3.tar.gz && cd R-3.6.3 && ./configure --with-readline=no --with-x=no --enable-R-shlib && make && make install
RUN mkdir -p /root/transmart/transmart-data/R/root/bin && ln -s /usr/local/bin/R /root/transmart/transmart-data/R/root/bin/R && ln -s /usr/local/bin/Rscript /root/transmart/transmart-data/R/root/bin/Rscript
ADD other_pkg.R /root/transmart/transmart-data/R/other_pkg.R

# Run the install script
ENV JAVA_HOME=/usr/
WORKDIR /root/transmart/transmart-data
RUN make -C env install_ubuntu_packages16 install_ubuntu_packages
RUN make -C env /var/lib/postgresql/tablespaces
RUN make -C env update_etl_git
RUN make -C env data-integration
RUN make -C env ../vars

SHELL ["/bin/bash", "-c"] 
WORKDIR /root
RUN curl https://get.sdkman.io | bash
RUN echo "Y" > AnswerYes.txt
RUN source /root/.sdkman/bin/sdkman-init.sh && sdk install grails 2.3.11 < AnswerYes.txt && sdk install groovy 2.4.5 < AnswerYes.txt

WORKDIR /root/transmart/transmart-data
RUN source vars && chmod 700 $TABLESPACES/*

WORKDIR /root/
RUN /root/Scripts/install-ubuntu16/updateTomcatConfig.sh

WORKDIR /root/transmart/transmart-data
RUN source vars && make -C R install_packages
RUN echo "export PATH=/usr/local/bin:\$PATH" > /etc/profile.d/Rpath.sh

WORKDIR /root/transmart/transmart-data
RUN echo "install.packages(\"Rserve\",,\"http://rforge.net\")" | R --vanilla

WORKDIR /root/transmart/transmart-data
RUN locale-gen en_US.UTF-8
RUN adduser postgres root && chmod -R g+rwx /root
RUN source vars && service postgresql start && su postgres -c "make -j4 postgres"

WORKDIR /root/transmart/transmart-data
RUN source vars && make -C config install
RUN mkdir -p /usr/share/tomcat7/.grails/transmartConfig/
RUN cp /root/.grails/transmartConfig/*.groovy /usr/share/tomcat7/.grails/transmartConfig/
RUN chown -R tomcat7:tomcat7 /usr/share/tomcat7/.grails

WORKDIR /root/transmart
RUN mkdir war-files
WORKDIR /root/transmart/war-files
RUN curl http://library.transmartfoundation.org/release/release16_2_0_artifacts/transmart.war --output transmart.war
RUN curl http://library.transmartfoundation.org/release/release16_2_0_artifacts/gwava.war --output gwava.war
RUN cp *.war /var/lib/tomcat7/webapps/

WORKDIR /root/transmart/transmart-data
RUN (source vars ; make -C solr start) & sleep 2m && source vars && make -C solr rwg_full_import sample_full_import

WORKDIR /root/transmart/transmart-data
RUN /root/Scripts/install-ubuntu16/updateTomcatConfig.sh
RUN source vars && TABLESPACES=$TABLESPACES TRANSMART_USER="tomcat7" make -C R install_rserve_init

WORKDIR /root/
ADD run.sh /root/run.sh
RUN chmod +x run.sh
EXPOSE 8080
CMD ["./run.sh"]
