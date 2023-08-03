# Containerized SEDIMENT 
This directory contains docker components for the SEDIMENT project. 
It contains a pre-built docker container image for SEDIMENT and 
a shell convenience scripts to configure and initiate the containers.

## Contents
- [Docker Container](#docker-container)
- [Running the Containers](#running-the-containers)

## Docker Container
The containerized SEDIMENT system is implemented as a single docker container on Ubuntu 20.04 Linux. See [Docker Installation](https://docs.docker.com/engine/install/ubuntu/) for instructions on installing docker on Ubuntu.
Once docker is installed, create a SEDIMENT network using the following command                                     

        $ docker network create --subnet=192.168.2.0/24 sediment

Note that the SEDIMENT database is configured to use subnet 192.168.2.0/24. It the subnet is changed, then the database in data/sediment.db needs to be changed accordingly.
Download the SEDIMENT container tar archive (sediment-container.tar.gz) and import it. 

        $ cat sediment-container.tar.gz | docker import - sediment:demo
        $ docker images
```
REPOSITORY   TAG       IMAGE ID       CREATED          SIZE
sediment     demo      ddff5022cc92   18 minutes ago   257MB
```

## Running the Containers
The container can be started either in automatic or manual mode.

### Automatic Mode
Running in automatic mode means relavant SEDIMENT components are designated as the entrypoints of the containers.
The SEDIMENT container can be started using start.sh.
```
Usage: ./start.sh [ -acmrstwh ] 
    -c <component>    { prover | verifier | firewall | app_server }
    -m                Run in manual mode
    -r <repo:tag>     Docker image repo:tag
    -h                Help
```

Run each of the following commands in a separate terminal.

        $ ./start.sh -c firewall
        $ ./start.sh -c verifier
        $ ./start.sh -c app_server
        $ ./start.sh -c prover                     

On the verifier terminal, it should show that device with the ID Ubuntu-001 passes remote attestation.
Sensor data will then appear on the app_server window shortly.
Note that there will be some periodical connection errors causes by GUI not being present.
They are not relavant for attestaion purposes.

### Manual Mode
For debugging purposes, the containers can be started in manual mode, using the -m option.

        $ ./start.sh -c firewall -m
        $ ./start.sh -c verifier -m
        $ ./start.sh -c app_server -m
        $ ./start.sh -c prover -m

Once the containers are started, run SEDIMENT components as follows.

        sediment@firewall:~$ build/firewall
        sediment@verifier:~$ build/verifier
        sediment@app_server:~$ build/app_server
        sediment@prover:~$ build/prover

