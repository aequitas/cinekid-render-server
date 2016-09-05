# create nested directory structure for rendering
define cinekid::dir ($works, $days){
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
