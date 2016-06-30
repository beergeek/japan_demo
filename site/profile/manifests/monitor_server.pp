class profile::monitor_server {

  if $::osfamily != 'redhat' {
    fail("This class is only for EL family")
  }

  require profile::base
  include apache
  include epel
  package { ['nagios','nagios-plugins','nagios-plugins-all']:
    ensure  => present,
    require => Class['epel'],
  }

  file { '/etc/nagios/conf.d':
    ensure  => absent,
    owner   => 'nagios',
    group   => 'nagios',
    mode    => '0755',
    purge   => true,
    force   => false,
    recurse => true,
    require => Package['nagios'],
  }

  # apache config for nagios
  file { '/etc/httpd/conf.d/nagios.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/nagios.conf.erb'),
    require => Package['nagios'],
  }

  service { 'nagios':
    ensure    => running,
    enable    => true,
    subscribe => File['/etc/httpd/conf.d/nagios.conf'],
  }

  File <<| tag == 'Monitoring' |>>
  Nagios_host <<||>>
  Nagios_service <<||>>

}
