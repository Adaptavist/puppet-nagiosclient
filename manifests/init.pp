class nagiosclient  (
    $custom_plugins      = $nagiosclient::params::custom_plugins,
    $merge_plugins       = $nagiosclient::params::merge_plugins,
    $plugin_packages     = $nagiosclient::params::plugin_packages,
    $nrpe_config_file    = $nagiosclient::params::nrpe_config_file,
    $nrpe_source         = $nagiosclient::params::nrpe_source,
    $packageName         = $nagiosclient::params::nrpePackageName,
    $serviceName         = $nagiosclient::params::nrpeServiceName,
    $masterPluginPackage = $nagiosclient::params::masterPluginPackage,
    $semanage_package    = $nagiosclient::params::semanage_package,
    ) inherits nagiosclient::params {

    #custom_plugins can be set at either global or host level, therefore check to see if the hosts hash exists
    if ($host != undef) {

        validate_hash($host)

        #if a host level "merge_plugins" flag has been set use it, otherwise use the global flag
        $merge_plugins_hashes = $host["${name}::merge_plugins"] ? {
            default => $host["${name}::merge_plugins"],
            undef   => $merge_plugins
        }

        #if there are host level custom plugins
        if ($host["${name}::custom_plugins"] != undef) {
            #and we have merging enabled merge global and host
            if ($merge_plugins_hashes) {
                #$custom_plugins_list = merge($custom_plugins, $host["${name}::custom_plugins"])
                $array_merge = [$custom_plugins, $host["${name}::custom_plugins"]]
                $custom_plugins_list = unique(flatten($array_merge))
            } else {
                $custom_plugins_list = $host["${name}::custom_plugins"]
            }
        }
        #if there are no host level plugins just use globals
        else {
            $custom_plugins_list = $custom_plugins
        }

        #if there are host level plugins
        if ($host["${name}::plugin_packages"] != undef) {
            #and we have merging enabled merge global and host
            if ($merge_plugins_hashes) {
                $plugin_packages_list = merge($plugin_packages, $host["${name}::plugin_packages"])
            } else {
                $plugin_packages_list = $host["${name}::plugin_packages"]
            }
        }
        #if there are no host level plugins just use globals
        else {
            $plugin_packages_list = $plugin_packages
        }
    }
    #if there is no host has use global values
    else {
        $custom_plugins_list = $custom_plugins
        $plugin_packages_list = $plugin_packages
    }

    package { $packageName:
        ensure => 'installed',
    }

    # if this is a RedHat system we need at least the "nagios-plugins" package as well as the main nrpe package
    if ( $::osfamily == 'RedHat') {
        package { $masterPluginPackage:
            ensure  => 'installed',
            require => Package[$packageName]
        }
    }

    file { $nrpe_config_file:
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => $nrpe_source,
        require => Package[$packageName],
        notify  => Service[$serviceName],
    }

    # if we have a list of plugins to install include the classes that will do the work
    if ($custom_plugins_list) {
        # if selinxu is enabled ensure the semanage package in installed
        if (str2bool($::selinux) and ! defined(Package[$semanage_package]) ) {
            ensure_packages([$semanage_package])
        }

        validate_array($custom_plugins_list)
        include $custom_plugins_list
    }

    # install any plugin packages that are needed, this is important for RedHat systems as all plugins
    # ship in their own package
    if ( $plugin_packages_list[$::osfamily] != undef ) {
        package { $plugin_packages_list[$::osfamily]:
            ensure  => installed,
            require => Package[$packageName]
        }
    }

    service { $serviceName:
        ensure => 'running',
        enable => true,
    }
}
