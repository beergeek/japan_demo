class profile::web_services::iis {

  $website_hash = hiera('profile::web_services::iis::website_hash',undef)
  $base_docroot = hiera('profile::web_services::iis::base_docroot')

  case $::kernelmajversion {
    '6.0','6.1': {
      windowsfeature { 'IIS':
        feature_name => [
          'Web-Server',
          'Web-WebServer',
          'Web-Asp-Net',
          'Web-ISAPI-Ext',
          'Web-ISAPI-Filter',
          'NET-Framework',
          'WAS-NET-Environment',
          'Web-Http-Redirect',
          'Web-Filtering',
          'Web-Mgmt-Console',
          'Web-Mgmt-Tools'
        ]
      }
    }
    '6.2.','6.3': {
      windowsfeature { 'IIS':
        feature_name => [
          'Web-Server',
          'Web-WebServer',
          'Web-Common-Http',
          'Web-Asp',
          'Web-Asp-Net45',
          'Web-ISAPI-Ext',
          'Web-ISAPI-Filter',
          'Web-Http-Redirect',
          'Web-Health',
          'Web-Http-Logging',
          'Web-Filtering',
          'Web-Mgmt-Console',
          'Web-Mgmt-Tools'
          ],
      }
    }
    default: {
      fail("You must be running a 19th centery version of Windows")
    }
  }

  # disable default website
  iis::manage_site { 'Default Web Site':
    ensure    => absent,
    site_path => 'C:\inetpub\wwwroot',
    app_pool  => 'Default Web Site',
  }

  iis::manage_app_pool { 'Default Web Site':
    ensure => absent,
  }

  if $website_hash {
    $website_hash.each |String $site_name, Hash $website| {
      if $website['database_search'] {
        $search_results = query_resources(false, $website['database_search'])
      } else {
        $_bypass = true
      }
      if $_bypass or !(empty($search_results)) {
        $_docroot = "${base_docroot}\\${website['docroot']}"

        iis::manage_app_pool { $site_name:
          enable_32_bit           => true,
          managed_runtime_version => 'v4.0',
        }

        iis::manage_site { $site_name:
          site_path   => $_docroot,
          port        => '80',
          ip_address  => '*',
          host_header => $site_name,
          app_pool    => $site_name,
          before      => File[$_docroot],
        }

        acl { $_docroot:
          target                     => $_docroot,
          purge                      => false,
          permissions                => [
            { identity => 'vagrant', rights => ['full'], perm_type=> 'allow', child_types => 'all', affects => 'all' },
            { identity => 'Administrators', rights => ['full'], perm_type=> 'allow', child_types => 'all', affects => 'all'}
            ],
            owner                      => 'vagrant',
            group                      => 'Administrators',
            inherit_parent_permissions => true,
        }
        file { $_docroot:
          ensure  => directory,
          owner   => 'vagrant',
          group   => 'Administrators',
          recurse => true,
          purge   => true,
          force   => true,
          source  => "puppet:///iis_files/${site_name}",
        }
      }
    }
  }
}
