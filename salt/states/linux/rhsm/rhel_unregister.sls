# rhel_unregister.sls

{% if grains['os'] == 'RedHat' %}
# Unregister the system from Red Hat Subscription Manager
unregister_from_subscription_manager:
  cmd.run:
    - name: subscription-manager unregister
    - onlyif: subscription-manager status | grep '^Overall Status.*Current$'
    - order: 99999
{% endif %}