#!/bin/sh

# rsnapshot uses rsync and cp -al to keep an historical archive with minimal extra storage. in short:

# there's the 'last' copy, let's call it back-0
# the previous copies are called back-1, back-2....
# each copy 'seems' to be a full complete copy, but in fact any unchanged file is stored only once. it appears on several directories using hard links.

# the process is simple, let's say there are currently 4 copies, back-0 through back-3. when rsnapshot is invoked, it:

# deletes the oldest copy: back-3 (rm -r back-3)
# renames back-2 to back-3 (mv back-2 back-3)
# renames back-1 to back-2 (mv back-1 back-2)
# makes a 'link mirror' from back-0 to back-1 (cp -al back-0 back-1) this creates the back-1 directory but insteado of copying each file from back-0 to back-1, it creates a hardlink; in effect, a second reference to the same file. this second name is just as valid as the first one, and the file's data won't be removed from the disk until both names are deleted.
# performs an rsync from the original storage to back-0. since the previous backup was still on back-0, this rsync is very fast (even on remote links, since it transfers only changes). a file that was changed since the previous backup is replaced on back-0 but not on back-1, breaking the link between them, so now you keep both versions. an unchanged file stays shared between both directories and won't require extra storage to keep the previous copies consistent.
# once you get familiar with the procedure, you'll find it very handy. it's not complex at all, sometimes i do it manually to keep sporadic 'previous versions' at interesting points of time (just before an important upgrade, just after installing and configuring a system, etc)

FORMAT="%Y%m%d-%H%M"
TYPE=$1
ROOT_DIR=$(pwd)

source /vars.sh

calculate() {
  local expression=$1
  local result=$(echo "$expression" | bc)
  echo "$result"
}

init_folder() {
  local backup_folder=$1
  local name=$2
  local target="$backup_folder/$name"
  [[ -d $target ]] || mkdir -p $target
  echo "Created: $target"
}

remove_folder() {
  local period_folder=$1
  local snapshot=$2
  local target="$period_folder.$snapshot"
  if [ -d "$target" ]; then
    rm -r $target
    echo "Deleted: $target"
  fi
}

rename_folder() {
  local period_folder=$1
  local snapshot=$2
  local target="$period_folder.$(calculate "$snapshot + 1")"
  local origin="$period_folder.$snapshot"
  if [ -d "$origin" ]; then
    mv $origin $target
    echo "Moved: $origin --> $target"
  fi
}

mirror_folder() {
  local period_folder=$1
  local origin="$period_folder.0"
  local target="$period_folder.1"
  if [ -d "$origin" ]; then
    cp -al "$origin" "$target"
    echo "Mirrored: $origin --> $target"
  else
    mkdir -p $origin
  fi
}

update_backup() {
  local source=$1
  local output=$2
  local remote=$3
  local options=${4:-"-Paxuv --no-o --no-g --no-perms"}
  #echo $options;
  #echo $4;
  if [ "$remote" == true ]; then
    BACKUP_SSH_ARGS=${BACKUP_SSH_ARGS:-"-i /ssh-id -o \"StrictHostKeyChecking no\""}
    rsync $options -e "ssh $BACKUP_SSH_ARGS" $source $output
    echo rsync $options -e "ssh $BACKUP_SSH_ARGS" $source $output
  else
    rsync $options $source $output
  fi
}

secure_compress() {
  local folder=$1
  local output=$2
  local password=$3
  cd "$folder"
  zip -r -P $password "$output" "$folder"
  cd "$ROOT_DIR"
}

case $TYPE in
hourly) BACKUP_LIMIT=$BACKUP_HOURLY ;;
daily) BACKUP_LIMIT=$BACKUP_DAILY ;;
weekly) BACKUP_LIMIT=$BACKUP_WEEKLY ;;
monthly) BACKUP_LIMIT=$BACKUP_MONTHLY ;;
yearly) BACKUP_LIMIT=$BACKUP_YEARLY ;;
*)
  echo "Unknown period. Options: hourly, daily, weekly, monthly, yearly"
  exit 1
  ;;
esac

BACKUP_OUTPUT=$BACKUP_PATH/$BACKUP_NAME/$TYPE
BACKUP_LIMIT=$(calculate "$BACKUP_LIMIT - 1")
FOLDERS_TO_MOVE=$(calculate "$BACKUP_LIMIT - 1")

echo "Backing up: $BACKUP_SOURCE"

init_folder $BACKUP_PATH $BACKUP_NAME

remove_folder $BACKUP_OUTPUT $BACKUP_LIMIT
while [ $FOLDERS_TO_MOVE -gt 0 ]; do
  rename_folder $BACKUP_OUTPUT $FOLDERS_TO_MOVE
  FOLDERS_TO_MOVE=$(calculate "$FOLDERS_TO_MOVE - 1")
done
mirror_folder $BACKUP_OUTPUT

update_backup $BACKUP_SOURCE $BACKUP_OUTPUT.0 $IS_REMOTE $BACKUP_RSYNC_ARGS

if [ "$BACKUP_COMPRESS" = true ]; then
  secure_compress $BACKUP_OUTPUT.0 "$BACKUP_OUTPUT-$(date +"$FORMAT")" $BACKUP_PASSWORD
fi
