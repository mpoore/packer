# rhel_register.sls

{% set rhsm_user = salt['environ.get']('RHSM_USER', 'default_value') %}
{% set rhsm_pass = salt['environ.get']('RHSM_PASS', 'default_value') %}

{% if grains['os'] == 'RedHat' %}
# Ensure subscription-manager is installed
subscription-manager-install:
  pkg.installed:
    - name: subscription-manager

# Register the system with Red Hat Subscription Manager and auto-attach a subscription
register_with_subscription_manager:
  cmd.run:
    - name: subscription-manager register --username={{ rhsm_user }} --password='{{ rhsm_pass }}' --auto-attach
    - unless: subscription-manager status | grep '^Overall Status.*Current$'
    - require:
      - pkg: subscription-manager-install
{% endif %}