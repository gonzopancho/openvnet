#!/bin/bash

BASE=$(cd $(dirname $0) && /bin/pwd)

BUILD_DEPS="wakame-vdc-ruby make git gcc gcc-c++ zlib-devel openssl-devel
zeromq-devel openssl-devel zeromq-devel mysql-devel sqlite-devel libpcap-devel"
USAGE_DEPS="redis mysql-server upstart"

err() { echo 1>&2 "ERROR: $@"; exit 1; }

mode=$1

set -e
BUILD_OK=false
BUILD_ERR="Internal error"
trap '$BUILD_OK || err "${BUILD_ERR}"' 0

function reset_db() {
  cd ${BASE}/vnet
  bundle exec rake db:drop
  bundle exec rake db:create
  bundle exec rake db:migrate
}

function print_usage {
  echo "Commands:
    $0 install-deps-rhel   # Installs rhel dependencies for Wakame-VNet.
    $0 dev-setup           # Installs config files, upstart jobs and resets the database.
    $0 reset-db            # Resets the database.
    $0 bundle              # Installs the gems bundle for Wakame-VNet.
  "
}


case ${mode} in
  install-deps-rhel)
    yum install -y install $BUILD_DEPS $USAGE_DEPS
    BUILD_OK=true
    ;;
  dev-setup)
    make update-config
    reset_db
    BUILD_OK=true
    ;;
  reset-db)
    reset_db
    BUILD_OK=true
    ;;
  bundle)
    make install-bundle-dev
    BUILD_OK=true
    ;;
  *)
    BUILD_ERR="Unknown command: ${mode}"
    print_usage
    ;;
esac
