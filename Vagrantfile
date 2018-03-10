Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-16.04"
  config.ssh.insert_key = false
# config.vm.network "private_network", ip: "192.168.33.10"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
  end

  config.vm.provision "shell", inline: <<-SHELL
    add-apt-repository -y ppa:hadret/fswatch
    apt-get update -y
    apt-get install -y build-essential git autoconf m4 unzip wget
    apt-get install -y fswatch perl
    apt-get update -y
    bash /vagrant/startup/install_opam.sh
    sudo -u vagrant bash /vagrant/startup/install_satysfi.sh
    sudo -u vagrant bash /vagrant/startup/install_foolysh.sh
  SHELL

end
