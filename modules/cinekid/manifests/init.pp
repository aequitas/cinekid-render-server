class cinekid (
  $user = undef,
  $web_user = undef,
  $web_host = undef,
  $web_target = undef,
  $private_key = undef,
  $public_key = undef,
  $base_dir = '/srv/cinekid',
  $share_root = '/srv/cinekid/samba',
  $done_dir = '/srv/cinekid/done',
  $works = undef,
  $day_start=10,
  $day_stop=20,
){
  # install required packages
  package { ['libav-tools', 'rsync', 'python3-pip']:
  } ->
  package { ['colorlog', 'simplejson']:
    provider => 'pip3',
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

  file { "/home/${user}/.ssh/config":
    content => "StrictHostKeyChecking no"
  }

  # install private key for rsync
  file { "/home/${user}/.ssh/id_rsa":
    content => $private_key,
    mode    => '0600',
  }

  # install scripts
  file { "/usr/local/bin/cinekid_processing_pipeline.py":
    source => 'puppet:///modules/cinekid/src/cinekid_processing_pipeline.py',
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
  File["/usr/local/bin/cinekid_processing_pipeline.py"] ~>
  Service['cinekid_processing_pipeline']

  # only run rsync on primary server
  $rsync_ensure = $primary ? { true => running, false => stopped }
  file { "/etc/init/cinekid_rsync.conf":
    content => template('cinekid/cinekid_rsync.conf'),
  } ~>
  service { 'cinekid_rsync':
    ensure => $rsync_ensure,
    enable => true,
  }

  # create base directories (on primary server only)
  if $primary {
      $root = '/srv/cinekid/'

      file { $root:
        ensure => directory,
      }

      file { '/srv/cinekid/logs/':
        ensure => directory,
      }

      file { '/srv/cinekid/config/':
        ensure => directory,
      }

      file { '/srv/cinekid/renderers/':
        ensure => directory,
      }

      # install scripts
      file { "/srv/cinekid/renderers/cinekid_render.sh":
        source => 'puppet:///modules/cinekid/src/cinekid_render.sh',
        mode   => '0755',
      }
      file { "/srv/cinekid/renderers/cinekid_render_test.sh":
        source => 'puppet:///modules/cinekid/src/cinekid_render_test.sh',
        mode   => '0755',
      }
      file { "/srv/cinekid/renderers/cinekid_render_noop.sh":
        source => 'puppet:///modules/cinekid/src/cinekid_render_noop.sh',
        mode   => '0755',
      }
      file { "/srv/cinekid/renderers/cinekid_render_default.sh":
        source => 'puppet:///modules/cinekid/src/cinekid_render_default.sh',
        mode   => '0755',
      }
      file { "/srv/cinekid/renderers/cinekid_render_webm.sh":
        source => 'puppet:///modules/cinekid/src/cinekid_render_webm.sh',
        mode   => '0755',
      }


      # processing pipeline directories
      $dirs = [
        'samba',
        'render_locks',
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
