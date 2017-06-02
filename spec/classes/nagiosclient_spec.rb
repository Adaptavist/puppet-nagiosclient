require 'spec_helper'

describe 'nagiosclient', :type => 'class' do

  context "Should fail for Windows and other not usable os" do
    let(:facts) {{ :osfamily => 'Windows'}}
    let(:params) { {
            :ensure => true,
    } }
    it { expect { should contain_file('/etc/nagios/nrpe_local.cfg') }.to raise_error(Puppet::Error) }
  end

  client = 'client_test'
  environment = 'environment_test'

  deb_package = 'nagios-nrpe-server'
  deb_service = 'nagios-nrpe-server'
  context "Should install package, service and config file on Debian" do
    let(:facts) {{
      :osfamily => 'Debian',
      :client => client,
    }}
    let(:environment) { environment }
    it do
      should contain_package(deb_package).with_ensure('installed')
      should contain_file('/etc/nagios/nrpe_local.cfg').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
        'source'  => ["puppet:///files/#{client}/#{environment}/etc/nagios/nrpe_local.cfg",
                   "puppet:///files/#{client}/default/etc/nagios/nrpe_local.cfg",
                   "puppet:///files/default/#{environment}/etc/nagios/nrpe_local.cfg",
                   "puppet:///files/default/default/etc/nagios/nrpe_local.cfg"],
        'require' => "Package[#{deb_package}]",
        'notify'  => "Service[#{deb_service}]"
      )
      should contain_service(deb_service).with(
        'ensure' => 'running',
        'enable' => 'true'
      )
    end
  end

  red_package = 'nrpe'
  red_service = 'nrpe'
  context "Should install package, service and config file on RedHat" do
    let(:facts) {{
      :osfamily => 'RedHat',
      :operatingsystemrelease => '6',
      :client => client,
    }}
    let(:environment) { environment }
    it do
      should contain_package(red_package).with_ensure('installed')
      should contain_package('nagios-plugins').with_ensure('installed')
      should contain_file('/etc/nrpe.d/nrpe_local.cfg').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
        'source'  => ["puppet:///files/#{client}/#{environment}/etc/nagios/nrpe_local.cfg",
                   "puppet:///files/#{client}/default/etc/nagios/nrpe_local.cfg",
                   "puppet:///files/default/#{environment}/etc/nagios/nrpe_local.cfg",
                   "puppet:///files/default/default/etc/nagios/nrpe_local.cfg"],
        'require' => "Package[#{red_package}]",
        'notify'  => "Service[#{red_service}]"
      )
      should contain_service(red_service).with(
        'ensure' => 'running',
        'enable' => 'true'
      )
    end
  end

  custom_plugins     = ['nagiosclient::mysql_replication_plugin', 'nagiosclient::postgres_plugin','nagiosclient::readonly_filesystem_plugin', 'nagiosclient::svn_replication_plugin']

  context "Should install package, service, config file and mysql replication/postgres/readonly fs/svn replication plugins on Debian" do
    let(:facts) {{
      :osfamily => 'Debian',
      :client => client,
    }}
    let(:environment) { environment }
    let(:params) {
      { :custom_plugins => custom_plugins }
    }
    it do
      should contain_package(deb_package).with_ensure('installed')
      should contain_file('/etc/nagios/nrpe_local.cfg').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
        'source'  => ["puppet:///files/#{client}/#{environment}/etc/nagios/nrpe_local.cfg",
                   "puppet:///files/#{client}/default/etc/nagios/nrpe_local.cfg",
                   "puppet:///files/default/#{environment}/etc/nagios/nrpe_local.cfg",
                   "puppet:///files/default/default/etc/nagios/nrpe_local.cfg"],
        'require' => "Package[#{deb_package}]",
        'notify'  => "Service[#{deb_service}]"
      )
      should contain_file('/usr/lib/nagios/plugins/check-mysql-slave.rb').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0755',
        'source'  => "puppet:///modules/nagiosclient/check-mysql-slave.rb"
      )
      should contain_file('/usr/lib/nagios/plugins/check-mysql-slave.sh').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0755',
      )
      should contain_file('/usr/lib/nagios/plugins/check_postgres.pl').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0755',
        'source'  => "puppet:///modules/nagiosclient/check_postgres.pl"
      )
      should contain_package('ruby-dev')
      should contain_package('libmysqlclient-dev')
      should contain_service(deb_service).with(
        'ensure' => 'running',
        'enable' => 'true'
      )
      should contain_file('/usr/lib/nagios/plugins/check-svn-replication.sh').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0755',
        'source'  => "puppet:///modules/nagiosclient/check-svn-replication.sh"
      )
      should contain_file('/usr/lib/nagios/plugins/check_ro_mounts.pl').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0755'
      )
    end
  end

  context "Should install package, service, config file and mysql replication/postgres/readonlyfs/svn replication plugins on RedHat" do
    let(:facts) {{
      :osfamily => 'RedHat',
      :operatingsystemrelease => '6',
      :client => client,
    }}
    let(:environment) { environment }
    let(:params) {
      { :custom_plugins => custom_plugins }
    }
    it do
      should contain_package(red_package).with_ensure('installed')
      should contain_package('nagios-plugins').with_ensure('installed')
      should contain_file('/etc/nrpe.d/nrpe_local.cfg').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
        'source'  => ["puppet:///files/#{client}/#{environment}/etc/nagios/nrpe_local.cfg",
                   "puppet:///files/#{client}/default/etc/nagios/nrpe_local.cfg",
                   "puppet:///files/default/#{environment}/etc/nagios/nrpe_local.cfg",
                   "puppet:///files/default/default/etc/nagios/nrpe_local.cfg"],
        'require' => "Package[#{red_package}]",
        'notify'  => "Service[#{red_service}]"
      )
      should contain_file('/usr/lib64/nagios/plugins/check-mysql-slave.rb').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0755',
        'source'  => "puppet:///modules/nagiosclient/check-mysql-slave.rb"
      )
      should contain_file('/usr/lib64/nagios/plugins/check-mysql-slave.sh').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0755',
      )
      should contain_file('/usr/lib64/nagios/plugins/check_postgres.pl').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0755',
        'source'  => "puppet:///modules/nagiosclient/check_postgres.pl"
      )

      should contain_package('ruby-devel')
      should contain_package('mysql-devel')
      should contain_service(red_service).with(
        'ensure' => 'running',
        'enable' => 'true'
      )
      should contain_file('/usr/lib64/nagios/plugins/check-svn-replication.sh').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0755',
        'source'  => "puppet:///modules/nagiosclient/check-svn-replication.sh"
      )
      should contain_file('/usr/lib64/nagios/plugins/check_ro_mounts.pl').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0755'
      )
    end
  end

  host_custom_plugins     = {
      'nagiosclient::custom_plugins' => [],
      'nagiosclient::merge_plugins' => false
  }
  context "mysql replication plugin should be disabled at host level" do
    let(:facts) {{
      :osfamily => 'Debian',
      :client => client,
      :host => host_custom_plugins,
    }}
    let(:environment) { environment }
    let(:params) {
      { :custom_plugins => custom_plugins }
    }
    it do
      should contain_package(deb_package).with_ensure('installed')
      should contain_file('/etc/nagios/nrpe_local.cfg').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
        'source'  => ["puppet:///files/#{client}/#{environment}/etc/nagios/nrpe_local.cfg",
                   "puppet:///files/#{client}/default/etc/nagios/nrpe_local.cfg",
                   "puppet:///files/default/#{environment}/etc/nagios/nrpe_local.cfg",
                   "puppet:///files/default/default/etc/nagios/nrpe_local.cfg"],
        'require' => "Package[#{deb_package}]",
        'notify'  => "Service[#{deb_service}]"
      )
      should_not contain_file('/usr/lib/nagios/plugins/check-mysql-slave.rb')
      should_not contain_file('/usr/lib/nagios/plugins/check-mysql-slave.sh')
      should_not contain_file('/usr/lib/nagios/plugins/check_postgres.pl')
      should_not contain_package('ruby-dev')
      should_not contain_package('libmysqlclient-dev')
      should contain_service(deb_service).with(
        'ensure' => 'running',
        'enable' => 'true'
      )
    end
  end

  red_plugin_packages     = {
      'RedHat' => ['nagios-plugins-apt']
  }
  context "Should install package, service, config file and plugin packages on RedHat" do
    let(:facts) {{
      :osfamily => 'RedHat',
      :operatingsystemrelease => '6',
      :client => client,
    }}
    let(:environment) { environment }
    let(:params) {
      { :plugin_packages => red_plugin_packages }
    }
    it do
      should contain_package(red_package).with_ensure('installed')
      should contain_package('nagios-plugins').with_ensure('installed')
      should contain_package('nagios-plugins-apt').with_ensure('installed')
      should_not contain_package('nagios-plugins-mysql')
      should contain_file('/etc/nrpe.d/nrpe_local.cfg').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
        'source'  => ["puppet:///files/#{client}/#{environment}/etc/nagios/nrpe_local.cfg",
                   "puppet:///files/#{client}/default/etc/nagios/nrpe_local.cfg",
                   "puppet:///files/default/#{environment}/etc/nagios/nrpe_local.cfg",
                   "puppet:///files/default/default/etc/nagios/nrpe_local.cfg"],
        'require' => "Package[#{red_package}]",
        'notify'  => "Service[#{red_service}]"
      )
      should contain_service(red_service).with(
        'ensure' => 'running',
        'enable' => 'true'
      )
    end
  end

  context "Should fail with unsupported OS family" do
    let(:facts) {{ :osfamily => 'Solaris' }}

    it do
      should raise_error(Puppet::Error, /nagiosclient - Unsupported Operating System family: Solaris at/)
    end
  end


end
