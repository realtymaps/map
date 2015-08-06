class app (
  $user,
  $ruby_version,
  $node_version,
  $home = "/home/${user}",

) {

  Exec {
    path => [
       "/home/vagrant/.nvm/versions/node/v${node_version}/bin",
       "/usr/local/rvm/gems/${ruby_version}/bin",
       "/usr/local/rvm/gems/${ruby_version}@global/bin:/usr/local/rvm/rubies//${ruby_version}/bin",
       '/usr/local/rvm/bin',
       '/opt/vagrant_ruby/bin',
       '/usr/local/bin',
       '/usr/bin',
       '/usr/sbin',
       '/bin',
       '/sbin',
    ],
    logoutput => on_failure,
  }

  exec { 'run-app':
    command     => 'foreman run scripts/runDev --mayday --bare-server --install &',
    cwd         => '/vagrant',
    user        => $user,
    environment => [ "HOME=${home}" ],
    logoutput => true,
  }

}
