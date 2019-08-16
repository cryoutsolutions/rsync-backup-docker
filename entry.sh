#! /bin/sh

LOG_FILE=/backup-docker.log

# prepare crontab for root
touch /etc/crontabs/root

source vars.sh

# Dynamic parts - depending on the retain settings
# This will also create the crontab
if [ "${BACKUP_HOURLY}" -gt 0 ]; then
  echo "0 * * * * /backup.sh hourly >$LOG_FILE" >>/etc/crontabs/root
  echo "Hourly backup job created!" >$LOG_FILE
fi
if [ "${BACKUP_DAILY}" -gt 0 ]; then
  echo "50 0 * * * /backup.sh daily >$LOG_FILE" >>/etc/crontabs/root
  echo "Daily backup job created!" >$LOG_FILE
fi
if [ "${BACKUP_WEEKLY}" -gt 0 ]; then
  echo "50 11 * * 0 /backup.sh weekly >$LOG_FILE" >>/etc/crontabs/root
  echo "Weekly backup job created!" >$LOG_FILE
fi
if [ "${BACKUP_MONTHLY}" -gt 0 ]; then
  echo "50 12 1 * * /backup.sh monthly >$LOG_FILE" >>/etc/crontabs/root
  echo "Monthly backup job created!" >$LOG_FILE
fi
if [ "${BACKUP_YEARLY}" -gt 0 ]; then
  echo "50 13 1 1 * /backup.sh yearly >$LOG_FILE" >>/etc/crontabs/root
  echo "Yearly backup job created!" >$LOG_FILE
fi

# start cron - we should be done!
/usr/sbin/crond -f
