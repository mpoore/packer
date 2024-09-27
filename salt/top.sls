# salt/top.sls
base:
  'kernel:Linux':
    - match: grain
    - linux/rhsm/rhel_register
    - linux/updates
    - linux/motd
    - linux/rhsm/rhel_unregister
    - linux/clean