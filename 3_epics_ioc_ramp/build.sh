# Dockerfile 'COPY' cannot use ../db/ramp.db,
# must have file below the 'build context'.
# Copy file in..
cp ../db/ramp.db .
docker build -f Dockerfile -t ornl_epics/epics_ioc_ramp .
# .. and then remove again
rm ramp.db
