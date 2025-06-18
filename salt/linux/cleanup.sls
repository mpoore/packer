# cleanup.sls

/etc/machine-id:
    file.managed:
        - contents:
        - replace: True

/etc/ssh/ssh_host_*:
    file.absent:
    
/etc/udev/rules.d/70-persistent-net.rules
    file.absent:

/etc/sysconfig/network-scripts/ifcfg-*:
    file.absent:

/tmp/*:
    file.absent:

/var/tmp/*:
    file.absent:
    
        rm -f /root/.bash_history &&
        rm -f /home/*/.bash_history &&
        rm -rf /home/*/.ssh &&
        rm -rf /home/*/.cache &&
        rm -rf /home/*/.config &&
        sed -i '/^HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-* &&
        sed -i '/^UUID/d' /etc/sysconfig/network-scripts/ifcfg-* &&
        yum clean all &&
        fixfiles onboot &&
        touch /.autorelabel