{% if grains['os'] == 'RedHat' %}
# Update crypto policies to allow SHA-1 signed packages
configure_network_kernel_settings:
  file.managed:
    - name: /etc/sysctl.conf
    - contents: |
        # sysctl settings are defined through files in
        # /usr/lib/sysctl.d/, /run/sysctl.d/, and /etc/sysctl.d/.
        #
        # Vendors settings live in /usr/lib/sysctl.d/.
        # To override a whole file, create a new file with the same in
        # /etc/sysctl.d/ and put new settings there. To override
        # only specific settings, add a file with a lexically later
        # name in /etc/sysctl.d/ and put new settings there.
        #
        # For more information, see sysctl.conf(5) and sysctl.d(5).
        net.ipv4.conf.all.send_redirects = 0
        net.ipv4.icmp_ignore_bogus_error_responses = 1
        kernel.randomize_va_space = 2
        net.core.wmem_default=26214400
    - user: root
    - group: root
    - mode: 644
{% endif %}