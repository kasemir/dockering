# Run 'demo.db'

# In case IOC had been running, remove it.
# Could avoid this by running with --rm option,
# but that would also remove logs of IOC on exit,
# which are useful to debug problems
docker rm ioc_demo

# -it     Create TTY for interactive use and/or for softIocPVA to continue
# -d      Detach (remove to run in terminal)
# --name  .. to identify IOC
# -v      Mount './db' folder into container as /db
docker run -itd --name ioc_demo --net=host -v $PWD/db:/db ornl_epics/epics_base softIocPVA -d /db/demo.db

# Attach console via
#
#   docker attach ioc_demo
#
# Exit attached console via CTRL-p CTRL-q
