# Scripts

Two script are available to help with creating cron tasks related to MDE.

## schedule_scan.py

This script creates a cron job that will perform virus scans on a regular basis.

### Usage 
`$python 3 schedule_scan.py [-h] [-H {0-23}] [-D {*,0-6}] [-S {quick,full}] [-L LOG_FILE] [-d]`

Script creates an mde scheduled quick scan.

### Options

| Commandline Parameter | Description | Default Value |
| --- | --- | --- |
| -h, --help | show this help message and exit | |
| -H {0-23}, --hour {0-23} | number representing the hour of the day: 0-23 (0 being midnight). | 2 (2am) |
| -D {*,0-6}, --day {*,0-6} | number representing the day of the week: 0 => Sunday, 6 => Saturday or * to represent every day. | * (everyday) |
| -S {quick,full}, --scan {quick,full} | Type of scan to run ('quick' or 'full'). | quick |
| -L LOG_FILE, --log LOG_FILE | Log file name and location for output. | /tmp/mdatp_scheduled_scan.log |
| -d, --debug | dump script parameters and print debug statements. No actions will be taken | |

## schedule_update.py

Script creates an mde package update schedule.

### Usage: 

`$python3 schedule_update.py [-h] [-H {0-23}] [-D {0-6}] [-O {RHEL,SLES,DEB}] [-L LOG_FILE] [-d]`

### Options

| Commandline Parameter | Description | Default Value |
| --- | --- | --- |
| -h, --help | show this help message and exit | |
| -H {0-23}, --hour {0-23} | Provide a number that represents the hour of the day: 0-23 (0 being midnight). | 2 (2am) |
| -D {0-6}, --day {0-6} | Provide a number that represents the day of the week: 0 => Sunday, 6 => Saturday. '*' Has been removed as daily checks are not recommended. | 6 (SAT) | 
| -O {RHEL,SLES,DEB}, --os {RHEL,SLES,DEB} | Linux Distribution | DEB |
| -L LOG_FILE, --log LOG_FILE | Log file location for output. | /tmp/mdatp_update_job.log |
| -d, --debug | dump parameters | |