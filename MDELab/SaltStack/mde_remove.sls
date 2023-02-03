# This is a very basic way to deploy MDE using Salt Stack
#
remove_mde_managed_file:
  file.absent:
    - name: /etc/opt/microsoft/mdatp/managed/mdatp_managed.json

remove_mde_onboarding_file:
  file.absent:
    - name: /etc/opt/microsoft/mdatp/mdatp_onboard.json

offboard_mde:
  file.managed:
    - name: /etc/opt/microsoft/mdatp/mdatp_offboard.json
    - source: salt://mde/mdatp_offboard.json

remove_mde_packages:
  pkg.removed:
    - pkgs:
      - mdatp