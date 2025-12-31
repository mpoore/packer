# ----------------------------------------------------------------------------
# Name:         salt/states/linux/salt-minion.sls
# Description:  Salt state file for Packer provisioning to prepare and
#               configure salt-minion
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

# Set paths based on OS family - works for RHEL, Ubuntu, and Photon OS
{% set unit_path = "/etc/systemd/system" %}
{% set minion_path = "/etc/salt" %}
{% if grains['os_family'] == 'Debian' %}
  {% set service_name = "salt-minion" %}
{% elif grains['os'] == 'Photon' %}
  {% set service_name = "salt-minion" %}
{% else %}
  {% set service_name = "salt-minion" %}
{% endif %}

# Create systemd override directory for salt-minion
salt_minion_override_dir:
  file.directory:
    - name: {{ unit_path }}/{{ service_name }}.service.d
    - makedirs: True
    - order: 99991

# Configure salt-minion to start 60 seconds after boot
salt_minion_delayed_start:
  file.managed:
    - name: {{ unit_path }}/{{ service_name }}.service.d/override.conf
    - contents: |
        [Service]
        ExecStartPre=/bin/sleep 60
    - require:
      - file: salt_minion_override_dir
    - order: 99992

# Remove minion_id file
salt_minion_id_cleanup:
  file.absent:
    - name: {{ minion_path }}/minion_id
    - order: 99993

# Remove minion keys
salt_minion_keys_cleanup:
  file.absent:
    - name: {{ minion_path }}/pki/minion
    - order: 99994

# Reload systemd daemon to apply changes
salt_minion_systemd_reload:
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: salt_minion_delayed_start
    - order: 99995

# Enable salt-minion service
salt_minion_enable:
  service.enabled:
    - name: salt-minion
    - onchanges:
      - file: salt_minion_delayed_start
    - order: 99996