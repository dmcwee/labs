#!/usr/bin/env python3

import os
import argparse
from datetime import datetime
    
def backup_cron_jobs(debug):
    try:
        today = datetime.today().date()
        formatted_date = today.strftime('%Y%m%d')
        backup_location = f"/tmp/cron_schedule_update_backup_{formatted_date}"

        cron_backup = f"(crontab -l > {backup_location})"
        if debug == True:
            print(f"[d] cron_backup: {cron_backup}")
        else:
            os.system(cron_backup)
    except Exception as e:
        print(f"[!] Error performing cron backup: {e}")
        raise Exception("Error attempting to backup cron jobs.")

def create_cron_job(minute="*", 
                    hour="2", 
                    day_of_month="*", 
                    month="*", 
                    day_of_week="6", 
                    command="", 
                    debug=False):
    
    today = datetime.today().date()
    formatted_date = today.strftime('%Y%m%d')
    export_file = f"/tmp/cron_update_schedule_{formatted_date}"

    # Construct the cron task expression
    cron_expression = f"{minute} {hour} {day_of_month} {month} {day_of_week} {command}"
    
    # pull cron tasks, append cron_expression, and store in tmp file
    cron_export = f"crontab -l > {export_file}"
    cron_append_task = f"echo '{cron_expression}' >> {export_file}"

    # push cron task temp file back to crontab for loading
    cron_cmd = f"crontab {export_file}"

    if debug == True:
        print(f"[d] cron_expression: {cron_expression}")
        print(f"[d] cron_export: {cron_export}")
        print(f"[d] task_append_cmd: {cron_append_task}")
        print(f"[d] cron_cmd: {cron_cmd}")
    else:
        try:
            # Add the command to the crontab
            os.system(cron_export)
            os.system(cron_append_task)
            os.system(cron_cmd)

            print(f"Cron job added successfully: {cron_expression}")
        except Exception as e:
            print(f"[!] Error adding cron job: {e}")
            raise Exception("Error attempting to create cron job.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Script creates an mde package update schedule.")
    parser.add_argument("-H", "--hour",
        action="store",
        dest="hour",
        type=int,
        default=2,
        choices=range(0,24),
        help="Provide a number that represents the hour of the day: 0-23 (0 being midnight). Default: 2(2am)")
    parser.add_argument("-D", "--day",
        action="store",
        dest="day",
        choices=["0","1","2","3","4","5","6"],
        default=6,
        help="Provide a number that represents the day of the week: 0 => Sunday, 6 => Saturday. Default: 6(SAT). '*' Has been removed as daily checks are not recommended.")
    parser.add_argument("-O", "--os",
        choices=["RHEL", "SLES", "DEB"],
        action="store",
        default="DEB",
        dest="os",
        help="Linux Distribution")
    parser.add_argument("-L", "--log",
        action="store",
        dest="log_file",
        default="/tmp/mdatp_update_job.log",
        help="Log file location for output.")
    parser.add_argument("-d", "--debug",
        action="store_true",
        dest="debug",
        default=False,
        help="dump parameters")
    
    try:
        args = parser.parse_args()
        update_dict = {"RHEL":"yum update mdatp -y",
                       "SLES":"zypper update mdatp",
                       "DEB":"apt install --only-upgrade mdatp"}
        
        cmd_string = f"sudo {update_dict[args.os]} >> {args.log_file}"
        if args.debug == True:
            print(f"[d] Hour: {args.hour} Day: {args.day} Cmd: {cmd_string}")

        backup_cron_jobs(args.debug)
        create_cron_job(hour=args.hour, day_of_week=args.day, command=cmd_string, debug=args.debug)
    
    except KeyboardInterrupt:
        quit()
    except Exception as e:
        print(f"[!] schedule_scan script failed: {e}")
        quit()
