#!/usr/bin/env bash

# stop on first error
set -e

skipfile=".$(basename "$0").skip"

test -f "${skipfile}" && exit 0

# install puppet
wget http://apt.puppetlabs.com/puppetlabs-release-pc1-wheezy.deb
sudo dpkg -i puppetlabs-release-pc1-wheezy.deb
sudo apt-get update
sudo apt-get -yqq install puppet git
touch "${skipfile}"
