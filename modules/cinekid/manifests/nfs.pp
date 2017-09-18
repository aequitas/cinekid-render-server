# install nfs server for sharing rendering files among render servers
class cinekid::nfs (
    $primary_server=undef,
    $secondary_servers=[],
){
  include nfs::client

    # for primary server configure nfs exports, for others configure mounts
    if $::primary {
        include nfs::server
        $clients = join(suffix($secondary_servers, '/32(rw,insecure,async,no_root_squash)'), ' ')

        nfs::server::export { $cinekid::base_dir:
            ensure  => 'present',
            clients => $clients,
        }
    } else {
        nfs::client::mount { $cinekid::base_dir:
            server  => $primary_server,
            share   => $cinekid::base_dir,
            options => 'rw',
            owner   => $cinekid::user,
            group   => $cinekid::user,
        }
    }
}
