class nagiosclient::postgres_plugin (
    $present = true
    )  {

    if ($present == true) {
        # set OS specific variables
        case $::osfamily {
            Debian: {
                $plugin_path = '/usr/lib/nagios/plugins'
                $file_deps = Package['nagios-nrpe-server']
            }
            RedHat: {
                $plugin_path = '/usr/lib64/nagios/plugins'
                $file_deps = [Package['nagios-plugins'], Package['nrpe']]
            }
            default: {
                fail("nagiosclient::postgres_plugin - Unsupported Operating System family: ${::osfamily}")
            }
        }
        # create plugin script
        file { "${plugin_path}/check_postgres.pl":
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            source  => 'puppet:///modules/nagiosclient/check_postgres.pl',
            require => $file_deps
        }
    }
}
