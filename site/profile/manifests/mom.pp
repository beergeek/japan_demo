class profile::mom {

  $enable_firewall      = hiera('profile::mom::enable_firewall',true)

  Firewall {
    proto  => tcp,
    action => accept,
    before  => Class['profile::fw::post'],
    require => Class['profile::fw::pre'],
  }

  file { '/opt/iis_files':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    before => Augeas['iis_file_path'],
  }

  augeas { 'iis_file_path':
    context => "/files/${::settings::fileserverconfig}/iis_files",
    changes => [
      "set path /opt/iis_files",
      'set allow *'
    ],
    notify => Service['pe-puppetserver'],
  }

  if $enable_firewall {
    firewall { '100 allow puppet access':
      port   => [8140],
    }

    firewall { '100 allow pcp access':
      port   => [8142],
    }

    firewall { '100 allow pcp client access':
      port   => [8143],
    }

    firewall { '100 allow mco access':
      port   => [61613],
    }

    firewall { '100 allow amq access':
      port   => [61616],
    }

    firewall { '100 allow console access':
      port   => [443],
    }

    firewall { '100 allow nc access':
      port   => [4433],
    }

    firewall { '100 allow puppetdb access':
      port   => [8081],
    }
  }

  @@nagios_service { "${::fqdn}_puppet":
    ensure              => present,
    use                 => 'generic-service',
    host_name           => $::fqdn,
    service_description => "Puppet Master",
    check_command       => 'check_http! -p 8140 -S -u /production/node/test',
    target              => "/etc/nagios/conf.d/${::fqdn}_service.cfg",
    notify              => Service['nagios'],
    require             => File["/etc/nagios/conf.d/${::fqdn}_service.cfg"],
  }


}
