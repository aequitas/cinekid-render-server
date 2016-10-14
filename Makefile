SHELL=/bin/bash

export GEM_HOME=.gem
BIN=$(GEM_HOME)/bin

WORKON_HOME ?= $(TMPDIR)
VIRTUALENV = $(WORKON_HOME)/cinekid

gem=/usr/bin/gem
git=/usr/bin/git
bundle=$(BIN)/bundle
librarian-puppet=$(BIN)/librarian-puppet
puppet=$(BIN)/puppet
pytest=$(VIRTUALENV)/bin/py.test
pylama=$(VIRTUALENV)/bin/pylama
autopep8 = $(VIRTUALENV)/bin/autopep8

.PHONY: apply bootstrap

ifeq ($(shell whoami),root)
$(error Must not run as root or use sudo!)
endif

all: apply

# install puppet modules
Puppetfile.lock: Puppetfile | $(librarian-puppet) $(git)
	# update puppet module dependencies
	$(librarian-puppet) install
	touch $@

/var/run/.initial_apt:
	sudo apt-get update
	sudo touch $@

.PHONY: git-remote-update
git-remote-update: | $(git)
	# checking for upstream changes
	@git remote update &>/dev/null || true
	@if [ ! -z "$$(git log HEAD..origin/master --oneline)" ];then \
		git log HEAD..origin/master --oneline; \
		echo "to pull in upstream changes run 'git pull' and apply again."; \
	else \
		echo "No upstream changes found."; \
	fi
	# /checking for upstream changes

# apply puppet configuration
apply: Puppetfile.lock /var/run/.initial_apt git-remote-update| $(puppet)
	# apply configuration
	sudo -E $(puppet) apply --verbose \
		--modulepath=modules:vendor/modules \
		--hiera_config=hiera.yaml \
		manifests/site.pp \
		2>&1 | egrep -v 'Warning: (Setting templatedir is|You cannot collect without storeconfigs|Loading facts|Facter::Util::EC2)'

# setup environment
bootstrap: | $(puppet) $(librarian-puppet)

# puppet gem binaries dependencies
$(puppet) $(librarian-puppet): Gemfile.lock

# install ruby packages from Gemfile
Gemfile.lock: Gemfile | $(bundle)
	$(bundle) install --quiet --path $(GEM_HOME) --binstubs $(BIN)
	touch $@

# install bundler Gemfile parser
$(bundle): $(gem)
	$(gem) install --bindir $(BIN) bundler

# install ruby
$(gem):
	sudo apt-get install -yqq ruby ruby1.9.1-dev

$(git): | /var/run/.initial_apt
	sudo apt-get install -yqq git

# cleaning and maintenance

mrproper:
	# cleaning up everything
	rm -rf vendor/modules/* *.lock .gem .bundle $(VIRTUALENV) .initial_apt.*
	# undo vagrant boxes
	vagrant destroy -f

# status

pipeline_files:
	find /srv/cinekid -type f

status:
	sudo tail -f /var/log/upstart/cinekid_processing_pipeline.log /var/log/upstart/cinekid_rsync.log

status_pipeline:
	sudo tail -f /var/log/upstart/cinekid_processing_pipeline.log

status_rsync:
	sudo tail -f /var/log/upstart/cinekid_rsync.log

tail_logs:
	sudo tail -n1 /srv/cinekid/logs/*

# testing

dev:
	sudo ln -sf `pwd`/src/* /usr/local/bin/
	sudo chmod a+x /usr/local/bin/*

ts = $(shell date +%s)
testfile = test 12341234 $(ts).m4v

empty_pipeline:
	sudo find /srv/cinekid/{render_locks,done,logs,tmp}/ -type f -delete

empty_incoming:
	sudo find /srv/cinekid/samba/ -type f -delete

fill_incoming:
	cat cinekid2015sourcevideos/test.mp4 | sudo -u cinekid tee "/srv/cinekid/samba/test/10/$(testfile)" >/dev/null

fill_source:
	sudo -u cinekid cp -v cinekid*sourcevideos/* /srv/cinekid/samba/test/20/

.PHONY: fix check test integration-test
fix: $(autopep8)
	# fix simple python style issues
	$(autopep8) --in-place --recursive --max-line-length 120 src
	# fix simple puppet linting errors
	puppet-lint --fix manifests
	puppet-lint --fix modules

check: $(pylama)
	# validate python
	$(pylama) src/
	# validate puppet
	puppet-lint manifests
	puppet-lint modules
	# validate shell scripts
	shellcheck scripts/*.sh src/*.sh

test: $(VIRTUALENV)/.requirements.txt | $(pytest)
	$(pytest) --doctest-modules src/

integration-test:
	# test guest login on samba
	smbutil view -g //192.168.42.2 | grep Cinekid | grep Disk

	# mount samba share
	-umount /Volumes/Cinekid
	mkdir -p /Volumes/Cinekid
	mount_smbfs //guest@192.168.42.2/Cinekid /Volumes/Cinekid

	# copy test video
	cp "cinekid2015sourcevideos/test.mp4" "/Volumes/Cinekid/test/10/$(testfile)"

	# test if file is rendered and thumbnail is generated (can take a few minutes)
	vagrant ssh encode-server-1 -- 'timeout 300 bash -c "\
		while sleep 5; do \
			test -f \"/srv/cinekid/done/test/10/$(testfile)\" && break; \
			test -f \"/srv/cinekid/done/test/10/$(subst m4v,jpg,$(testfile))\" && break; \
		done "'

	# test if file is uploaded to webserver
	vagrant ssh test-web-server -- 'timeout 60 bash -c "\
		while sleep 5; do \
			test -f \"/home/cinekid/results/test/10/$(testfile)\" && break; \
		done "'

	# cleanup
	umount /Volumes/Cinekid

	@echo -- All good --

timestamp=$(shell date +%s)
integration-test-local:
	# testing if directory can be created as cinekid user
	smbclient -U cinekid -c "mkdir test/20/test_${timestamp}" //localhost/Cinekid cinekid

	# testing if directory is created
	test -d /srv/cinekid/samba/test/20/test_${timestamp}

	# testing if directory can be created as cinekid user
	smbclient -U guest -N -c "mkdir test/20/guest_${timestamp}" //localhost/Cinekid

	# testing if directory is created
	test -d /srv/cinekid/samba/test/20/guest_${timestamp}

	@echo -- All good --

# tools

$(autopep8) $(pytest) $(pylama): $(VIRTUALENV)/.requirements.txt
$(VIRTUALENV)/.requirements.txt: test/requirements.txt | $(VIRTUALENV)
	$(VIRTUALENV)/bin/pip install -r test/requirements.txt
	touch $@

$(VIRTUALENV):
	virtualenv --python python3 $(VIRTUALENV)
