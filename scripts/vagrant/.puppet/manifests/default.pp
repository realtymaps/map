Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ]
}

group { "puppet":
    ensure => "present",
}

include update
include curl
include git
include stdlib
include '::gnupg'
include nginx

class { 'nvm_nodejs':
  user    => 'vagrant',
  version => '0.12.6',
  npm_version => '2.12.1'
}

include rvm
#gnupg_key_id => false#, version => stable}
rvm::system_user { www-data: ; vagrant: ;}
rvm_system_ruby {
  'ruby-2.1.3':
    ensure      => 'present',
    default_use => true;
}

rvm_gem {
  'foreman':
    name         => 'foreman',
    ruby_version => 'ruby-2.1.3',
    ensure       => latest,
    require      => Rvm_system_ruby['ruby-2.1.3'];
}
