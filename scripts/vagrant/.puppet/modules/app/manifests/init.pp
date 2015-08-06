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

  exec { 'kill-app':
    command     => 'pidof ruby; echo 0',
    user        => $user
  }

  exec { 'run-app':
    command     => 'rm -f vagrant_app.log; foreman run scripts/runDev --mayday --bare-server --install >> vagrant_app.log &',
    cwd         => '/vagrant',
    user        => $user,
    environment => [ "HOME=${home}" ],
    logoutput   => true,
    require     => Exec['kill-app']
  }

}
