class profile::base {

  $enable_firewall = hiera('profile::base::enable_firewall')

  # monitoring
  class { 'profile::monitoring': }

  case $::kernel {
    'linux': {
      Firewall {
        before  => Class['profile::fw::post'],
        require => Class['profile::fw::pre'],
      }

      include ::profile::time_locale

      if $enable_firewall {
        class { 'firewall':
        }
        class {['profile::fw::pre','profile::fw::post']:
        }
        firewall { '100 allow ssh access':
          port   => '22',
          proto  => 'tcp',
          action => 'accept',
        }
      } else {
        class { 'firewall':
          ensure => stopped,
        }
      }

      ensure_packages(['ruby'], {'ensure' => 'present'})
    }
    'windows': {

      $wsus_server      = hiera('profile::base::wsus_server')
      $wsus_server_port = hiera('profile::base::wsus_server_port')

      if $enable_firewall {
        class { 'windows_firewall':
          ensure => 'running',
        }

        Windows_firewall::Exception {
          direction    => 'in',
          action       => 'Allow',
          enabled      => 'yes',
          protocol     => 'TCP',
          remote_port  => 'any',
        }

        windows_firewall::exception { 'PING':
          ensure       => present,
          protocol     => 'ICMPv4',
          display_name => 'PING',
          description  => 'PING',
        }
        windows_firewall::exception { 'RDP_TCP':
          ensure       => present,
          local_port   => '3389',
          display_name => 'Windows Remote Desktop TCP',
          description  => 'Inbound rule for Windows Remote Desktop',
        }
        windows_firewall::exception { 'RDP_UDP':
          ensure       => present,
          protocol     => 'UDP',
          local_port   => '3389',
          display_name => 'Windows Remote Desktop UDP',
          description  => 'Inbound rule for Windows Remote Desktop',
        }
        windows_firewall::exception { 'WINRM':
          ensure       => present,
          local_port   => '5985',
          display_name => 'Windows Remote Management HTTP-In',
          description  => 'Inbound rule for Windows Remote Management via WS-Management. [TCP 5985]',
        }
      } else {
        class { 'windows_firewall':
          ensure => 'stopped',
        }
      }

      file { ['C:/ProgramData/PuppetLabs/facter','C:/ProgramData/PuppetLabs/facter/facts.d']:
        ensure => directory,
      }

      acl { ['C:/ProgramData/PuppetLabs/facter','C:/ProgramData/PuppetLabs/facter/facts.d']:
        purge                      => false,
        permissions                => [
         { identity => 'vagrant', rights => ['full'], perm_type=> 'allow', child_types => 'all', affects => 'all' },
         { identity => 'Administrators', rights => ['full'], perm_type=> 'allow', child_types => 'all', affects => 'all'}
        ],
        owner                      => 'vagrant',
        group                      => 'Administrators',
        inherit_parent_permissions => true,
      }

      # setup wsus client
      class { 'wsus_client':
        server_url => "${wsus_server}:${wsus_server_port}",
      }
    }
  }

}
