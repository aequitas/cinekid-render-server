Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.define "encode-server-1" do |config|
    config.vm.hostname = "encode-server-1"
    config.vm.network "private_network", ip: "192.168.42.2"
  end

  config.vm.define "encode-server-2" do |config|
    config.vm.hostname = "encode-server-2"
    config.vm.network "private_network", ip: "192.168.42.3"
  end

  # config.vm.define "test-web-server" do |config|
  #   config.vm.hostname = "test-web-server"
  #   config.vm.network "private_network", ip: "192.168.42.10"
  # end

  config.vm.provision "shell", keep_color: true, inline: "/usr/bin/make -C /vagrant"

#  # install puppet
#  config.vm.provision "shell", keep_color: true, path: "scripts/bootstrap.sh"
#
#  # run provisioning with puppet
#  config.vm.provision "puppet" do |puppet|
#    puppet.manifests_path = "manifests"
#    puppet.manifest_file = "site.pp"
#
#    puppet.module_path = ["modules", "vendor/modules"]
#
#    puppet.hiera_config_path = "hiera.yaml"
#    puppet.working_directory = "/vagrant"
#
#    puppet.options = "--verbose"
#  end

end
