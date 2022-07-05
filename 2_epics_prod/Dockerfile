# EPICS essentials for production, size about 450 MB

# 'prod' image
FROM ubuntu as prod

# Tools to support runtime
RUN apt-get update                      && \
    apt-get install -yq libreadline8    && \
    rm -rf /var/lib/apt/lists/*

# EPICS base: Binaries, not sources
WORKDIR /controls
COPY --from=ornl_epics/epics_base /controls/base/bin       /controls/base/bin
COPY --from=ornl_epics/epics_base /controls/base/configure /controls/base/configure
COPY --from=ornl_epics/epics_base /controls/base/dbd       /controls/base/dbd
COPY --from=ornl_epics/epics_base /controls/base/include   /controls/base/include
COPY --from=ornl_epics/epics_base /controls/base/lib       /controls/base/lib
COPY --from=ornl_epics/epics_base /controls/base/templates /controls/base/templates

COPY --from=ornl_epics/epics_base /controls/autosave/bin       /controls/autosave/bin
COPY --from=ornl_epics/epics_base /controls/autosave/configure /controls/autosave/configure
COPY --from=ornl_epics/epics_base /controls/autosave/db        /controls/autosave/db
COPY --from=ornl_epics/epics_base /controls/autosave/dbd       /controls/autosave/dbd
COPY --from=ornl_epics/epics_base /controls/autosave/include   /controls/autosave/include
COPY --from=ornl_epics/epics_base /controls/autosave/lib       /controls/autosave/lib

COPY --from=ornl_epics/epics_base /controls/RELEASE.local      /controls/RELEASE.local

ENV PATH="/controls/base/bin/linux-x86_64:${PATH}"
CMD [ "/bin/bash" ]
