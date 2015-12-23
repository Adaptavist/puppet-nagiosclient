# Nagios Client Configuration
This contains the configuration for the Nagios NRPE server (the part that runs on the server)

## Configuration 

Include nagiosclient class in hiera configuration. 

This module will look for config file in order:

* nagiosclient_module/files/${client}/${environment}/etc/nagios/nrpe_local.cfg",
* nagiosclient_module/files/${client}/default/etc/nagios/nrpe_local.cfg",
* nagiosclient_module/files/default/${environment}/etc/nagios/nrpe_local.cfg
* nagiosclient_module/files/default/default/etc/nagios/nrpe_local.cfg

and use it as /etc/nagios/nrpe_local.cfg to configure nagios

### Plugins

Plugins can be installed via OS packages, this is important for RedHat systems as all plugins ship in their own package.
The Packages are specified in an arrays of package names that are the values of a hash (plugin_packages) that is keyed on the puppet `::osfamily` 
values (e.g. 'Redhat' and 'Debian').  This hash can be set at global or host level (via host hash), these hashes can either 
be merged together or the host hash can be used on its own, the merging behavior is controlled by the merge_plugins boolean 
(which can itself be set at global or host level),
A default list of plugins is installed for RedHat based systems and no additional packages are (by default) 
installed for Debian based systems, this list can be overwritten in hiera, below is an hiera example: 

* Install plugins

        nagiosclient::plugin_packages:
            'RedHat':
                - 'nagios-plugins-procs'
                - 'nagios-plugins-disk'
                - 'nagios-plugins-mysql'
                - 'nagios-plugins-swap'
            'Debian':
                - 'some-plugin'

* Install plugins and additional plugins on host3

        nagiosclient::plugin_packages:
            'RedHat':
                - 'nagios-plugins-procs'
                - 'nagios-plugins-disk'
                - 'nagios-plugins-mysql'
                - 'nagios-plugins-swap'
            'Debian':
                - 'some-plugin'
        hosts:
            'host3':
                nagiosclient::plugin_packages:
                    'RedHat':
                        - 'nagios-plugins-procs'
                        - 'nagios-plugins-disk'
                        - 'nagios-plugins-mysql'
                        - 'nagios-plugins-swap'
                        - 'nagios-plugins-apt'
                    'Debian':
                        - 'some-plugin'
                        - 'some-other-plugin'

### Custom Plugins 

Custom plugins can also be installed (currently only mysql replication checker is supported), each plugin has its own class 
and are loaded via the custom_plugins array.  This array can be set at global or host level (via host hash), these arrays can either 
be merged together or the host array can be used on its own, the merging behavior is controlled by the merge_plugins boolean 
(which can itself be set at global or host level), below are some hiera examples: 

* Install the mysql replication monitor plugin

        #install custom nagios plugins globally
        nagiosclient::custom_plugins:
            - 'mysql_replication_plugin'
        nagiosclient::mysql_replication_plugin::present: true
        
* Do not install the mysql replication monitor plugin on host3

        #install custom nagios plugins globally 
        nagiosclient::custom_plugins:
            - 'mysql_replication_plugin'
        nagiosclient::mysql_replication_plugin::present: true
        #do not install custom plugin on host3
        hosts:
            'host3':
                nagiosclient::custom_plugins: []
                nagiosclient::merge_plugins: false

