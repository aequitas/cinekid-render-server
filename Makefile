export GEM_HOME=.gem
BIN=$(GEM_HOME)/bin

gem=/usr/bin/gem
bundle=$(BIN)/bundle
librarian-puppet=$(BIN)/librarian-puppet
puppet=$(BIN)/puppet

.PHONY: apply bootstrap

all: apply

# install puppet modules
Puppetfile.lock: Puppetfile | $(librarian-puppet)
	# update puppet module dependencies
	$(librarian-puppet) install

# apply puppet configuration
apply: Puppetfile.lock | $(puppet)
	# apply configuration to AWS
	$(puppet) apply --verbose \
	  --modulepath=modules:vendor/modules \
	  --hiera_config=hiera.yaml \
	  manifests/site.pp

# setup environment
bootstrap: | $(puppet) $(librarian-puppet)

# puppet gem binaries dependencies
$(puppet) $(librarian-puppet): Gemfile.lock

# install ruby packages from Gemfile
Gemfile.lock: Gemfile | $(bundle)
	$(bundle) install --path $(GEM_HOME) --binstubs $(BIN)

# install bundler Gemfile parser
$(bundle):
	$(gem) install --install-dir $(GEM_HOME) --bindir $(BIN) bundler

# install ruby
$(gem):
	sudo apt-get install -yqq ruby


mrproper:
	rm -rf vendor/modules/* *.lock

test:
	smbutil view -g //192.168.42.2 | grep Cinekid | grep Disk
	@echo -- All good --
