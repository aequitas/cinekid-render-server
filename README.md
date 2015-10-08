# Requirements

- Ubuntu installation (tested on 14.04)
- User with `sudo` rights (or `root`)

# Installation

Install git and pul the repository locally (you will need Gitlab credentials for the clone):

    sudo apt-get install -yqq git
    git clone https://gitlab.com/aequitas/cinekid.git

Run the following command to bootstrap/install:

    cd cinekid
    make

To reapply changes after the repository has been updated run these commands:

   cd cinekid
   git pull
   make

# General information

- Puppet is used to bring the system to required state (install packages, make required directories, install commands and add daemons)
- A user `cinekid` will be created and used for all actions, make sure you act as user `cinekid` when manually modifying files/directories: `sudo -u cinekid`
- These errors are normal:

    Warning: Setting templatedir is deprecated. See http://links.puppetlabs.com/env-settings-deprecations
    Warning: You cannot collect without storeconfigs being set on line 46 in file /vagrant/vendor/modules/nfs/manifests/server/export.pp

# Settings

Refer to the file:

    hiera/common.yaml

To find configurable settings.

After changing settings run puppet apply again:

    make apply

# Debugging

Watching output of processing pipeline:

    sudo tail -f /var/log/upstart/cinekid_processing_pipeline.log

Logfile of individual renders can be found in:

    /srv/cinekid/logs/
