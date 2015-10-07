define cinekid::folder(){
    file { "${cinekid::share_root}/${name}":
      ensure => directory,
      owner  => nobody,
      group  => $cinekid::user,
    }
}
