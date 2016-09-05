SHELL=/bin/bash

export GEM_HOME=.gem
BIN=$(GEM_HOME)/bin

WORKON_HOME ?= $(TMPDIR)
VIRTUALENV = $(WORKON_HOME)/cinekid

gem=/usr/bin/gem
bundle=$(BIN)/bundle
librarian-puppet=$(BIN)/librarian-puppet
puppet=$(BIN)/puppet
pytest=$(VIRTUALENV)/bin/py.test

.PHONY: apply bootstrap

all: apply

# install puppet modules
Puppetfile.lock: Puppetfile | $(librarian-puppet)
	# update puppet module dependencies
	$(librarian-puppet) install

.initial_apt.$(shell hostname):
	sudo apt-get update
	touch $@

# apply puppet configuration
apply: Puppetfile.lock .initial_apt.$(shell hostname)| $(puppet)
	# apply configuration
	sudo -E $(puppet) apply --verbose \
	  --modulepath=modules:vendor/modules \
	  --hiera_config=hiera.yaml \
	  manifests/site.pp \
	  2>&1 | egrep -v 'Warning: (Setting templatedir is|You cannot collect without storeconfigs)'

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

# cleaning and maintenance

mrproper:
	rm -rf vendor/modules/* *.lock .gem .bundle $(VIRTUALENV) .initial_apt.*

# status

pipeline_files:
	find /srv/cinekid -type f

status:
	sudo tail -f /var/log/upstart/cinekid_processing_pipeline.log /var/log/upstart/cinekid_rsync.log

status_pipeline:
	sudo tail -f /var/log/upstart/cinekid_processing_pipeline.log

status_rsync:
	sudo tail -f /var/log/upstart/cinekid_rsync.log

# testing

dev:
	sudo ln -sf `pwd`/src/* /usr/local/bin/
	sudo chmod a+x /usr/local/bin/*

ts = $(shell date +%s)
testfile = test 12341234 $(ts).m4v

empty_pipeline:
	sudo find /srv/cinekid/{render_locks,done,logs,tmp}/ -type f -delete

fill_incoming:
	cat cinekid2015sourcevideos/test.mp4 | sudo -u cinekid tee "/srv/cinekid/samba/test/10/$(testfile)" >/dev/null

.PHONY: test
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

	# test if file is rendered
	while sleep 5; do \
		vagrant ssh encode-server-1 -- 'test -f "/srv/cinekid/done/test/10/$(testfile)"' && break; \
	done

	# cleanup
	umount /Volumes/Cinekid

	@echo -- All good --

$(pytest):
	virtualenv --python python3 $(VIRTUALENV)

$(VIRTUALENV)/.requirements.txt: test/requirements.txt
	$(VIRTUALENV)/bin/pip install -r test/requirements.txt
	touch $@
