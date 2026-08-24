# ----------------------------------------------------------------------------
# Name:         salt/states/linux/certificates.sls
# Description:  Salt state file for Packer provisioning to configure trusted
#               SSL certificates
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------
{% set os = grains['os'] %}
{% set root_urls = (salt['environ.get']('ROOTPEMFILES', '')).split(',') | map('trim') | select() | list %}
{% set issuing_urls = (salt['environ.get']('ISSUINGPEMFILES', '')).split(',') | map('trim') | select() | list %}

{% if os in ['RedHat', 'CentOS Stream', 'Rocky'] %}
  {% set cert_dir = '/etc/pki/ca-trust/source/anchors' %}
  {% set update_cmd = 'update-ca-trust extract' %}
{% elif os in ['Ubuntu', 'Debian'] %}
  {% set cert_dir = '/usr/local/share/ca-certificates' %}
  {% set update_cmd = 'update-ca-certificates' %}
{% elif os == 'VMware Photon OS' %}
  {% set cert_dir = '/etc/ssl/certs' %}
  {% set update_cmd = 'rehash_ca_certificates.sh' %}
{% else %}
  {% set cert_dir = '/usr/local/share/ca-certificates' %}
  {% set update_cmd = 'update-ca-certificates' %}
{% endif %}

certs-dir:
  file.directory:
    - name: {{ cert_dir }}
    - user: root
    - group: root
    - mode: 755

{% for url in root_urls %}
root-remote-{{ loop.index0 }}-cert:
  file.managed:
    - name: {{ cert_dir }}/root-remote-{{ loop.index0 }}.crt
    - source: {{ url }}
    - skip_verify: True
    - user: root
    - group: root
    - mode: 644
{% endfor %}

{% for url in issuing_urls %}
issuing-remote-{{ loop.index0 }}-cert:
  file.managed:
    - name: {{ cert_dir }}/issuing-remote-{{ loop.index0 }}.crt
    - source: {{ url }}
    - skip_verify: True
    - user: root
    - group: root
    - mode: 644
{% endfor %}

update-ca-store:
  cmd.run:
    - name: {{ update_cmd }} 2>/dev/null
    - onchanges:
      {% for url in root_urls %}
      - file: root-remote-{{ loop.index0 }}-cert
      {% endfor %}
      {% for url in issuing_urls %}
      - file: issuing-remote-{{ loop.index0 }}-cert
      {% endfor %}