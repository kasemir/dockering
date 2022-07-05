# EPICS base, size about 800 MB

# 'build' image
FROM ubuntu AS build

# Tools to fetch source code
RUN apt-get update && \
    apt-get install -yq wget git

# Tools to build C/C++ code
RUN apt-get update && \
    apt-get install -yq build-essential \
                        libreadline-dev

# EPICS base
WORKDIR /controls
ARG EPICS_BASE_NAME="base-7.0.6.1"
RUN wget -q https://epics.anl.gov/download/base/${EPICS_BASE_NAME}.tar.gz && \
    tar -xf ${EPICS_BASE_NAME}.tar.gz                                     && \
    rm ${EPICS_BASE_NAME}.tar.gz                                          && \
    mv ${EPICS_BASE_NAME} base                                            && \
    cd base && make && make clean                                         && \
    echo EPICS_BASE=/controls/base >/controls/RELEASE.local

# Add autosave
RUN cd /controls                                                                    && \
    wget https://github.com/epics-modules/autosave/archive/refs/tags/R5-10-2.tar.gz && \
    tar vzxf R5-10-2.tar.gz                                                         && \
    rm R5-10-2.tar.gz                                                               && \
    mv autosave-R5-10-2 autosave                                                    && \
    cd autosave && make && make clean                                               && \
    echo AUTOSAVE=/controls/autosave >>/controls/RELEASE.local

# Compilation takes about 15 minutes.
# Adding the last "make clean" as a separate
#   RUN cd base && make clean
# step to a previous version of the Dockerfile performed only that action,
# avoiding a repeat of the ~15 minute build.
# But the resulting image size stayed at ~2 GB,
# while a fresh image based on this Dockerfile uses only 800 MB

# Cleanup
RUN rm -rf /var/lib/apt/lists/*

ENV PATH="/controls/base/bin/linux-x86_64:${PATH}"
CMD [ "/bin/bash" ]
