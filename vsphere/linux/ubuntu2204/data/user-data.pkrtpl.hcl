#cloud-config

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Ubuntu Server 22.04 LTS

autoinstall:
  version: 1
  apt:
    geoip: true
    preserve_sources_list: false
    primary:
      - arches: [amd64, i386]
        uri: http://archive.ubuntu.com/ubuntu
      - arches: [default]
        uri: http://ports.ubuntu.com/ubuntu-ports
  early-commands:
    - sudo systemctl stop ssh
  locale: ${build_guestos_language}
  keyboard:
    layout: ${build_guestos_keyboard}
  storage:
    layout:
      name: direct
    config:
      # Disk
      - type: disk
        id: disk-sda
        match:
          size: largest
        ptable: gpt

      # EFI partition
      - type: partition
        id: efi-part
        size: 1024M
        flag: boot
        device: disk-sda
        wipe: superblock-recursive
        preserve: false
      - type: format
        fstype: vfat
        volume: efi-part
      - type: mount
        path: /boot/efi
        device: efi-part

      # Boot partition
      - type: partition
        id: boot-part
        size: 1024M
        device: disk-sda
      - type: format
        fstype: ext4
        volume: boot-part
      - type: mount
        path: /boot
        device: boot-part

      # LVM PV
      - type: partition
        id: pv-part
        size: -1  # use remaining space
        device: disk-sda
      - type: lvm_volgroup
        id: vg0
        name: vg0
        devices: [pv-part]

      # Logical Volume for Swap
      - type: lvm_partition
        id: lv-swap
        name: swap
        volgroup: vg0
        size: 8G
      - type: format
        fstype: swap
        volume: lv-swap
      - type: mount
        path: none
        device: lv-swap

      # Logical Volume for /var
      - type: lvm_partition
        id: lv-var
        name: var
        volgroup: vg0
        size: 8G
      - type: format
        fstype: xfs
        volume: lv-var
      - type: mount
        path: /var
        device: lv-var

      # Logical Volume for Root
      - type: lvm_partition
        id: lv-root
        name: root
        volgroup: vg0
        size: -1
      - type: format
        fstype: ext4
        volume: lv-root
      - type: mount
        path: /
        device: lv-root

  identity:
    hostname: ubuntu2204
    username: ${build_username}
    password: "${build_password_encrypted}"
  ssh:
    install-server: true
    allow-pw: true
  packages:
    - openssh-server
    - open-vm-tools
  user-data:
    disable_root: true
    timezone: ${build_guestos_timezone}
  late-commands:
    - sed -i -e 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /target/etc/ssh/sshd_config
    - echo '${build_username} ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/${build_username}
    - curtin in-target --target=/target -- chmod 440 /etc/sudoers.d/${build_username}
    - curtin in-target --target=/target -- mkdir -p /etc/apt/keyrings
    - curtin in-target --target=/target -- bash -c "curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public | tee /etc/apt/keyrings/salt-archive-keyring.pgp"
    - curtin in-target --target=/target -- bash -c "curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.sources | tee /etc/apt/sources.list.d/salt.sources"
    - curtin in-target --target=/target -- apt-get update
    - curtin in-target --target=/target -- apt-get install -y salt-minion