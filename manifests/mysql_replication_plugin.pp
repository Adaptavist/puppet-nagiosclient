class nagiosclient::mysql_replication_plugin (
    $present           = $nagiosclient::params::plugin_present,
    $file_deps         = $nagiosclient::params::plugin_file_deps,
    $plugin_path       = $nagiosclient::params::plugin_path,
    $ruby_dev_package  = $nagiosclient::params::mysql_rep_plugin_ruby_dev_package,
    $mysql_dev_package = $nagiosclient::params::mysql_rep_mysql_dev_package,
    $semanage_package    = $nagiosclient::params::semanage_package,
    ) inherits nagiosclient::params {

    if ($present == true) {
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
        # if selinux is enabled, restore default contexts to plugin directory
        if (str2bool($::selinux)) {
            exec { 'mysql_replication_plugin_selinux_context':
                command => "restorecon -R -v ${plugin_path}",
                require => [Package[$semanage_package],File["${plugin_path}/check-mysql-slave.rb"],File["${plugin_path}/check-mysql-slave.sh"]],
            }
        }
    }
}
