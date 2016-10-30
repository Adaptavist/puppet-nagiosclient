require 'rubygems'
require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint'

PuppetLint.configuration.send('disable_variable_scope')
PuppetLint.configuration.send('disable_puppet_url_without_modules')
PuppetLint.configuration.send('disable_2sp_soft_tabs')
PuppetLint.configuration.send('disable_quoted_booleans')
PuppetLint.configuration.send('disable_variable_is_lowercase')
PuppetLint.configuration.send('disable_140chars')

task :default => [:spec, :lint]