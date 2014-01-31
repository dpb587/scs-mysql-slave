class scs (
    $serverid,
    $super_username,
    $super_password,
    $master_username,
    $master_password,
    $replicate = [],
    $mysqld_options = {},
) {
    group {
        'scs' :
            ensure => present,
            gid => 1010,
            ;
    }

    user {
        'scs' :
            ensure => present,
            gid => 1010,
            shell => '/bin/false',
            uid => 1010,
            require => [
                Group['scs'],
            ],
            ;
    }

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
        '/usr/bin/easy_install supervisor' :
            creates => '/usr/bin/supervisord',
            require => [
                Package['python-setuptools'],
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

        "/scs/bin" :
            ensure => directory,
            ;
        "/scs/bin/update-requires-master" :
            ensure => file,
            content => template('scs/mysqld/update-requires-master.sh.erb'),
            mode => 500,
            ;

        "/scs/etc" :
            ensure => directory,
            ;
        "/scs/etc/supervisor.conf" :
            ensure => file,
            content => template('scs/supervisor/supervisor.conf.erb'),
            ;
        "/scs/etc/supervisor.d" :
            ensure => directory,
            ;
        "/scs/var" :
            ensure => directory,
            ;
        "/scs/var/log" :
            ensure => directory,
            ;
        "/scs/var/log/supervisord" :
            ensure => directory,
            ;
        "/scs/var/run" :
            ensure => directory,
            ;
        "/scs/var/run/supervisord" :
            ensure => directory,
            ;

        "/scs/etc/mysqld" :
            ensure => directory,
            ;
        "/scs/etc/mysqld/mysqld.ini" :
            ensure => file,
            content => template('scs/mysqld/mysqld.ini.erb'),
            ;
        "/scs/etc/supervisor.d/mysqld.conf" :
            ensure => file,
            content => template('scs/mysqld/supervisor.conf.erb'),
            ;
        "/scs/var/log/mysqld" :
            ensure => directory,
            owner => 'scs',
            group => 'scs',
            ;
        "/scs/var/run/mysqld" :
            ensure => directory,
            owner => 'scs',
            group => 'scs',
            ;
        '/var/run/mysqld/mysqld.sock' :
            backup => false,
            ensure => link,
            target => '/scs/var/run/mysqld/mysqld.sock',
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
        'python-setuptools' :
            ensure => installed,
            require => [
                Exec['apt-update'],
            ],
            ;
    }
}
