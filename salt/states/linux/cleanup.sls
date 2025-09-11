# ----------------------------------------------------------------------------
# Name:         salt/states/linux/cleanup.sls
# Description:  Salt state file for Packer provisioning to cleanup OS
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

# Remove temp files, logs, history, and personalization
cleanup_files:
  file.absent:
    - names:
      - /etc/ssh/ssh_host_*              # SSH host keys
      - /var/log/lastlog
      - /var/log/*.log                   # log files
      - /var/log/*.log.*                 # rotated logs
      - /tmp/*                           # tmp files
      - /var/tmp/*                       # var tmp files
      - /root/.bash_history
      - /home/*/.bash_history
      - /root/.ssh/known_hosts
      - /home/*/.ssh/known_hosts
      - /var/lib/cloud/instances/*       # cloud-init instances
      - /etc/machine-id
      - /var/lib/dhcp/*
      - /var/lib/dhclient/*
      - /var/lib/systemd/random-seed
    - order: last

# Reset machine-id after deletion
reset_machine_id:
  cmd.run:
    - name: dbus-uuidgen --ensure=/etc/machine-id
    - order: last
    - require:
      - file: cleanup_files

# Clean cloud-init state if installed
cleanup_cloud_init:
  cmd.run:
    - name: cloud-init clean --logs --seed
    - onlyif: which cloud-init
    - order: last

truncate_wtmp:
  cmd.run:
    - name: cat /dev/null > /var/log/wtmp
    - order: last

truncate_btmp:
  cmd.run:
    - name: cat /dev/null > /var/log/btmp
    - order: last

# Final sync to flush changes
cleanup_sync:
  cmd.run:
    - name: sync
    - order: last