# ----------------------------------------------------------------------------
# Name:         salt/states/linux/certificates.sls
# Description:  Salt state file for Packer provisioning to configure trusted
#               SSL certificates
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------
{% set os = grains['os'] %}
{% set certs = salt['pillar.get']('trustedcertificates', {}) %}

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

{% for cert_name in certs %}
{{ cert_name }}-cert:
  file.managed:
    - name: {{ cert_dir }}/{{ cert_name }}.crt
    - user: root
    - group: root
    - mode: 644
    - contents_pillar: trustedcertificates:{{ cert_name }}
{% endfor %}

update-ca-store:
  cmd.run:
    - name: {{ update_cmd }}
    - onchanges:
      {% for cert_name in certs %}
      - file: {{ cert_name }}-cert
      {% endfor %}