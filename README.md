Docker Explorations
===================

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

On Linux, a container can thus be just a process. The containerized process is in a restricted namespace
with a different view of the processes environment and file systems.
When running Linux containers on Windows, they might actually run inside a VM, but Linux containers on a Linux host
can perform just like plain host processes.

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

To access without ‘sudo’: 

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

    # no vi, gcc, ifconfig, … 
    # `ps aux` shows just that ps and bash
    # -i to then keep terminal in that bash 
    # -t for tty 
    # Takes ~20 seconds on first run, then ~2  
    docker run -i -t ubuntu /bin/bash 

Inspect running container 

    docker ps -a 
    docker container  top  id_or_name_of_container 

Execute shell in running container

    docker exec –id  id_or_name_of_container /bin/sh 

Delete stopped containers 

    docker ps -a 
    docker container  rm   id_or_name_of_container

 * https://docs.docker.com/get-started/docker_cheatsheet.pdf 
 * https://stackoverflow.com/questions/57607381/how-do-i-change-timezone-in-a-docker-container 


Volumes 
-------

Volumes are folder structures maintained by docker:

    docker volume create demo-volume 
    docker volume  ls –q
    
Create something under /mnt/demo in that ubuntu container, then exit:
    
    docker run -it --rm -v demo-volume:/mnt/demo ubuntu /bin/bash
    
Repeat, and each instance sees the same content under `/mnt/demo`.
It is possible to locate the volume data inside the docker file tree:

    docker volume inspect demo-volume  
    sudo ls -l /var/lib/docker/volumes/demo-volume/_data 

Alternatively, containers can directly mount a host folder:

    docker run -it --rm -v /tmp:/mnt/host_tmp ubuntu /bin/bash


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


Use `--net=host for full connectivity.

    docker run -it --rm --net=host busybox

This container will see all host interfaces in `ifconfig`.
When running `nc -l -v -p 9876` on the container,
the host can connect via `nc -l localhost 9876`.
When running `nc -v -l {IP of host} 9876` on the host,
the container will be able to connect via `nc {IP of host} 9876`.
Note different versions of `nc` in this example, requiring `-p 9876` to serve
from the container.

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


EPICS Base
----------

https://github.com/prjemian/epics-docker/tree/main/v1.1
https://github.com/pklaus/docker-epics-directory#readme 
https://github.com/pklaus/docker-epics/blob/master/epics_base/7.0.4_debian/Dockerfile 
 

TODO
----

‘docker build ...' is a lot like maven, fetching dependencies from some internet location,
reporting errors like `Resolution field "ansi-regex@5.0.1" is incompatible with requested version ...`.

Build images into local registry?

Where are the registries? `docker info`: 

    Registry: https://index.docker.io/v1/ 
    Insecure Registries: 127.0.0.0/8 
 
