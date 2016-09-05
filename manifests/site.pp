# webserver to test uploading
node 'test-web-server' {
  $user = hiera('cinekid::web_user')

  user { $user:
    ensure     => present,
    managehome => true,
  } ->
  ssh_authorized_key { "${user}@${::hostname}":
    user => $user,
    type => 'ssh-rsa',
    key  => hiera('cinekid::public_key'),
  }
}

node default {
    $primary_server = hiera('cinekid::nfs::primary_server')
    $primary = ( $ipaddress_eth0 == $primary_server or
        $ipaddress_eth1 == $primary_server)
    notice("This is primary server: ${primary}")

    hiera_include('classes', [])
}
