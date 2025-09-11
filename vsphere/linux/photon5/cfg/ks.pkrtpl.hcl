{
    "hostname": "photon5",
    "password":
        {
            "crypted": false,
            "text": "${admin_password}"
        },
    "disk": "/dev/sda",
    "partitions": [
        {
            "mountpoint": "/boot/efi",
            "size": 1024,
            "filesystem": "vfat",
            "label": "EFI"
        },
        {
            "mountpoint": "/boot",
            "size": 1024,
            "filesystem": "ext4",
            "label": "BOOT"
        },
        {
            "size": 8192,
            "filesystem": "swap",
            "lvm": {
                "vg_name": "vg0",
                "lv_name": "swap"
            }
        },
        {
            "mountpoint": "/var",
            "size": 8192,
            "filesystem": "xfs",
            "lvm": {
                "vg_name": "vg0",
                "lv_name": "var"
            }
        },
        {
            "mountpoint": "/",
            "size": 0,
            "filesystem": "ext4",
            "lvm": {
                "vg_name": "vg0",
                "lv_name": "root"
            }
        }
    ],
    "bootmode": "efi",
    "packages": [
        "minimal",
        "linux",
        "initramfs",
        "sudo",
        "vim",
        "cloud-utils",
        "openssl-c_rehash",
        "wget"
    ],
    "postinstall": [
        "#!/bin/sh",
        "useradd -m -G sudo ${build_username}",
        "echo \"${build_username}:${build_password}\" | chpasswd",
        "echo \"${build_username}  ALL=(ALL)  NOPASSWD:SETENV: ALL\" >> /etc/sudoers.d/${build_username}",
        "chage -I -1 -m 0 -M 99999 -E -1 ${admin_username}",
        "chage -I -1 -m 0 -M 99999 -E -1 ${build_username}",
        "iptables -A INPUT -p tcp --dport 22 -j ACCEPT",
        "iptables -A INPUT -p ICMP -j ACCEPT",
        "iptables -A OUTPUT -p ICMP -j ACCEPT",
        "iptables-save > /etc/systemd/scripts/ip4save",
        "systemctl restart iptables",
        "sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config",
        "systemctl restart sshd.service",
        "curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.repo | tee /etc/yum.repos.d/salt.repo",
        "tdnf install -y salt-minion"
    ],
    "linux_flavor": "linux",
    "network": {
        "type": "dhcp"
    }    
}