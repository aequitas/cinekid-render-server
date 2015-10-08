# webserver to test uploading
node 'test-web-server' {
  user { $cinekid::web_user:
    ensure     => present,
    managehome => true,
  } ->
  ssh_authorized_key { "${cinekid::web_user}@${::hostname}":
    user => $cinekid::web_user,
    type => 'ssh-rsa',
    key  => $cinekid::public_key,
  }
}

node default {
    $primary_server = hiera('cinekid::nfs::primary_server')
    $primary = ( $ipaddress_eth0 == $primary_server or
        $ipaddress_eth1 == $primary_server)
    notice("This is primary server: ${primary}")

    hiera_include('classes', [])
}
