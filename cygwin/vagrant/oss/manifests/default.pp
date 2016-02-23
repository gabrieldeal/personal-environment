# https://www.vagrantup.com/docs/provisioning/puppet_apply.html

include '::mysql::server'

# https://forge.puppetlabs.com/maestrodev/rvm
class { 'rvm': }
rvm::system_user {
  vagrant: ;
}

package { 'emacs24':
  ensure => 'installed'
}

package { 'git':
  ensure => 'installed'
}
