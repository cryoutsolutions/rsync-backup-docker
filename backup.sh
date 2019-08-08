#! /bin/sh

LOG_FILE=/rsnapshot-docker.log
FORMAT="%Y-%m-%d %T"


if [ -z "$1" ]
  then
    echo "No argument supplied" > $LOG_FILE
    exit 1
fi

echo "*********************" > $LOG_FILE
echo "Started at: $(date +"$FORMAT")" > $LOG_FILE
echo "*********************" > $LOG_FILE

rsnapshot -V $1 > $LOG_FILE

echo "*********************" > $LOG_FILE
echo "Finished at: $(date +"$FORMAT")" > $LOG_FILE
echo "*********************" > $LOG_FILE