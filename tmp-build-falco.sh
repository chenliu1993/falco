#!/bin/bash

set -eo pipefail

FALCO_REPO=/home/cliu/go/src/github.com/chenliu1993/falco

firstarg=$1

if [[ ${firstarg} == "" ]]; then
    firstarg="nothing"
fi

if [[ ${firstarg} == "build" ]]; then
    rm -rf ${FALCO_REPO}/build
    mkdir -p ${FALCO_REPO}/build
    cd ${FALCO_REPO}/build && cmake .. -DUSE_JEMALLOC=OFF \
                -DADD_FALCOCTL_DEPENDENCY=OFF \
                -DCMAKE_BUILD_TYPE=Debug \
                -DCMAKE_CXX_FLAGS_DEBUG="-O0 -NDEBUG -Wno-unused-but-set-variable" \
                -DUSE_BUNDLED_DEP=On \
                -DFALCO_VERSION=v0.0.1 \
                .. && make falco -j6;
elif [[ ${firstarg} == "run" ]]; then
    sudo ${FALCO_REPO}/build/userspace/falco/falco -c ${FALCO_REPO}/falco.yaml -r ${FALCO_REPO}/falco_rules.yaml
else
    echo "Do nothing"
fi
