# ----------------------------------------------------------------------------
# Name:         salt/states/windows/hibernation.sls
# Description:  Salt state file for Packer provisioning to disable hibernation
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

# Set hibernation file size
hibernation_file_size:
  reg.present:
    - name: HKLM\SYSTEM\CurrentControlSet\Control\Power
    - vname: HiberFileSizePercent
    - vdata: 0
    - vtype: REG_DWORD

# Disable hibernation
hibernation_disable:
  reg.present:
    - name: HKLM\SYSTEM\CurrentControlSet\Control\Power
    - vname: HibernateEnabled
    - vdata: 0
    - vtype: REG_DWORD