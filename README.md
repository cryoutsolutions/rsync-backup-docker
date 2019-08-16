# Rsync Backup in Docker

This Docker image allows you to run a (continuous) Rsync backup.
The logic is to perform a local backup from either a local folder or a remote server.

It allows the following customization:

## Volumes

Using the volume `/backup` you provide the target folder for the backups.
This is mandatory, otherwise backups are done into the ephemeral container disk space.

Using the volume `/data` you can provide the data which shall be backed up.
This is necessary for performing backups from a local folder and can be ignored for remote backups.

## File Mounts

The Docker image also expects a few file mounts. They are optional.

Using the volume `/ssh-id` you can provide at runtime an SSH ID.
This is necessary for performing backups from a remote server and can be ignored for local backups.

## Environment

**BACKUP_NAME**
This is the name of the backup source you are backing up. Default is `localhost` and it will be used as the name of the subfolder (under the `daily.X` etc folders) in the `/backup` volume.

**BACKUP_SOURCE**
This is the name of the backup source you are backing up. Default is `/data` which matches the name of the expected volume for local backups; for remote server backups the syntax should be `user@server:/folder`.

**BACKUP_SSH_ARGS**
This allows you to provide custom values for `ssh`. The default value is `-i /ssh-id -o "StrictHostKeyChecking no"`.

**BACKUP_RSYNC_ARGS**
This allows you to provide custom values for `rsync`. The default value is `-Paxuv --no-owner`.

**BACKUP_HOURLY**
This specifies the number of hourly backups to keep. The default value is `0` which means no hourly backups are performed.

**BACKUP_DAILY**
This specifies the number of daily backups to keep. The default value is `3`.

**BACKUP_WEEKLY**
This specifies the number of weekly backups to keep. The default value is `3`.

**BACKUP_MONTHLY**
This specifies the number of monthly backups to keep. The default value is `3`.

**BACKUP_YEARLY**
This specifies the number of yearly backups to keep. The default value is `3`.

**BACKUP_COMPRESS**
Creates a password protected zip file with the format `[period]-[YYYYmmdd-HHMM].zip`. The default value is`false`.

**BACKUP_PASSWORD**
Customize the password for the zip file. The default value is `password`.

## Example

Perform local backup of `/etc`, into `/srv/backup`, naming it `etc-folder`:

```bash
docker run -d -v /etc:/data \
           -v /srv/backup:/backup \
           -e BACKUP_NAME=etc-folder \
           thankyoupayroll/rsync-backup-docker
```

Perform remote backup of a remote server `example.com`, filesystem `/home` into `/src/backup`, naming it `remote`:

```bash
docker run -d -v $HOME/.ssh/id_rsa:/ssh-id \
           -v /srv/backup:/backup \
           -e BACKUP_NAME=remote \
           -e BACKUP_SOURCE=root@example.com:/home \
           thankyoupayroll/rsync-backup-docker
```

Orchestrate with `docker-compose`

```yml
version: "3.4"
# #############
# DEFAULTS
# #############
x-defaults: &defaults
  restart: unless-stopped
  networks:
    - default
##  For resource limits with docker swarm or using compatibility flag `--compatibility`
#   deploy:
#     resources:
#       limits:
#         cpus: "2"
#         memory: 2048M
#       reservations:
#         memory: 512M
# #############
# SERVICES
# #############
services:
  backup-internal:
    <<: *defaults
    image: thankyoupayroll/rsync-backup-docker
    volumes:
      - /data/to/backup:/data
      - /backup/output/folder:/backup
    environment:
      - BACKUP_NAME=localhost
      # - BACKUP_OPTS=
      # - BACKUP_HOURLY=0
      # - BACKUP_DAILY=3
      # - BACKUP_WEEKLY=3
      # - BACKUP_MONTHLY=3
      # - BACKUP_YEARLY=3
  backup-remote:
    <<: *defaults
    image: thankyoupayroll/rsync-backup-docker
    volumes:
      - /backup/output/folder:/backup
      - ${HOME}/.ssh/id_rsa:/ssh-id
    environment:
      - BACKUP_NAME=remote
      # - BACKUP_OPTS=
      - BACKUP_SOURCE=${REMOTE_USER}@${REMOTE_HOSTNAME}:${REMOTE_FOLDER}
      # - BACKUP_SSH_ARGS=
      # - BACKUP_HOURLY=0
      # - BACKUP_DAILY=3
      # - BACKUP_WEEKLY=3
      # - BACKUP_MONTHLY=3
      # - BACKUP_YEARLY=3
```
