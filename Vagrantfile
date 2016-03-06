# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|

  config.vm.define "lycra" do |docker|
    docker.vm.provider "virtualbox" do |virtualbox|
      virtualbox.name = "lycra"
    end
    docker.vm.box = "bento/ubuntu-14.04"
    docker.vm.hostname = "lycra"
    docker.vm.provision "docker"
    docker.vm.network :forwarded_port, guest: 9201, host: 9201
    docker.vm.network :forwarded_port, guest: 9202, host: 9202
  end

  # Elasticsearch 1.7.5
  config.vm.define "lycra-es1" do |elasticsearch|
    elasticsearch.vm.provider "docker" do |docker|
      docker.vagrant_vagrantfile = "./Vagrantfile"
      docker.vagrant_machine = "lycra"
      docker.image = "elasticsearch:1.7.5"
      docker.ports = ['9201:9200']
      docker.name = "lycra-es1"
    end
  end

  # Elasticsearch 2.2.0
  config.vm.define "lycra-es2" do |elasticsearch|
    elasticsearch.vm.provider "docker" do |docker|
      docker.vagrant_vagrantfile = "./Vagrantfile"
      docker.vagrant_machine = "lycra"
      docker.image = "elasticsearch:2.2.0"
      docker.ports = ['9202:9200']
      docker.name = "lycra-es2"
    end
  end
end
