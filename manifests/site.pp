hiera_include('classes', [])

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

node default {}
