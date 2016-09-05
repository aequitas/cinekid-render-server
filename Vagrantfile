Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.define "encode-server-1", primary: true do |config|
    config.vm.hostname = "encode-server-1"
    config.vm.network "private_network", ip: "192.168.42.2"
  end

  config.vm.define "encode-server-2" do |config|
    config.vm.hostname = "encode-server-2"
    config.vm.network "private_network", ip: "192.168.42.3"
  end

  config.vm.define "test-web-server" do |config|
    config.vm.hostname = "test-web-server"
    config.vm.network "private_network", ip: "192.168.42.10"
  end

  config.vm.provision "shell", keep_color: true, inline: 'echo "cd /vagrant; export WORKSPACE=/tmp; export PATH=/vagrant/scripts:$PATH; export WORKON_HOME=/tmp" >> /home/vagrant/.bashrc;'
  config.vm.provision "shell", keep_color: true, inline: "/usr/bin/make -C /vagrant"
end
