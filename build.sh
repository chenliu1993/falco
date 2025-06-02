#!/bin/env bash

set -exo pipefail

VERSION=$1

if [[ -z ${VERSION} ]]; then
    VERSION=0.40.0-priv
fi

# Install deps and bpftool
sudo apt-get update -y && sudo apt-get install -y --no-install-recommends ca-certificates cmake curl wget build-essential git pkg-config autoconf automake libtool m4 rpm alien llvm libelf-dev

srcPath=$(pwd)

cd /tmp
git clone -b v7.5.0 --recursive-submodeules https://github.com/libbpf/bpftool.git
cd bpftool && git submodule update --init
cd src && make install && sudo install ./bpftool /usr/local/sbin/bpftool

cd ${srcPath}
rm -rf skeleton-build build

cmake -B skeleton-build -S . -DUSE_BUNDLED_DEPS=ON -DCREATE_TEST_TARGETS=Off -DFALCO_VERSION=${VERSION} -DFALCOSECURITY_LIBS_SOURCE_DIR="$(pwd)/libs" -DDRIVER_SOURCE_DIR="$(pwd)/libs/driver"
cmake --build skeleton-build --target ProbeSkeleton -j12

cmake -B build -S . -DCMAKE_BUILD_TYPE=RelWithDebInfo -DUSE_BUNDLED_DEPS=On -DFALCO_ETC_DIR=/etc/falco -DMODERN_BPF_SKEL_DIR=$(pwd)/skeleton-build/skel_dir -DBUILD_DRIVER=Off -DBUILD_BPF=Off -DUSE_JEMALLOC=ON -DFALCO_VERSION=${VERSION} -DFALCOSECURITY_LIBS_SOURCE_DIR="$(pwd)/libs" -DDRIVER_SOURCE_DIR="$(pwd)/libs/driver"
cmake --build build --target falco -j8
cmake --build build --target package
