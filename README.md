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

# Directory structure

Working directory is:

    /srv/cinekid

This contain the following directories:

- samba: files are uploaded here
- render_locks: contains a lockfile when a video is rendering, lockfile contains PID and host id
- tmp: contains temporary files during rendering
- done: file is moved here when rendering is finished
    - removing a file here will cause it to be rerendered
    - this directory is rsynced to the webserver
    - jpeg files are generated here after video is rendered
- logs: contains logfiles for every render performed


Other log files can be found at:

    /var/log/upstart/cinekid_processing_pipeline.log
    /var/log/upstart/cinekid_rsync.log

# Status

To get status information on the current process run this command:

    make status

For status on only rsync or rendering pipeline:

    make status_pipeline
    make status_rsync

![expected output](https://gitlab.com/aequitas/cinekid/raw/master/expected%20output.png)

# General information

- List of files to render is shuffeled every time, so invalid files don't block the rendering pipeline
- Puppet is used to bring the system to required state (install packages, make required directories, install commands and add daemons)
- A user `cinekid` will be created and used for all actions, make sure you act as user `cinekid` when manually modifying files/directories: `sudo -u cinekid`
- These errors are normal:

    Warning: Setting templatedir is deprecated. See http://links.puppetlabs.com/env-settings-deprecations
    Warning: You cannot collect without storeconfigs being set on line 46 in file /vagrant/vendor/modules/nfs/manifests/server/export.pp

# Settings

Copy the file:

    hiera/settings.yaml.dist

To:

    hiera/settings.yaml

And modify files for setting overrides.

After changing settings run puppet apply again:

    make apply

Settings which are required are:

    cinekid::nfs::primary_server
    cinekid::nfs::secondary_server

# Debugging

Watching output of processing pipeline:

    sudo tail -f /var/log/upstart/cinekid_processing_pipeline.log

Logfile of individual renders can be found in:

    /srv/cinekid/logs/
