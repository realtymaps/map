class nginx {

  require update

  package {
    'nginx': ensure => installed;
  }

  file {
    '/etc/nginx/nginx.conf':
      source => 'puppet:///modules/nginx/nginx.conf',
      owner  => root,
      group  => root,
      mode   => '0644',
      notify => Service[nginx]
  }

  service { 'nginx':
  	ensure => running,
    enable     => true,
    # hasstatus  => true,
    require    => File['/etc/nginx/nginx.conf'],
    restart    => '/etc/init.d/nginx reload',
    hasrestart => true
  }

  Package[nginx] ->
    File['/etc/nginx/nginx.conf'] ->
    Service[nginx]

}
