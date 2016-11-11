class nagiosclient::readonly_filesystem_plugin (
    $present             = $nagiosclient::params::plugin_present,
    $file_deps           = $nagiosclient::params::plugin_file_deps,
    $plugin_path         = $nagiosclient::params::plugin_path,
    $nagios_perl_package = $nagiosclient::params::readonly_fs_nagios_perl_package,
    $semanage_package    = $nagiosclient::params::semanage_package,
    ) inherits nagiosclient::params {

    if ($present == true) {
        # install nagios_perl_pacakge if required
        if ($nagios_perl_package != false and $nagios_perl_package != 'false') {
            package { $nagios_perl_package:
                ensure      => installed,
            }
        }

        # create plugin script
        file { "${plugin_path}/check_ro_mounts.pl":
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            content => template("${module_name}/check_ro_mounts.pl.erb"),
            require => $file_deps
        }

        # if selinux is enabled, restore default contexts to plugin directory
        if (str2bool($::selinux)) {
            exec { 'readonly_filesystem_plugin_selinux_context':
                command => "restorecon -R -v ${plugin_path}",
                require => [Package[$semanage_package],File["${plugin_path}/check_ro_mounts.pl"]],
            }
        }

    }
}