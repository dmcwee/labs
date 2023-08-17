# Create a cron job to run quick scans
#
mdatp scan quick > /home/cmadmin/mdatp_cron_job.log:
  cron.present:
    - special: '@hourly'
