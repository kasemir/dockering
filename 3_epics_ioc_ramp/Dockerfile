# EPICS IOC, ~same size as epics_prod

# 'prod' image for EPICS binaries
FROM ornl_epics/epics_prod

# Add database file
WORKDIR /controls
COPY ramp.db .

# By default, start IOC
CMD [ "softIocPVA", "-d", "ramp.db" ]
