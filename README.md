This are application and provisioning sources to create media transcode servers.

# Requirements

- Ubuntu installation (tested on 14.04)
- User with `sudo` rights (or `root`)

# Installation

Install git and pull the repository locally:

    sudo apt-get install -yqq git
    git clone https://github.com/aequitas/cinekid-render-server.git

Run the following command to bootstrap/install:

    cd cinekid
    make

To reapply changes after the repository has been updated run these commands:

    cd cinekid
    git pull
    make

# Testing
This project is provided with a test suite to validate code quality and functionality.

To run quality check and unit tests:

    make check test

To verify funtionality after installation run:

    make integration-test-local

The following command will test the integrity of this project for development:

    make check test && vagrant destroy -f && vagrant up && make integration-test

# Development

For local development Vagrant can be used to create virtual render servers and run tests against the provisioned configuration. Make sure vragrant is installed and run:

    vagrant up

This will create 3 virtual machines: master render server `encode-server-1`, slave render server `encode-server-2` and a webserver for testing uploads `test-web-server`.

To login to master server and monitoring progress run:

    vagrant ssh encode-server-1

And once inside:

    make status

To run the testsuite against the virtual environment run:

    make integration-test

Machines can be brought up/created individually by their name:

    vagrant up encode-server-1

If provisioning needs to be reapplied (if it failed or configuration has changed) run:

    vagrant provision encode-server-1

This is equivalent of running `make` inside one of the virtual machines.

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

![expected output](https://raw.githubusercontent.com/aequitas/cinekid2015/master/expected%20output.png)

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

# Override render mapping

To override which render script is used for which 'werkje' directory or input extension create the following file:

    /srv/cinekid/config/render_mapping.json

This file should be a valid json file containing a json object (dict) mapping 'werkje' directories or extensions to lists containing a rendered name and desired output extension.

## Examples

To render file with de `default` renderer by default (so if not overwritten by another rule) using the `m4v` extension for the output file put this in the file:

    {
        "default": ["default", "m4v"]
    }

To have the files of `TestWerkje123` not processed at all but just passed on as-is (without changing the extension) use this:

    {
        "TestWerkje123": ["noop", null]
    }

Multiple rules can be combined like this:

    {
        "default": ["default", "m4v"],
        "TestWerkje123": ["noop", null],
        "apk": ["noop", null]
    }

To test if the json file is valid run this command:

    python -m json.tool /srv/cinekid/config/render_mapping.json

It should output the contents of the json file on success, or an error on failure.

## Available renderers

Renderers are 'bash' scripts living in the directory:

    /srv/cinekid/renderers

They are named:

    cinekid_renderer_######.sh

Where ####### is the renderer name.

Default installed renderers are:

    - default: the default renderer, rendering files to h264/AAC.
    - noop: NO OPeration renderer. 'Copies' the file as-is to output.

Renderers are extension agnostic. Extensions are set in the `render_mapping.json` file.

To experiment with renderers it is possible to create a copy of a existing renderer (preferable 'default') in the same directory with a different 'renderer name'.

This can then be references in the 'render_mapping.json' without modification of the application sourcecode.

# Debugging

Watching output of processing pipeline:

    sudo tail -f /var/log/upstart/cinekid_processing_pipeline.log

Logfile of individual renders can be found in:

    /srv/cinekid/logs/
