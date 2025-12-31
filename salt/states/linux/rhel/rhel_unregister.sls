# rhel_unregister.sls

{% if grains['os'] == 'RedHat' %}
# Unregister the system from Red Hat Subscription Manager
unregister_from_subscription_manager:
  cmd.run:
    - name: subscription-manager unregister
    - order: 99900
{% endif %}