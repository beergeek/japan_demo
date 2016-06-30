class profile::app_services {

  case $::kernel {
    'Linux': {
      include profile::app_services::tomcat
    }
    'Windows': {
      include profile::app_services::asp
    }
    default: {
      fail("${::kernel} is not a support OS kernel")
    }
  }
}
