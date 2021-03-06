Docker Explorations
===================

Demo of using Docker for EPICS IOCs.

 * `1_epics_base`:
   Docker image with EPICS base and some other EPICS module. Can be used to run IOCs or as basis for building additional modules.
 * `2_epics_prod`:
   Smaller image that has just the binaries. Can be used to run IOCs.
 * `3_epics_ioc_ramp`:
   Image for running a specific IOC.


Overview
--------

A Docker container is more lightweight than a VM.
On Linux, start an interactive ubuntu container, and inside that one we run `top`:

    # -it      Allocate interactive TTY, so 'top' will show in the terminal session
    # --rm     Remove container when done, don't keep the 'stopped' container
    # --name   .. so we can easier identify the container
    # ubuntu   Publicly available container image
    # top      Command to run in container
    docker run -it --rm --name playground ubuntu top

The instance of `top` inside the container will only list itself; one process `top` with PID 1.
When checking for `top` on the host, it will show an instance of `top` running as root, under a PID different from 1:

    ps aux | fgrep top | fgrep root

In fact the same PID will be indicated by this docker command:

    docker top playground

The CPU, memory and uptime info listed by the containerized `top` matches the info shown in a `top` instance
running on the host.
Killing the `top` instance on the host will stop the containerized process and in fact end the container:

    # Use PID from `ps aux | fgrep top | fgrep root`, i.e. the host PID
    sudo kill 1702

On Linux, a container can thus be like most other processes without any performance penalty.
The containerized process is simply in a restricted namespace
with a different view of the processes environment and file systems.
When running Linux containers on Windows or Mac, they actually run inside a VM.
On the Mac, that VM shows as a process `com.docker.hyperkit`.

 * https://docs.microsoft.com/en-us/virtualization/windowscontainers/deploy-containers/linux-containers 
 * https://stackoverflow.com/questions/41550727/how-does-docker-for-windows-run-linux-containers 


Setup 
-----

Installation details depend on the OS:

 * https://docs.docker.com/get-started/overview/
 * https://docs.docker.com/engine/install/rhel/

On Linux, this will result in a `systemd` service for the docker daemon:

    yum list installed | fgrep dock 
    cat  /etc/yum.repos.d/docker.repo 
    
    systemctl status docker.service 
    sudo docker info 

To access without ???sudo???: 

    sudo usermod -aG docker $USER 

    docker info 
    docker system info 


Basics
------

    docker images 
    docker image   ls 

    docker run hello-world 

    docker run -i -t ubuntu /bin/echo Hi 

Run bash in bare ubuntu:

    # no vi, gcc, ifconfig, ??? 
    # `ps aux` shows just that ps and bash
    # -i to then keep terminal in that bash 
    # -t for tty 
    # Takes ~20 seconds on first run, then ~2  
    docker run -i -t ubuntu /bin/bash 

Inspect running container 

    docker ps -a 
    docker container  top  id_or_name_of_container 

Execute shell in running container

    docker exec ???id  id_or_name_of_container /bin/sh 

Delete stopped containers 

    docker ps -a 
    docker container  rm   id_or_name_of_container

 * https://docs.docker.com/get-started/docker_cheatsheet.pdf 
 * https://stackoverflow.com/questions/57607381/how-do-i-change-timezone-in-a-docker-container 


Volumes 
-------

Volumes are folder structures maintained by docker:

    docker volume create demo-volume 
    docker volume  ls ???q
    
Create something under /mnt/demo in that ubuntu container, then exit:
    
    docker run -it --rm -v demo-volume:/mnt/demo ubuntu /bin/bash
    
Repeat, and each instance sees the same content under `/mnt/demo`.
It is possible to locate the volume data inside the docker file tree:

    docker volume inspect demo-volume  
    sudo ls -l /var/lib/docker/volumes/demo-volume/_data 

Alternatively, containers can directly mount a host folder:

    docker run -it --rm -v /tmp:/mnt/host_tmp ubuntu /bin/bash


Users
-----

Each container keeps its own user and group IDs in /etc/passwd and /etc/group,
and by default the container runs as "root".
When running a container with a named user, that user needs to be defined
inside the container.
It is also possible to run the container with a numeric user ID
which can be helpful when mounting folders and wanting to access them
as a user that's defined on the host:

    # Run container with current host user:
    docker run --rm -v /tmp:/mnt/host_tmp --user $UID \
           ubuntu /usr/bin/touch /mnt/host_tmp/created_by_container


Network
-------

Docker can create its own networks:

    docker network create mynet

Now run two containers using the `busybox` image which includes `ping`, `ifconfig`, `nc`:

    # Terminal 1
    docker run -it --rm --network mynet --network-alias box1 busybox
    # Terminal 2
    docker run -it --rm --network mynet --network-alias box2 busybox

`ifconfig` shows just `lo` and `eth0` in each container, with different IP.
Their names resolve.
    
    # On box1:
    ping box2
    nc -l -v -p 9876
    
    # On box2:
    ping box1
    nc -v box1 9876

To run IOCs inside a container and make them available on the wider network,
there are two options.
One is to specifically map ports from the container to the host by
running the container with options like

    docker run -p 5064:5064/udp -p 5064:5064 p 5065:5065 -it ...

This approach works for a single container with one IOC, but gets
complicated beyond that.

On Linux hosts, there is an additional option `--net=host` for full connectivity.

    docker run -it --rm --net=host busybox

This container will see all host interfaces in `ifconfig`.
When running `nc -l -v -p 9876` on the container,
the host can connect via `nc -l localhost 9876`.
When running `nc -v -l {IP of host} 9876` on the host,
the container will be able to connect via `nc {IP of host} 9876`.
Note different versions of `nc` in this example, requiring `-p 9876` to serve
from the container.

When running multiple IOC containers with `--net=host`, they will behave just like
other IOCs running on a Linux host.
The first one will listen on UDP 5064 as well as TCP 5064.
The next one will listen on the same UDP 5064 but a random free TCP port.
Based on the Linux kernel, only one of the IOCs might receive
search requests on UDP 5064 unless the client uses a broadcast in
`EPICS_CA_ADDR_LIST`, for example 127.255.255.255 for local tests on the host,
or the actual broadcast address of the subnet, assuming that the host
does not block that via a firewall.

When debugging network access on an ubuntu image,
you may need to add the networking tools:

    apt-get update
    apt-get install net-tools

 * https://stackoverflow.com/questions/39901311/docker-ubuntu-bash-ping-command-not-found



Dockerfile
----------

Check content of existing image:

    docker image history --no-trunc ubuntu

Order of commands in `Dockerfile` matters, because changes
result in re-build from then on.
http://localhost/tutorial/image-building-best-practices/ has hints,
including use of `.dockerignore`.

Multi-stage builds allow installing JDK or `gcc` to build,
but then only keep the binaries in the resulting image.

Finding available packages on ubuntu:

    # Get package info, unzip
    apt-get update
    apt-get install lz4
    cd /var/lib/apt/lists
    for i in *Packages*; do lz4cat $i > $i.txt; done

    # Look for something
    fgrep libreadline *.txt

EPICS Base
----------

See `epics_base` for building image that contains EPICS base
and to run an IOC in there.

 * https://github.com/prjemian/epics-docker/tree/main/v1.1
 * https://github.com/pklaus/docker-epics-directory#readme 
 * https://github.com/pklaus/docker-epics/blob/master/epics_base/7.0.4_debian/Dockerfile 
 

Running IOCs
------------

Basic idea for running an IOC:

    docker run -itd --name ioc_demo --net=host -v $PWD/db:/db ornl_epics/epics_base softIocPVA -d /db/demo.db

Check running IOCs:

    docker ps

View log:

    docker logs [-f] ioc_demo

Attach console (exit via `CTRL-p CTRL-q`):

    docker attach ioc_demo 

Stop IOC via `CTRL-c` or `CTRL-d` in console, or via

   docker stop ioc_demo

After an IOC has been stopped or exited for some reason, the log remains available,
which can help to debug issues.
Before restarting the IOC, however, a previous container needs to be removed:

   docker rm ioc_demo


Registry
--------

Setup and maintenance of a secure local registry is not trivial.
This example uses an insecure one without encryption nor authentication.
Start a local registry, using an `/opt/..` folder for storage:

    docker run -d -p 5000:5000                             \
               -v /opt/docker_registry:/var/lib/registry   \
               --restart=always --name registry registry:2

Note that simply starting the local registry requires internet access
for it to download the `registry` image.

To allow access from other hosts, may have to open firewall.
Use `--remove-rule` to revert, add `--permanent` to persist the setting over firewall restarts.

    sudo firewall-cmd --direct --add-rule ipv4 filter IN_public_allow 0 -m tcp -p tcp --dport 5000 -j ACCEPT

To push locally available images into the registry, they need a tag that
starts with "hostname:port/":

    docker tag ubuntu:latest             localhost:5000/ubuntu
    docker tag ornl_epics/epics_base     localhost:5000/ornl_epics/epics_base:latest
    docker tag ornl_epics/epics_prod     localhost:5000/ornl_epics/epics_prod:latest
    docker tag ornl_epics/epics_ioc_ramp localhost:5000/ornl_epics/epics_ioc_ramp:latest

Now push those tagged images into the local registry:

    docker push localhost:5000/ubuntu
    docker push localhost:5000/ornl_epics/epics_base:latest 
    docker push localhost:5000/ornl_epics/epics_prod:latest 
    docker push localhost:5000/ornl_epics/epics_ioc_ramp:latest 

Trying to use this registry from another host will end like this:

    $ docker pull name_of_reg_host:5000/ubuntu
    Error ... server gave HTTP response to HTTPS client

Enable insecure access by adding the following to the docker config on the client.
With docker desktop, the config can be found in the "Docker Engine" tab of the desktop.
On Linux, use the file `/etc/docker/daemon.json`:

    {
      "insecure-registries": ["name_of_reg_host:5000" ]
    }

When now pulling from the remote repo, the image uses that name:

    docker pull name_of_reg_host:5000/ornl_epics/epics_prod:latest 

Re-tag to a more convenient name:

    docker tag name_of_reg_host:5000/ornl_epics/epics_prod:latest  ornl_epics/epics_prod:latest


 * https://docs.docker.com/registry
 * https://docs.docker.com/registry/insecure
 * https://docs.docker.com/engine/reference/commandline/dockerd/#daemon-configuration-file


