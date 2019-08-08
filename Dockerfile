FROM alpine

LABEL maintainer="Thankyou Payroll<development@thankyoupayroll.co.nz>"

VOLUME /backup
VOLUME /data

ENV BACKUP_NAME=localhost
ENV BACKUP_SOURCE=/data
ENV BACKUP_OPTS=one_fs=1
ENV BACKUP_HOURLY=0
ENV BACKUP_DAILY=3
ENV BACKUP_WEEKLY=3
ENV BACKUP_MONTHLY=3
ENV BACKUP_YEARLY=3

RUN touch /ssh-id && touch /backup.cfg && touch /rsnapshot-docker.log

RUN ln -sf /proc/1/fd/1 /rsnapshot-docker.log

RUN apk add --update rsnapshot

ADD entry.sh /entry.sh
ADD backup.sh /backup.sh
RUN chmod +x /backup.sh
RUN chmod +x /entry.sh

CMD ["/entry.sh"]
