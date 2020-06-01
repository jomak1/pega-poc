# GIFFD JBOSS DOCKERFILE
# -----------------------------------------
# This Dockerfile creates a JBoss EAP 7 image by creating a sample standalone configuration  to run Pega applications.
# Datasource and JMS resources are automatically configured accordingly to Pega Installation Guide using <TBD>
#
# At runtime the image expose the following mount points as volumes:
#
#	/pega
#		Whitin this path the following directories are expected:
#			/etc
#				Place here the following standard Pega configuration files:
#					prbootstrap.properties
#					prconfig.xml
#					prlogging.xml
#			/tmp
#				This will be used as Pega temporary directory
#			/logs
#				This directory is assigned to the ${pega.log.location} env variable
#			/lib
#				Place here the jdbc driver referenced by the -e DRIVER=ojdbc7.jar flag at runtime
#			/deploy
#		        Place here the archives to be deployed at runtime
##
# Weblogic Console app is reachable at ip_address:7001/console
# Domain admin credentials are: weblogic/Pegasys1+
#
# REQUIRED FILES TO BUILD THIS IMAGE
# -----------------------------------------
# (1) jboss-eap-7.0.x.zip (RedHat JBoss EAP 7.0.x	Application Platform - zip file downloaded from https://developers.redhat.com/products/eap/download/)
#
# HOW TO BUILD THIS IMAGE
# -----------------------------------------
#      $ docker build -t giffd/prpc_jboss:7 .


# Pull base image
# ---------------
# Use latest jboss/base-jdk:8 image as the base
FROM jboss/base-jdk:8

# Maintainer
# ----------
MAINTAINER GIFFD <domenico.giffone@pega.com>


# Environment variables required for this build
# -------------------------------------------------------------
# Set the JBOSS_VERSION env variable
ENV JBOSS_VERSION 7.2.0
ENV JBOSS_HOME /opt/jboss/jboss-eap-7.2/
ENV ADMIN_PASSWORD Pegasys1+
ENV ADMIN_DATASOURCE true
ENV JBOSS_MGMT_NATIVE_PORT 9999
ENV JBOSS_MGMT_HTTP_PORT 9990
ENV JBOSS_HTTP_PORT 8080

COPY media/jboss-eap-$JBOSS_VERSION.zip /opt/jboss

# Add the JBoss distribution to /opt, and make jboss the owner of the extracted zip content
# Make sure the distribution is available from a well-known place
RUN cd $HOME \
    && unzip jboss-eap-$JBOSS_VERSION.zip \
    && rm jboss-eap-$JBOSS_VERSION.zip

# Setup JBoss user
# ------------------------------------------------------------
# create JBoss console user
RUN $JBOSS_HOME/bin/add-user.sh admin $ADMIN_PASSWORD --silent

# Copy patches
RUN mkdir -p $HOME/patches
COPY media/patches/* /opt/jboss/patches/

# Show Java version & other details
RUN java -version
RUN echo $HOME
RUN ls -al /opt/jboss/patches


# Root commands
USER root

# Change the open file limits in /etc/security/limits.conf
RUN sed -i '/.*EOF/d' /etc/security/limits.conf && \
    echo "* soft nofile 16384" >> /etc/security/limits.conf && \
    echo "* hard nofile 16384" >> /etc/security/limits.conf && \
    echo "# EOF"  >> /etc/security/limits.conf

# Change the kernel parameters that need changing.
#RUN echo "net.core.rmem_max=4192608" > /opt/jboss/.sysctl.conf && \
#    echo "net.core.wmem_max=4192608" >> /opt/jboss/.sysctl.conf && \
#    sysctl -e -p /opt/jboss/.sysctl.conf

# Setup Pega requirements
# --------------------------------
RUN mkdir -p /pega/etc && \
	mkdir -p /pega/tmp && \
	mkdir -p /pega/logs && \
	mkdir -p /pega/lib && \
        mkdir -p /pega/deploy && \
    chmod a+xr /pega

# Adjust file permissions
RUN chown jboss: -R /pega
RUN chown jboss: -R /opt/jboss

# Add files required to run this image
COPY standalone.conf.pega $JBOSS_HOME/bin
COPY PegaConfig.cli $JBOSS_HOME/bin
#COPY deployApps.py /u01/app/oracle/
COPY pega/lib/*   /pega/lib/
COPY pega/etc/*  /pega/etc/
COPY pega/deploy/* /pega/deploy/
# Export pega dirs
VOLUME /pega

# Expose JBoss ports
EXPOSE $JBOSS_HTTP_PORT $JBOSS_MGMT_NATIVE_PORT $JBOSS_MGMT_HTTP_PORT

# Define default command to start bash.
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# go to $JBOSS_HOME as user 'jboss'
WORKDIR $JBOSS_HOME
USER jboss
ENTRYPOINT ["/entrypoint.sh"]
# download postgres driver
RUN set -x && mkdir -p /opt/jboss/wildfly/modules/system/layers/base/org/postgresql/main
RUN curl -L https://jdbc.postgresql.org/download/postgresql-42.2.2.jar -o /opt/jboss/wildfly/modules/system/layers/base/org/postgresql/main/postgresql-42.2.2.jar
