Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.define "encode-server-1" do |vm|
  end

  config.vm.define "encode-server-2" do |vm|
  end

  config.vm.define "test-web-server" do |vm|
  end

  # install puppet
  config.vm.provision "shell", keep_color: true, path: "scripts/bootstrap.sh"

  # run provisioning with puppet
  config.vm.provision "puppet" do |puppet|
    puppet.manifests_path = "manifests"
    puppet.manifest_file = "site.pp"

    puppet.module_path = ["modules", "vendor/modules"]

    puppet.hiera_config_path = "hiera.yaml"
    puppet.working_directory = "/vagrant"

    puppet.options = "--verbose"
  end

end
