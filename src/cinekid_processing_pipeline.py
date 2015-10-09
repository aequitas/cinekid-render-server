#!/usr/bin/env python3

"""
Quits fast and can be run often to update pipeline.
State is kept on the filesystem."""

import hashlib
import json
import logging
import multiprocessing
import os
import platform
import random
import re
import socket
import subprocess
import time
from collections import defaultdict

from colorlog import ColoredFormatter

log = logging.getLogger(__name__)

# settings
# video formats to look for when scanning directories
video_ext = re.compile('[^\.].*(mp4|mov|flv|webm|avi|mpg|mpeg)$', re.I)
# seconds a file not has to have been touched to be considered ready for rendering
ready_age = 60

# map work name (lowercase) to renderer and output file extension (None for same)
render_mapping = {
    'default': ('default', 'flv'),
    # 'default': ['webm', 'webm'],
    # 'default': ('test', None),
    # '': ('noop', None),
    # 'mov': ('')
}

render_cmd = '/usr/local/bin/cinekid_render.sh'

# internal variables
base_dir = '/srv/cinekid'
samba_dir = 'samba'
render_locks = 'render_locks'
done_dir = 'done'
tmp_dir = 'tmp'

# configure logging
formatter = ColoredFormatter(
    "%(log_color)s%(levelname)-8s%(reset)s %(message)s",
    datefmt=None,
    reset=True,
    log_colors={
        'DEBUG': 'cyan',
        'INFO': 'green',
        'WARNING': 'yellow',
        'ERROR': 'red',
        'CRITICAL': 'red,bg_white',
    },
    secondary_log_colors={},
    style='%'
)

# get uuid for this host from ssh rsa host key or fallback on hostname
try:
    uuid = hashlib.md5(open('/etc/ssh/ssh_host_rsa_key.pub', 'rb').read()).hexdigest()
except:
    uuid = platform.node()
cores = multiprocessing.cpu_count()

def find(path):
    """Return files in path recursively, including directory name.

    >>> find('test/samba/')
    ['test/samba/Test/file1.mp4', 'test/samba/Test/file2.mp4']
    """
    return [os.path.join(dp, f).replace(path + '/', '')
        for dp, dn, fn in os.walk(path)
            for f in fn if video_ext.match(f)]

def replace_ext(file_name, ext):
    """If ext is provided replace the file name extension with ext.
    >>> replace_ext('test.123', '321')
    'test.321'
    """
    if not ext:
        return file_name

    return ".".join([file_name.rsplit('.', 1)[0], ext])

def start_render(file_name, render_mapping):
    """Start background render process for file."""
    lock_file = os.path.join(render_locks, file_name)

    # get specific renderer for work or fallback to default
    work_name = file_name.split('/')[0]
    renderer, out_ext = render_mapping.get(work_name, render_mapping.get('default'))
    log.info('looking up renderer for work named: %s = %s, extension change: %s', work_name, renderer, out_ext)

    # replace extension for out files if configured so
    tmp_file = replace_ext(os.path.join(tmp_dir, file_name), out_ext)
    out_file = replace_ext(os.path.join(done_dir, file_name), out_ext)

    # compose arguments from render script
    args = [
        renderer,
        base_dir,
        lock_file,
        os.path.join(samba_dir, file_name),
        tmp_file,
        out_file,
    ]

    log.info('starting render command: %s %s', render_cmd, " ".join(args))
    process = subprocess.Popen([render_cmd] + args, preexec_fn=os.setpgrp)

    with open(lock_file, 'w') as f:
        f.write(json.dumps({
            'pid': process.pid,
            'uuid': uuid
        }))
    return process.pid

def lockfiles_by_host(lockfiles):
    host_lockfiles = defaultdict(list)

    for lockfile in lockfiles:
        lockfile_path = os.path.join(render_locks, lockfile)

        try:
            with open(lockfile_path, 'r') as f:
                try:
                    lockdata = json.loads(f.read())
                    assert lockdata['uuid']
                    assert lockdata['pid']
                    lockdata['filename'] = lockfile
                    host_lockfiles[lockdata.get('uuid')].append(lockdata)
                except:
                    log.exception('invalid lockfile %s, removing', lockfile_path)
                    os.remove(os.path.join(render_locks, lockfile))
                    continue
        except FileNotFoundError:
            log.warning('lock file %s no longer there ', lockfile_path)

    return host_lockfiles

def clean_render_files(lockfiles):
    """Remove lockfiles for processes that are no longer running."""

    host_lockfiles = lockfiles_by_host(lockfiles)

    for lockfile in host_lockfiles.get(uuid, []):
        pid = str(lockfile.get('pid'))

        cmdfile = os.path.exists(os.path.join('/proc/', pid, 'cmdline'))
        if not cmdfile:
            lockfile_path = os.path.join(render_locks, lockfile.get('filename'))
            log.warning('process for lockfile %s, no longer running, removing %s', lockfile, lockfile_path)
            os.remove(lockfile_path)

def filter_ready(files, root=''):
    """Return only files which haven't been touched for a while."""
    now = int(time.time())

    for f in files:
        mtime = int(os.path.getctime(os.path.join(root, f)))
        age = now - mtime
        if age > ready_age:
            yield f

def remove_done_and_rendering(ready_files, done_files, rendering_files):
    """Accept list of files ready for processing, remove file which are done or rendering."""
    for f in ready_files:
        if f in rendering_files:
            continue

        # strip extension for done files as it might have changed
        without_ext = f.rsplit('.', 1)[0]
        if [f for f in done_files if without_ext in f]:
            continue

        yield f

def main():
    log.info('this host id: %s', uuid)

    # try loading render mapping from file
    try:
        render_mapping_file = '/home/cinekid/render_mapping.json'
        if os.path.exists(render_mapping_file):
            with open(render_mapping_file) as f:
                render_mapping.update(json.loads(f.read()))
            log.info('loaded render mapping override from file: %s', render_mapping_file)
    except:
        log.exception('failed to load render mapping from file: %s', render_mapping_file)



    # get current state from filesystem
    samba_files = find(samba_dir)
    ready_files = list(filter_ready(samba_files, samba_dir))
    rendering_files = find(render_locks)
    done_files = find(done_dir)

    rendering_by_host = lockfiles_by_host(rendering_files)
    rendering_this_host = rendering_by_host.get(uuid, [])

    available_slots = max(0, cores - len(rendering_this_host))
    log.info('render slots; total: %s, available: %s', cores, available_slots)

    if rendering_files:
        log.info('rendering on hosts:')
        for host, files in rendering_by_host.items():
            log.info("  %s %s", host, [f.get('filename') for f in files])
    else:
        log.info('nothing rendering at the moment')


    # determine files which need rendering
    render_files = list(remove_done_and_rendering(ready_files, done_files, rendering_files))

    log.info('file stats; samba: %s, ready: %s, need render: %s, rendering: %s, done: %s',
        len(samba_files), len(ready_files), len(render_files), len(rendering_files), len(done_files))

    # randomize list to try and prevent failing files holding up the line
    random.shuffle(render_files)
    to_process = render_files[:available_slots]
    if to_process:
        log.info('going to start render of: %s', to_process)

        pids = [start_render(f, render_mapping) for f in to_process]
        log.info('started render processes with pids: %s', pids)
    else:
        if available_slots:
            log.info('no files need rendering')
        else:
            log.info('render slots full, not starting new renders')

    clean_render_files(rendering_files)

if __name__ == "__main__":
    os.chdir(base_dir)

    log.setLevel(logging.INFO)
    ch = logging.StreamHandler()
    ch.setFormatter(formatter)
    log.addHandler(ch)

    main()
    log.info('---------------------------\n')
