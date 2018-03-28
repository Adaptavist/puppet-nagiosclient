class nagiosclient::kernel_check_plugin (
    $present             = $nagiosclient::params::plugin_present,
    $file_deps           = $nagiosclient::params::plugin_file_deps,
    $plugin_path         = $nagiosclient::params::plugin_path,
    $semanage_package    = $nagiosclient::params::semanage_package,
    ) inherits nagiosclient::params {

    if ($present == true) {
        # create plugin script
        file { "${plugin_path}/check-installed-kernel.sh":
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            source  => 'puppet:///modules/nagiosclient/check-installed-kernel.sh',
            require => $file_deps,
        }

        # if selinux is enabled, restore default contexts to plugin directory
        if (str2bool($::selinux)) {
            exec { 'readonly_filesystem_plugin_selinux_context':
                command => "restorecon -R -v ${plugin_path}",
                require => [Package[$semanage_package],File["${plugin_path}/check-installed-kernel.sh"]],
            }
        }

    }
}