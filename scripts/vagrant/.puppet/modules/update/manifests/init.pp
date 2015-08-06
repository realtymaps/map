class update {

    exec { 'apt-get update':
        command => 'apt-get update -y',
    }

    $sysPackages = ['build-essential', 'make', 'wget']
    package { $sysPackages:
        ensure => 'installed',
        require => Exec['apt-get update'],
    }

}
