#!/usr/bin/env python3

"""
Quits fast and can be run often to update pipeline.
State is kept on the filesystem."""

import os
import multiprocessing
import json
import logging
import subprocess
import re

log = logging.getLogger(__name__)
# settings
base_dir = '/srv/cinekid'
render_re = re.compile('sleep 10')

render_cmd = '/vagrant/src/render.sh {base} {in_file} {tmp_file} {done_file}&'

# internal variables
samba_dir = 'samba'
in_dir = 'in'
render_locks = 'render_locks'
render_dir = 'render'
done_dir = 'done'
tmp_dir = 'tmp'

cores = multiprocessing.cpu_count()

def find(path):
    """Return files in path recursively, including directory name.

    >>> find('samba_dir')
    ['10/file1.mpg', '11/file2.mpg']
    """
    return [os.path.join(dp, f).replace(path+'/', '') for dp, dn, fn in os.walk(path) for f in fn]

def start_render(file):
    """Start background render process for file."""
    files = {
        'base': base_dir,
        'in_file': os.path.join(samba_dir, file),
        'tmp_file': os.path.join(tmp_dir, file),
        'done_file': os.path.join(done_dir, file),
    }
    cmd = render_cmd.format(**files)
    print('starting render command: ', cmd)
    process = subprocess.Popen(cmd, shell=True)

    with open(os.path.join(render_locks, file), 'w') as f:
        f.write(json.dumps({'pid': process.pid}))
    return process

def clean_render_files(lockfiles):
    """Remove lockfiles for processes that are no longer running."""
    for lockfile in lockfiles:
        with open(os.path.join(render_locks, lockfile),'r') as f:
            try:
                process = json.loads(f.read())
            except:
                log.error('invalid lockfile %s, removing', lockfile)
                os.remove(os.path.join(render_locks, lockfile))

        cmdfile = os.path.exists(os.path.join('/proc/', str(process.get('pid')), 'cmdline'))
        if not cmdfile:
            log.info('process for lockfile %s no longer running, removing', lockfile)
            os.remove(os.path.join(render_locks, lockfile))

def main():
    # get current state from filesystem
    samba_files = find(samba_dir)
    ready_files = samba_files
    rendering_files = find(render_locks)
    rendering_done = find(render_dir)
    done_files = find(done_dir)

    available_slots = max(0, cores - len(rendering_files))
    print('render slots; total:', cores, 'available:', available_slots, 'running renders:', rendering_files)

    render_files = list(set(ready_files) - set(done_files) - set(rendering_files))

    print('file stats; samba:', len(samba_files), 'ready:', len(ready_files), 'need render:',
    len(render_files), 'rendering:', len(rendering_files), 'done:', len(done_files))

    to_process = render_files[:available_slots]

    print('going to start render of: ', to_process)

    pids = [p.pid for p in map(start_render, to_process)]
    print('started render processes with pids:', pids)

    clean_render_files(rendering_files)

if __name__ == "__main__":
    os.chdir(base_dir)
    logging.basicConfig(level=logging.INFO)
    main()
