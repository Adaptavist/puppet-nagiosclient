class nagiosclient::params {

    # defaults for init
    $custom_plugins = ['nagiosclient::readonly_filesystem_plugin', 'nagiosclient::kernel_check_plugin']
    $merge_plugins  = true
    $plugin_packages = {
        'Debian' => [],
        'RedHat' => ['nagios-plugins-procs','nagios-plugins-disk','nagios-plugins-mysql',
                     'nagios-plugins-swap', 'nagios-plugins-load', 'nagios-plugins-users',
                     'nagios-plugins-file_age']
    }
    $nrpe_source  = ["puppet:///files/${client}/${environment}/etc/nagios/nrpe_local.cfg",
                     "puppet:///files/${client}/default/etc/nagios/nrpe_local.cfg",
                     "puppet:///files/default/${environment}/etc/nagios/nrpe_local.cfg",
                     'puppet:///files/default/default/etc/nagios/nrpe_local.cfg']
    case $::osfamily {
        'Debian': {
            $nrpePackageName = 'nagios-nrpe-server'
            $nrpeServiceName = 'nagios-nrpe-server'
            $masterPluginPackage = ''
            $nrpe_config_file = '/etc/nagios/nrpe_local.cfg'
            $semanage_package = 'policycoreutils-python'
        }
        'RedHat': {
            $nrpePackageName = 'nrpe'
            $nrpeServiceName = 'nrpe'
            $masterPluginPackage = 'nagios-plugins'
            $nrpe_config_file = '/etc/nrpe.d/nrpe_local.cfg'
            $semanage_package = 'policycoreutils'
        }
        default: {
            fail("nagiosclient - Unsupported Operating System family: ${::osfamily}")
        }
    }

    # defaults for all plugin classes
    $plugin_present = true
    case $::osfamily {
        'Debian': {
            $plugin_path = '/usr/lib/nagios/plugins'
            $plugin_file_deps = Package['nagios-nrpe-server']
            $nrpe_commands = {}
        }
        'RedHat': {
            $plugin_path = '/usr/lib64/nagios/plugins'
            $plugin_file_deps = [Package['nagios-plugins'], Package['nrpe']]
            $nrpe_commands = {
                'check_load' => {
                    command => "${plugin_path}/check_load -w 15,10,5 -c 30,25,20",
                    file => '/etc/nagios/nrpe.cfg',
                    ensure => 'present'
                }
            }
        }
        default: {
            fail("nagiosclient - Unsupported Operating System family: ${::osfamily}")
        }
    }

    # defaults for mysql_replicaiton plugin
    $mysql_rep_mysql_gem_package = 'mysql2'
    case $::osfamily {
        'Debian': {
            $mysql_rep_plugin_ruby_dev_package = 'ruby-dev'
            $mysql_rep_mysql_dev_package = 'libmysqlclient-dev'
        }
        'RedHat': {
            $mysql_rep_plugin_ruby_dev_package = 'ruby-devel'
            if (versioncmp($::operatingsystemrelease,'7') >= 0 and $::operatingsystem != 'Fedora') {
                $mysql_rep_mysql_dev_package = 'mysql-community-devel'
            } else {
                $mysql_rep_mysql_dev_package = 'mysql-devel'
            }
        }
        default: {
            fail("nagiosclient - Unsupported Operating System family: ${::osfamily}")
        }
    }

    # defaults for readonly_fs plugin
    case $::osfamily {
        'Debian': {
            $readonly_fs_nagios_perl_package = false
        }
        'RedHat': {
            $readonly_fs_nagios_perl_package = 'nagios-plugins-perl'
        }
        default: {
            fail("nagiosclient - Unsupported Operating System family: ${::osfamily}")
        }
    }
}