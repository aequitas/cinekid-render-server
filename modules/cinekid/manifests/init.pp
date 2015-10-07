class cinekid (
  $user = undef,
  $web_user = undef,
  $private_key = undef,
  $public_key = undef,
  $share_root = '/srv/cinekid/samba',
  $works = undef,
  $day_start=10,
  $day_stop=20,
){
  # install required packages
  package { 'libav-tools':
  }

  # create required user and group
  group { $user:
    ensure => present,
  }
  user { $user:
    ensure     => present,
    groups     => [$user],
    managehome => true,
    shell      => '/bin/bash',
  } ->
  file { "/home/${user}":
    ensure => directory,
  } ->
  file { "/home/${user}/.ssh":
    ensure => directory,
  }

  # install private key for rsync
  file { "/home/${user}/.ssh/id_rsa":
    content => $private_key,
    mode    => '0600',
  }

  # install scripts
  file { "/usr/local/bin/cinekid_processing_pipeline.sh":
    source => 'puppet:///modules/cinekid/src/cinekid_processing_pipeline.py',
    mode   => '0755',
  }

  # install scripts
  file { "/usr/local/bin/cinekid_render.sh":
    source => 'puppet:///modules/cinekid/src/cinekid_render.sh',
    mode   => '0755',
  }

  # create processing pipeline daemon script
  file { "/etc/init/cinekid_processing_pipeline.conf":
    content => template('cinekid/cinekid_processing_pipeline.conf'),
  } ~>
  service { 'cinekid_processing_pipeline':
    ensure => running,
    enable => true,
  }

  # create base directories
  $root = '/srv/cinekid/'
  file { $root:
    ensure => directory,
  }
  file { '/srv/cinekid/logs/':
    ensure => directory,
  }

  # processing pipeline directories
  $dirs = [
    'samba',
    'in',
    'render_locks',
    'render',
    'tmp',
    'done',
  ]

  # day directories to create in works directories
  $days = range($day_start, $day_stop)

  # set default user for directories
  File {
    owner => $user,
    group => $user
  }
  $_dirs = prefix(suffix($dirs, '/'), $root)

  dir { $_dirs:
    works => $works,
    days  => $days,
  }
}

define dir ($works, $days){
  $_works = prefix(suffix($works,'/'), $name)
  file { $name:
    ensure => directory
  }
  file { $_works:
    ensure => directory;
  }
  day{ $_works:
    days => $days,
  }
}

define day ($days){
  $_days = prefix(suffix($days,'/'), $name)
  file { $_days:
    ensure => directory,
  }
}
