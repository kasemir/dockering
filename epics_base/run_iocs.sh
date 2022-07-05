# Run 'demo.db'

# In case IOC had been running, remove it.
# Could avoid this by running with --rm option,
# but that would also remove logs of IOC on exit,
# which are useful to debug problems
docker rm ioc_ramp ioc_noise

# -it     Create TTY for interactive use and/or for softIocPVA to continue
# -d      Detach (remove to run in terminal)
# --name  .. to identify IOC
# -v      Mount './db' folder into container as /db
docker run -itd --net=host -v $PWD/db:/db --name ioc_ramp  ornl_epics/epics_base softIocPVA -d /db/ramp.db
docker run -itd --net=host -v $PWD/db:/db --name ioc_noise ornl_epics/epics_base softIocPVA -d /db/noise.db

# Attach console via
#
#   docker attach ioc_ramp
#   docker attach ioc_noise
#
# Exit attached console via CTRL-p CTRL-q
