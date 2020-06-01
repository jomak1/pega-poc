JBOSS EAP 7 PEGA DOCKER IMAGE
=================================

This Docker image creates a JBoss EAP 7.0.x standalone instance preconfigured to run Pega applications running on an Oracle database.  

Application server configuration is applied when container is booted for the fist time by the docker entrypoint script provided: `entripoint.sh`.  

The entrypoint invokes the jBoss-cli script `PegaConfig.cli` to configure the standalone instance accordingly to Pega Installation Guide by using the datasources defined in the properties file: `pega/etc/datasources.properties`.  
Pega archives placed in the /pega/deploy directory are automatically deployed.  

Please note that this image is emant to work only with Oracle databases, as such the oracle jdbc driver for java 8 `ojdbc8.jar` is placed in the `pega/lib` directory


### Build Prerequisites

Download the following prerequisites and copy them in the directory specified below.

 - RedHat JBoss EAP 7.0.x	Application Platform:   
  [jboss-eap-7.0.x.zip](https://developers.redhat.com/download-manager/file/jboss-eap-7.0.0.zip)
 downloaded from [RedHat JBoss EAP Page](https://developers.redhat.com/products/eap/download/)  
   _This file must be placed in the `media` directory_  

 - RedHat JBoss EAP 7 patches:  
   Cumulative patches for a ZIP or Installer installation of JBoss EAP are available to download from the [Red Hat Customer Portal](https://access.redhat.com/).  
   _These files must be placed in the `media/patches` directory_  


### Run Prerequisites

A database with the Pega rulebase must be already installed and reachable from the docker container

### Volumes
At runtime the image expose the following mount points as volumes:

* `/pega`

### Ports
The following ports are exposed:
 - JBOSS_MGMT_NATIVE_PORT `9999`
 - JBOSS_MGMT_HTTP_PORT `9990`
 - JBOSS_HTTP_PORT `8080`


### JBoss Console
JBoss Console app is reachable at `http://localhost:9990/console/A`  
Admin credentials are: `admin/Pegasys1+`

Build
-----
```
$ docker build -t giffd/prpc_jboss:7 .
```

Run
---
### Prepare the datasource
Edit the `datasources.properties` file and provide the jdbc connection details.
The following `datasources.properties` Oracle based sample is placed in `pega/etc`

```
base.datasource.name=PegaRULES
base.datasource.driver.name=oracle
base.datasource.jndi.name=java:/jdbc/PegaRULES
base.datasource.url=jdbc:oracle:thin:@db:1521/pega.oracle.xe
base.datasource.username=PEGA_DATA
base.datasource.password=PEGA
base.datasource.pool.initialSize=10
base.datasource.pool.maxSize=60

admin.datasource.name=AdminPegaRULES
admin.datasource.driver.name=oracle
admin.datasource.jndi.name=java:/jdbc/AdminPegaRULES
admin.datasource.url=jdbc:oracle:thin:@db:1521/pega.oracle.xe
admin.datasource.username=PEGA_INSTALL
admin.datasource.password=PEGA
admin.datasource.pool.initialSize=1
admin.datasource.pool.maxSize=5

rules.defaultSchemaName=PEGA_RULES
data.defaultSchemaName=PEGA_DATA
```

The docker `--link` run option can be used to [reference the database container using an alias](http://rominirani.com/2015/07/31/docker-tutorial-series-part-8-linking-containers/).
In the properties files above the database alias `db` is referenced in the jdbc url and must be provided at runtime by mapping the `db` alias with the name of a running Oracle container `oracle_container_name`. E.g.:  `--link oracle_container_name:db`


### Prepare the host directories
Create the expected folder structure in your computer.
The local `pega` directory can be used as template.

* `/pega`  
    Whitin this directory the following directories are expected:
    * `/deploy`  
    Place here the archives to be automatically deployed at runtime  
    * `/etc`  
        Place here the datasources configuration file and the standard Pega configuration files:  

            * datasource.properties
            * prbootstrap.properties
            * prconfig.xml
            * prlog4j2.xml  
   * `/tmp`  
        This will be used as Pega temporary directory
   * `/logs`  
       This directory is assigned to the `${pega.log.location}` env variable.
       Please ensure that the `prlog4j2.xml`file is updated to include this variable in file paths  
   * `/lib`  
        Place here the Oracle jdbc driver

### Run command
Run JBoss 7 in standalone mode using `as-jboss7-ora-740` as host name, remapping container port `8080` to host port `9740`, linking a running database container named `db-oraxe-pega-740` using the `db` alias, mounting the host path at the current working directory on the container volume `/pega`

```
$ pwd
/home/domenico/dev/docker/volume_mounts/jboss7_ora_740/pega

$ find
.
./tmp
./etc
./etc/prbootstrap.properties
./etc/prconfig.xml
./etc/prlog4j2.xml
./deploy
./deploy/prhelp.war
./deploy/prsysmgmt_jboss.war
./deploy/prpc_j2ee14_jboss7JBM.ear
./lib
./lib/README.txt
./lib/ojdbc8.jar
./logs

$ docker run -it -p 9740:8080 \
-h as-jboss7-ora-740 \
--name=as_jboss7_ora_740  \
--link db-oraxe-pega-740:db \
-v $(pwd):/pega \
giffd/prpc_jboss:7

```
More details about the used arguments:

* `-it`  
   Launch the container in interactive mode. The Server logs are provided in the output.  
   Pressing `CTRL+C` will halt the container   


* `-p 9740:8080`  
   Expose the container port 8080 on the host port 9740.   

* `-h`  
    Assign a static hostname to the container   
    _JBoss *doesn't* accept a host name with *underscore* characters_  
    If underscores are used in the host name the standalone instance will not boot correctly.

* `--name=`  
    Assign a static name to the container    

*  `--link db-oraxe-pega-740:db`
   Link the running database container named `db-oraxe-pega-740`  As such the JBoss container can reach the database using the `db` hostname.

* `-v $(pwd):/pega`  
    Create a bind mount point for the pega directory using the current host directory   

* `giffd/prpc_jboss:7`  
    the image to run

### Stopping a running container

 - Attach an interactive console to the container.
*This is not required if you run the container with the `-i` option:*

```
$ docker attach --sig-proxy=true Container_Name
```

 - Press  `CTRL+C` to stop the container:

### Starting an existing container
```
$ docker start -i -a <Container_Name>
```
