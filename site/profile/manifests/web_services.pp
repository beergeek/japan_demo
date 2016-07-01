class profile::web_services {

  $lb = hiera('profile::web_services::lb',true)

  case $::kernel {
    'linux': {
      include profile::web_services::apache
    }
    'windows': {
      include profile::web_services::iis
    }
    default: {
      fail("${::kernel} is not a support OS kernel")
    }
  }

  # Export monitoring configuration
  @@nagios_service { "${::fqdn}_http":
    ensure              => present,
    use                 => 'generic-service',
    host_name           => $::fqdn,
    service_description => "HTTP",
    check_command       => 'check_http',
    target              => "/etc/nagios/conf.d/${::fqdn}_service.cfg",
    notify              => Service['nagios'],
    require             => File["/etc/nagios/conf.d/${::fqdn}_service.cfg"],
  }

}
