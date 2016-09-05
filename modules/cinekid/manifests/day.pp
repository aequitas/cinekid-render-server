# create daily folder in rending directory
define cinekid::day ($days){
  $_days = prefix(suffix($days,'/'), $name)
  file { $_days:
    ensure => directory,
  }
}
