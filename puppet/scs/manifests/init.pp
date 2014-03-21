class scs (
    $serverid,
    $super_username,
    $super_password,
    $master_username,
    $master_password,
    $replicate = [],
    $mysqld_options = {},
) {
    exec {
        'apt-source:percona:key' :
            command => '/usr/bin/apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1C4CBDCDCD2EFD2A',
            ;
        'apt-source:percona' :
            command => '/bin/echo "deb http://repo.percona.com/apt precise main" >> /etc/apt/sources.list',
            unless => '/bin/grep "deb http://repo.percona.com/apt precise main" /etc/apt/sources.list',
            require => [
                Exec['apt-source:percona:key'],
            ],
            ;
        'apt-update' :
            command => '/usr/bin/apt-get update',
            require => [
                Exec['apt-source:percona'],
            ],
            ;
    }

    file {
        "/root/.my.cnf" :
            ensure => file,
            content => template('scs/mysqld/my.cnf.erb'),
            mode => 0400,
            ;
        "/root/.mysql_history" :
            ensure => link,
            target => '/dev/null',
            ;

        '/usr/bin/scs-runtime-hook-start' :
            ensure => file,
            source => 'puppet:///modules/scs/scs-runtime-hook-start',
            owner => root,
            group => root,
            mode => 0755,
            ;
        "/usr/bin/scs-liveupdate-mysql" :
            ensure => file,
            content => template('scs/mysqld/liveupdate-mysql.erb'),
            mode => 500,
            ;
        '/usr/bin/scs-supervisor-mysqld-postload' :
            ensure => file,
            source => 'puppet:///modules/scs/scs-supervisor-mysqld-postload',
            owner => root,
            group => root,
            mode => 0755,
            ;
        '/usr/bin/scs-util-mysqld-status' :
            ensure => file,
            source => 'puppet:///modules/scs/scs-util-mysqld-status',
            owner => root,
            group => root,
            mode => 0755,
            ;

        "/etc/mysqld" :
            ensure => directory,
            ;
        "/etc/mysqld/mysqld.ini" :
            ensure => file,
            content => template('scs/mysqld/mysqld.ini.erb'),
            ;
        "/etc/supervisor.d/mysqld.conf" :
            ensure => file,
            content => template('scs/mysqld/supervisor.conf.erb'),
            ;
        "/etc/supervisor.d/mysqld-postload.conf" :
            ensure => file,
            content => template('scs/mysqld/supervisor-postload.conf.erb'),
            ;
        "/var/log/mysqld" :
            ensure => directory,
            owner => 'scs',
            group => 'scs',
            require => [
                Package['percona-server-server-5.6'],
            ],
            ;
        "/var/run/mysqld" :
            ensure => directory,
            owner => 'scs',
            group => 'scs',
            require => [
                Package['percona-server-server-5.6'],
            ],
            ;
    }

    package {
        'percona-server-server-5.6' :
            ensure => installed,
            require => [
                Exec['apt-source:percona'],
                Exec['apt-update'],
            ],
            ;
    }
}
