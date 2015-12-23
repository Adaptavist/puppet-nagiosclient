class nagiosclient::mysql_replication_plugin (
    $present = true
    )  {

    if ($present == true) {
        # set OS specific variables
        case $::osfamily {
            Debian: {
                $ruby_dev_package = 'ruby-dev'
                $mysql_dev_package = 'libmysqlclient-dev'
                $plugin_path = '/usr/lib/nagios/plugins'
                $file_deps = Package['nagios-nrpe-server']
            }
            RedHat: {
                $ruby_dev_package = 'ruby-devel'
                if (versioncmp($::operatingsystemrelease,'7') >= 0 and $::operatingsystem != 'Fedora') {
                    $mysql_dev_package = 'mysql-community-devel'
                } else {
                    $mysql_dev_package = 'mysql-devel'
                }
                $plugin_path = '/usr/lib64/nagios/plugins'
                $file_deps = [Package['nagios-plugins'], Package['nrpe']]
            }
            default: {
                fail("nagiosclient::mysql_replication_plugin - Unsupported Operating System family: ${::osfamily}")
            }
        }
        # create plugin script
        file { "${plugin_path}/check-mysql-slave.rb":
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            source  => 'puppet:///modules/nagiosclient/check-mysql-slave.rb',
            require => $file_deps
        }
        # create plugin launcher
        file { "${plugin_path}/check-mysql-slave.sh":
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            content => template("${module_name}/check-mysql-slave.sh.erb"),
            require => $file_deps
        }
        # install mysql development package as its needed by the mysql gem
        package { $mysql_dev_package:
            ensure      => installed,
        }
        # install ruby development package as its needed by the mysql gem
        package { $ruby_dev_package:
            ensure      => installed,
        }
        # install the mysql gem
        package { 'mysql':
            ensure   => installed,
            provider => gem,
            require  => [Package[$ruby_dev_package], Package[$mysql_dev_package]]
        }
    }
}
