#!/usr/bin/env bash

# apply puppet configuration

set -e

cd "$(dirname "$0")/.."

which puppet >/dev/null || ./bootstrap.sh

puppet apply --verbose \
  --modulepath=modules:vendor/modules \
  --hiera_config=hiera.yaml \
  manifests/site.pp "$@"
