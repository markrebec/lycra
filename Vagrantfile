# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|

  config.vm.define "lycra" do |dev|
    dev.vm.provider "virtualbox" do |virtualbox|
      virtualbox.name = "lycra-development"
      virtualbox.memory = 1024
    end
    dev.vm.box = "bento/ubuntu-14.04"
    dev.vm.hostname = "lycra-development"
    dev.vm.network :forwarded_port, guest: 5601,  host: 4501 # Kibana UI
    dev.vm.network :forwarded_port, guest: 9200,  host: 4500 # Elasticsearch API
    dev.vm.network :forwarded_port, guest: 22,    host: 4522, id: 'ssh'
    dev.vm.provision "docker"
  end

  config.vm.define "elasticsearch" do |elasticsearch|
    elasticsearch.vm.provider "docker" do |docker|
      docker.vagrant_vagrantfile = "./Vagrantfile"
      docker.vagrant_machine = "lycra"

      docker.name = "elasticsearch"
      docker.image = "elasticsearch:2.3.5"
      docker.ports = ['9200:9200', '9300:9300']
    end
  end

  config.vm.define "kibana" do |kibana|
    kibana.vm.provider "docker" do |docker|
      docker.vagrant_vagrantfile = "./Vagrantfile"
      docker.vagrant_machine = "lycra"

      docker.name = "kibana"
      docker.build_dir = "./kibana"
      docker.link "elasticsearch:elasticsearch"
      docker.ports = ['5601:5601']
      docker.volumes = ['/vagrant/kibana/config/:/opt/kibana/config/']
    end
  end

end
