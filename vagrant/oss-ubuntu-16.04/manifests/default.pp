# https://www.vagrantup.com/docs/provisioning/puppet_apply.html

include '::mysql::server'
mysql::db { 'officespace_development':
  user => 'vagrant',
  password => '',
  host => 'localhost',
  grant => ['ALL', 'SUPER'],
}
mysql::db { 'officespace_test':
  user => 'vagrant',
  password => '',
  host => 'localhost',
  grant => ['ALL', 'SUPER'],
}

class { '::phantomjs':
  package_version => '2.1.1',
  package_update => true,
  install_dir => '/usr/local/bin',
  source_dir => '/opt',
  timeout => 300
}

# https://forge.puppetlabs.com/maestrodev/rvm
class { 'rvm': }
rvm::system_user {
  vagrant: ;
}
rvm_system_ruby {
  'ruby-2.3.1':
    ensure      => 'present',
    default_use => true;
}
rvm_gem {
  'bundler':
    name => 'bundler',
    ruby_version => 'ruby-2.3.1',
    ensure => latest,
    require => Rvm_system_ruby['ruby-2.3.1'];
}

# This makes sure we update our package list before installing any
# package:
exec { "apt-update":
  command => "/usr/bin/apt-get update"
}
Exec["apt-update"] -> Package <| |>

# Want to build emacs from source.
package { 'emacs24':
  ensure => 'absent'
}

package { 'libcurl4-openssl-dev':
  ensure => 'installed'
}

package { 'imagemagick':
  ensure => 'installed'
}

package { 'xauth':
  ensure => 'installed'
}

package { 'git':
  ensure => 'installed'
}

package { 'libmysqlclient-dev':
  ensure => 'installed'
}

package { 'nodejs':
  ensure => 'installed'
}

package { 'nodejs-legacy':
  ensure => 'installed'
}

package { 'npm':
  ensure => 'installed'
}

package { 'libgeos-dev':
  ensure => 'installed'
}

class { 'redis':;
}
