FROM alpine

LABEL maintainer="Thankyou Payroll<development@thankyoupayroll.co.nz>"

VOLUME /backup
VOLUME /data

RUN touch /ssh-id && touch /backup-docker.log

RUN ln -sf /proc/1/fd/1 /backup-docker.log

RUN apk update && apk add rsync openssh zip

ADD vars.sh /vars.sh
ADD entry.sh /entry.sh
ADD backup.sh /backup.sh
RUN chmod +x /backup.sh
RUN chmod +x /entry.sh

CMD ["/entry.sh"]
