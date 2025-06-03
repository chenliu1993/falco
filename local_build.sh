#!/bin/env bash

set -exo pipefail

VERSION=$1

if [[ -z ${VERSION} ]]; then
    VERSION=0.40.0-priv
fi

DEFAULT_DRIVER_VERSION=8.1.0+driver
DEFAULT_LIBS_VERSION=0.21.0

nproc=$(grep processor /proc/cpuinfo | tail -n 1 | awk '{print $3}')
echo "Running with ${nproc}"

# Install deps and bpftool
# sudo apt update -y && sudo apt install -y --no-install-recommends cppcheck git ca-certificates cmake curl wget build-essential clang pkg-config autoconf automake libtool m4 rpm alien llvm libelf-dev
# echo $(pwd)
srcPath=$(pwd)

# cd /tmp
# git clone -b v7.5.0 --recurse-submodules https://github.com/libbpf/bpftool.git
# cd bpftool && git submodule update --init
# cd src && sudo make install && sudo install ./bpftool /usr/local/sbin/bpftool

# cd ${srcPath}

rm -rf skeleton-build build

cmake -B skeleton-build -S . \
    -DUSE_BUNDLED_DEPS=ON \
    -DCREATE_TEST_TARGETS=ON \
    -DFALCO_VERSION=${VERSION} \
    -DBUILD_FALCO_MODERN_BPF=ON \
    -DFALCOSECURITY_LIBS_SOURCE_DIR="${srcPath}/libs" \
    -DDRIVER_SOURCE_DIR="${srcPath}/libs/driver" \
    -DBUILD_FALCO_UNIT_TESTS=ON \
    -DFALCOSECURITY_LIBS_VERSION=${DEFAULT_LIBS_VERSION} \
    -DDRIVER_VERSION=${DEFAULT_DRIVER_VERSION}

cmake --build skeleton-build --target ProbeSkeleton -j8

cmake -B build -S . \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DUSE_BUNDLED_DEPS=ON \
    -DBUILD_FALCO_MODERN_BPF=ON \
    -DFALCO_ETC_DIR=/etc/falco \
    -DBUILD_FALCO_UNIT_TESTS=ON \
    -DMODERN_BPF_SKEL_DIR=${srcPath}/skeleton-build/skel_dir \
    -DBUILD_DRIVER=ON \
    -DBUILD_BPF=ON \
    -DUSE_JEMALLOC=ON \
    -DFALCO_VERSION=${VERSION} \
    -DFALCOSECURITY_LIBS_SOURCE_DIR="${srcPath}/libs" \
    -DDRIVER_SOURCE_DIR="${srcPath}/libs/driver" \
    -DFALCOSECURITY_LIBS_VERSION=${DEFAULT_LIBS_VERSION} \
    -DDRIVER_VERSION=${DEFAULT_DRIVER_VERSION}
cmake --build build --target falco -j8

cmake --build build --target falco_unit_tests -j8

cmake --build build --target package
