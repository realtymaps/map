class nginx {

  require update

  file {
    '/etc/nginx/nginx.conf':
      source => 'puppet:///modules/nginx/nginx.conf',
      owner  => root,
      group  => root,
      mode   => '0644',
      notify => Service[nginx]
  }

  file {
    '/etc/apt/sources.list.d/nginx.list':
      source => 'puppet:///modules/nginx/nginx.list',
      owner  => root,
      group  => root,
      mode   => '0644',
      notify => Service[nginx]
  }

  file {
    '/etc/init.d/nginx':
      source => 'puppet:///modules/nginx/nginx',
      owner  => root,
      group  => root,
      mode   => '0755',
  }

  exec { 'get-nginx-keys':
    command     => 'wget http://nginx.org/keys/nginx_signing.key && apt-key add nginx_signing.key',
  }

  exec { 'install-nginx':
    command => 'apt-get update && apt-get install nginx',
    require => Exec['get-nginx-keys']
  }

  service { 'nginx':
  	ensure => running,
    enable   => true,
    hasstatus  => true,
    require  => File['/etc/nginx/nginx.conf'],
    hasrestart => true
  }

  Exec['get-nginx-keys'] ->
    File['/etc/apt/sources.list.d/nginx.list'] ->

  Exec['install-nginx'] ->
    File['/etc/nginx/nginx.conf'] ->
    File['/etc/init.d/nginx'] ->
    Service[nginx]

}
