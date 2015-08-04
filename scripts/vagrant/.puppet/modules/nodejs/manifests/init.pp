class nodejs {

  exec { 'nvm-install':
    command => "curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.25.4/install.sh | /bin/sh",
    user => "vagrant",
    group => "vagrant",
    creates => '/home/vagrant/.nvm',
    require => Class['curl'],
  }

  exec { 'node-install':
		command => '/bin/bash -c "source /home/vagrant/.nvm/nvm.sh && nvm install 0.12.6 && nvm alias default 0.12.6"',
		user => 'vagrant',
		environment => 'HOME=/home/vagrant',
		require => Exec['nvm-install']
	}
}
