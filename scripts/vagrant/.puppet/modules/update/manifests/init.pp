class update {

    exec { 'apt-get update':
        command => 'apt-get update -y',
    }

    $sysPackages = ['build-essential', 'wget', 'vim', 'git', 'curl']
    package { $sysPackages:
        ensure => 'installed',
        require => Exec['apt-get update'],
    }

}
