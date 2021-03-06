class profile::web_services::apache {

  $website_hash 	    = hiera('profile::web_services::apache::website_hash',undef)
  $website_defaults 	= hiera('profile::web_services::apache::website_defaults')
  $enable_firewall    = hiera('profile::web_services::apache::enable_firewall')
  $repo_provider      = hiera('profile::web_services::apache::repo_provider', undef)
  $lb                 = hiera('profile::web_services::apache::lb',true)

  include ::apache
  include ::apache::mod::php
  include ::apache::mod::ssl
  include app_update

  if $enable_firewall {
    # add firewall rules
    firewall { '100 allow http and https access':
      port   => [80, 443],
      proto  => tcp,
      action => accept,
    }
  }

  if $repo_provider == 'git' {
    ensure_packages(['git'])

    Vcsrepo {
      require => Package['git'],
    }
  }

  if $website_hash {
    $website_hash.each |String $site_name, Hash $website| {
      if $website['database_search'] {
        $search_results = query_resources("Class['mysql::server']", $website['database_search'])
      } else {
        $_bypass = true
      }
      if $_bypass or !(empty($search_results)) {
        $_docroot = "/var/www/${website['docroot']}"

        if $::os['family'] == 'RedHat' and $::os['release']['major'] == '7' {
          $port = 'enp0s8'
        } else {
          $port = 'eth1'
        }

        host { $site_name:
          ensure => present,
          ip     => $::networking['interfaces'][$port]['ip'],
        }

        # Export monitoring configuration
        @@nagios_service { "${::fqdn}_http_${site_name}":
          ensure              => present,
          use                 => 'generic-service',
          host_name           => $::fqdn,
          service_description => "${::fqdn}_http_${site_name}",
          check_command       => "check_http!${site_name} -I ${networking['interfaces']['Ethernet 2']['ip']} -p ${website['port']} -u http://${site_name}",
          target              => "/etc/nagios/conf.d/${::fqdn}_service.cfg",
          notify              => Service['nagios'],
          require             => File["/etc/nagios/conf.d/${::fqdn}_service.cfg"],
        }

        apache::vhost { $site_name:
          docroot        => $_docroot,
          manage_docroot => $website['manage_docroot'],
          port           => $website['port'],
          priority       => $website['priority'],
        }

        if $website['repo_source'] {
          vcsrepo { $site_name:
            ensure   => present,
            path     => $_docroot,
            provider => $website['repo_provider'],
            source   => $website['repo_source'],
            require  => Apache::Vhost[$site_name],
          }
        } elsif $website['site_package'] {
          package { $website['site_package']:
            ensure => present,
            tag    => 'custom',
          }
        }
        # Exported load balancer configuration if required
        if $lb {
          @@haproxy::balancermember { "${site_name}-${::fqdn}":
            listening_service => $site_name,
            server_names      => $::fqdn,
            ipaddresses       => $::ipaddress_eth1,
            ports             => $website['port'],
            options           => 'check',
          }
        }
      }
    }
  }
}
