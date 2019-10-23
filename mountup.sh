#!/bin/bash
echo -e "Starting mountup.sh"
USER=max #user name goes here
GROUP=max #group name goes here
SET_DIR=~/zenmounts/sets
# Make Work Dirs
sudo mkdir -p /opt/sharedrives
sudo chown -R $USER:$GROUP /opt/sharedrives
sudo chmod -R 775 /opt/sharedrives
# Create and place service files
export user=$USER group=$GROUP
envsubst '$user,$group' <./input/teamdrive@.service >./output/teamdrive@.service
envsubst '$user,$group' <./input/teamdrive_primer@.service >./output/teamdrive_primer@.service
envsubst '$user,$group' <./input/teamdrive_primer@.timer >./output/teamdrive_primer@.timer
#copynewfiles
sudo bash -c 'cp ./output/teamdrive@.service /etc/systemd/system/teamdrive@.service'
sudo bash -c 'cp ./output/teamdrive_primer@.service /etc/systemd/system/teamdrive_primer@.service'
sudo bash -c 'cp ./output/teamdrive_primer@.timer /etc/systemd/system/teamdrive_primer@.timer'
# enable new services
sudo systemctl enable teamdrive@.service
sudo systemctl enable teamdrive_primer@.service
sudo systemctl enable teamdrive_primer@.timer
#
# Note that count default starting number=5575
# Read the current port no to be used then increment by +1
get_port_no_count () {
  read count < port_no.count
  echo $(($count+1)) > port_no.count
}

# config files
make_config () {
  for set_file in $@; do echo Set file is $set_file
    column -t $SET_DIR/$set_file|sed '/^\s*#.*$/d'|\
    while IFS=' ' read -r name other;do
      get_port_no_count
      conf="
      RCLONE_RC_PORT=$count
      SOURCE_REMOTE=$name:
      DESTINATION_DIR=/mnt/sharedrives/$name/
      ";
      echo "$conf" > /opt/sharedrives/$name.conf
      echo /opt/sharedrives/$name.conf
    done
  done
}

make_starter () {
  for set_file in $@; do echo Set file is $set_file
    column -t $SET_DIR/$set_file|sed '/^\s*#.*$/d'|\
    while IFS=' ' read -r name other;do
      echo "sudo systemctl enable teamdrive@$name.service && sudo systemctl enable teamdrive_primer@$name.service">>vfs_starter.sh
    done
    column -t $SET_DIR/$set_file|sed '/^\s*#.*$/d'|\
    while IFS=' ' read -r name other;do
      echo "sudo systemctl start teamdrive@$name.service && sudo systemctl start teamdrive_primer@$name.service">>vfs_starter.sh
    done
  done
}

make_vfskill () {
  for set_file in $@; do echo Set file is $set_file
    column -t $SET_DIR/$set_file|sed '/^\s*#.*$/d'|\
    while IFS=' ' read -r name other;do
      echo "sudo systemctl stop teamdrive@$name.service && sudo systemctl stop teamdrive_primer@$name.service">>vfs_kill.sh
    done
    column -t $SET_DIR/$set_file|sed '/^\s*#.*$/d'|\
    while IFS=' ' read -r name other;do
      echo "sudo systemctl disable teamdrive@$name.service && sudo systemctl disable teamdrive_primer@$name.service">>vfs_kill.sh
    done
  done
}

make_config $@
make_starter $@
# daemon reload
sudo systemctl daemon-reload
make_vfskill $@
chmod +x vfs_starter.sh
./vfs_starter.sh  #fire the starter
echo "sharedrive vfs mounts complete"
echo "now edit mergerfs service"