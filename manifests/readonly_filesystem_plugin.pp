class nagiosclient::readonly_filesystem_plugin (
    $present           = $nagiosclient::params::plugin_present,
    $file_deps         = $nagiosclient::params::plugin_file_deps,
    $plugin_path       = $nagiosclient::params::plugin_path,
    ) inherits nagiosclient::params {

    if ($present == true) {
        # create plugin script
        file { "${plugin_path}/check_ro_mounts.pl":
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            source  => 'puppet:///modules/nagiosclient/check_ro_mounts.pl',
            require => $file_deps
        }
    }
}