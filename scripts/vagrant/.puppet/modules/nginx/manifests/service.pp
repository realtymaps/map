service { 'nginx':
	ensure => running,
	require => Package['nginx'],
}
