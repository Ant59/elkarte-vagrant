ENV["LC_ALL"] = "en_GB.UTF-8"

unless Vagrant.has_plugin?("vagrant-hostmanager")
  raise "vagrant-hostmanager plugin is missing. Install with 'vagrant plugin install vagrant-hostmanager'"
end

Vagrant.configure("2") do |config|

	# Specify the base box
	config.vm.box = "ubuntu/trusty32"

	# Automatically update hosts file
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true

	# Setup network
  config.vm.hostname = "elkarte.dev"
  config.vm.network "private_network", ip: "192.168.56.101", netmask: "255.255.255.0"

	# Sync provisioning files
	config.vm.synced_folder ".", "/vagrant", type: "rsync"

  # Setup synced folder
  config.vm.synced_folder "./Elkarte", "/var/www", type: "rsync",
      rsync__exclude: [".git/", "install/", "Settings.php"],
      rsync__auto: true,
      group: "www-data", owner: "www-data"

  # VM specific configs
  config.vm.provider "virtualbox" do |v|
  	v.name = "Elkarte"
  	v.customize ["modifyvm", :id, "--memory", "1024"]
  end

  # Shell provisioning
  config.vm.provision "shell" do |s|
  	s.path = "provision/setup.sh"
  end

end
