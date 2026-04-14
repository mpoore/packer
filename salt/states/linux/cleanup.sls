# ----------------------------------------------------------------------------
# Name:         salt/states/linux/cleanup.sls
# Description:  Salt state file for Packer provisioning to cleanup OS
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

# Remove temp files, logs, history, and personalization
cleanup_files_exact:
  file.absent:
    - names:
      - /var/log/lastlog
      - /root/.bash_history
      - /root/.ssh/known_hosts
      - /etc/machine-id
      - /var/lib/systemd/random-seed
      - /etc/resolv.conf
    - order: last

# Remove files using wildcards
cleanup_files_glob:
  cmd.run:
    - names:
      - rm -f /etc/ssh/ssh_host_*
      - rm -f /var/log/*.log
      - rm -f /var/log/*.log.*
      - rm -rf /tmp/*
      - rm -rf /var/tmp/*
      - rm -f /home/*/.bash_history
      - rm -f /home/*/.ssh/known_hosts
      - rm -rf /var/lib/cloud/*
      - rm -f /var/lib/dhcp/*
      - rm -f /var/lib/dhclient/*
      - rm -f /etc/sysconfig/network-scripts/ifcfg-*
      - rm -f /etc/NetworkManager/system-connections/*
    - order: last

# Reset machine-id after deletion
reset_machine_id:
  cmd.run:
    - name: dbus-uuidgen --ensure=/etc/machine-id
    - order: last
    - require:
      - file: cleanup_files_exact

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