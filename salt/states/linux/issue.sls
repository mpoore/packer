# ----------------------------------------------------------------------------
# Name:         salt/states/linux/issue.sls
# Description:  Salt state file for Packer provisioning to configure issue
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------
issue:
  file.managed:
    - name: /etc/issue
    - contents_pillar: issue_contents
    - user: root
    - group: root
    - mode: '0644'

issue_net:
  file.managed:
    - name: /etc/issue.net
    - contents_pillar: issue_contents
    - user: root
    - group: root
    - mode: '0644'