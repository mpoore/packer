{% if grains['os'] == 'RedHat' %}
# Update crypto policies to allow SHA-1 signed packages
rupdate_crypto_policies_legacy:
  cmd.run:
    - name: update-crypto-policies --set LEGACY
{% endif %}