class profile::lb_services::haproxy {

  $listeners        = hiera('profile::lb_services::haproxy::listeners',undef)
  $enable_firewall  = hiera('profile::lb_services::haproxy::enable_firewall')
  $frontends        = hiera('profile::lb_services::haproxy::frontends',undef)

  Firewall {
    before  => Class['profile::fw::post'],
    require => Class['profile::fw::pre'],
  }

  include ::haproxy

  if $listeners {
    $listeners.each |String $key,Hash $value| {
      haproxy::listen { $key:
        collect_exported => $value['collect_exported'],
        ipaddress        => $value['ipaddress'],
        ports            => $value['ports'],
        options          => $value['options'],
      }

      if $enable_firewall {
        firewall { "100 ${key}":
          port   => [$value['ports']],
          proto  => 'tcp',
          action => 'accept',
        }
      }
    }
  }

  if $frontends {
    $frontends.each |String $frontend, Hash $values| {
      haproxy::frontend { $frontend:
        * => $values,;
      }
    }
  }
}
