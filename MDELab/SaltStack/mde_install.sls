# This is a very basic way to deploy MDE using Salt Stack
#
add_ms_repo:
    pkgrepo.managed:
      - humanname: Microsoft Defender
      {% if grains['os_family'] == 'Debian' %}
      - name: deb [arch=amd64,armhf,arm64] https://packages.microsoft.com/ubuntu/20.04/prod focal main
      - dist: focal 
      - file: /etc/apt/sources.list.d/microsoft-prod.list
      - key_url: https://packages.microsoft.com/keys/microsoft.asc
      - refresh_db: true
      {% elif grains['os_family'] == 'RedHat' %}
      - name: packages-microsoft-prod
      - file: microsoft-prod
      - baseurl: https://packages.microsoft.com/rhel/8/prod
      - gpgkey: https://packages.microsoft.com/keys/microsoft.asc
      - gpgcheck: true
      {% endif %}

# this was required when I tried installing on CentOS
install_mdatp_prereqs:
  pkg.installed:
    - pkgs:  
      - libnetfilter_queue
      - mde-netfilter

install_mdatp:
  pkg.installed:
    - name: mdatp
    - required: add_ms_repo

# An example MDATP Managed JSON file can be found in the Ansible folder of this lab
copy_mde_configuration:
  file.managed:
    - name: /etc/opt/microsoft/mdatp/managed/mdatp_managed.json
    - source: salt://mde/mdatp_managed.json
    - required: install_mdatp

# this assumes you have extracted the mdatp_onboard.json file to your salt shared file directory
copy_mde_onboarding_file:
  file.managed:
    - name: /etc/opt/microsoft/mdatp/mdatp_onboard.json
    - source: salt://mde/mdatp_onboard.json
    - required: install_mdatp
