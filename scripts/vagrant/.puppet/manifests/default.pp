Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ]
}

group { "puppet":
    ensure => "present",
}

$node_version = '0.12.6'
$ruby_version = 'ruby-2.1.3'

include update
include stdlib
include '::gnupg'
include nginx

#RVM
rvm_system_ruby {
  $ruby_version:
    ensure      => 'present',
    default_use => true;
}->
rvm_gem {
  'foreman':
    name         => 'foreman',
    ruby_version => $ruby_version,
    ensure       => latest,
    require      => Rvm_system_ruby[$ruby_version];
}->
class { 'nvm_nodejs':#NODE
  user    => 'vagrant',
  version => '0.12.6',
  npm_version => '2.12.1'
}->
class { 'rvm':
  system_users => ['www-data','vagrant'], #FOR SOME CRAZY reason I canot set the order(->||~>) of this as it fucks it up
}->
class { 'app':#RUN REALTYMAPS APP
  user    => 'vagrant',
  node_version => $node_version,
  ruby_version =>  $ruby_version
}
