# Run IOCs

# In case IOC had been running, remove it.
# Could avoid this by running with --rm option,
# but that would also remove logs of IOC on exit,
# which are useful to debug problems
docker rm -f ioc_ramp

# -it     Create TTY for interactive use and/or for softIocPVA to continue
# -d      Detach (remove to run in terminal)
# --name  .. to identify IOC
docker run -itd --net=host --name ioc_ramp --user $UID  ornl_epics/epics_ioc_ramp

# Attach console via
#
#   docker attach ioc_ramp
#   docker attach ioc_noise
#
# Exit attached console via CTRL-p CTRL-q
