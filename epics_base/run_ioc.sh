# Run 'demo.db'

# Interactively
docker run -it --rm --net=host  -v $PWD:/db ornl_epics/epics_base softIocPVA -d /db/demo.db

# In background
# docker run --rm -d --name ioc_demo --net=host -v $PWD:/db ornl_epics/epics_base softIocPVA -d /db/demo.db


