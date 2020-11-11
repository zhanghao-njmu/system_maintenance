#!/usr/bin/env bash
######################### Parameters ##########################################
backup_arr=("/")
exclude_arr=("/dev" "/media" "/mnt" "/proc" "/run" "/sys" "/tmp" "/var/tmp")
restic_repo="/mnt/usb2/tmp/restic/"
RESTIC_PASSWORD="b206shalab"
###############################################################################

restic &>/dev/null
[ $? -eq 127 ] && {
    echo -e "Cannot find the command restic.\n"
    exit 1
}

if [[ ! -d $restic_repo ]]; then
    echo -e "ERROR! Cannot find the repository directory: $restic_repo"
    exit 1
fi

export RESTIC_PASSWORD=$RESTIC_PASSWORD
restic -r $restic_repo check &>/dev/null
if [[ $? != 0 ]]; then
    echo -e "ERROR! restic check failed for the repository directory: $restic_repo"
    exit 1
fi

####### Start preocessing #######
logfile=$restic_repo/Backup.log

SECONDS=0
echo -e "****************** Start Backup ******************" &>>$logfile
echo -e ">>> Backup start at $(date +'%Y-%m-%d %H:%M:%S')" &>>$logfile
echo -e ">>> Backup targets: ${backup_arr[*]}" &>>$logfile
echo -e ">>> Backup targets excluding: ${exclude_arr[*]}\n" &>>$logfile

exclude_par=$(printf -- ",%s" "${exclude_arr[@]}")
cmd="restic -r $restic_repo backup --quiet --exclude={${exclude_par%,}} ${backup_arr[*]} "
#echo "$cmd"
eval $cmd &>>$logfile

if [[ $? != 0 ]]; then
    echo -e "Backup failed: ${backup_arr[*]}\n" &>>$logfile
    ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
    echo -e "$ELAPSED" &>>$logfile
    echo -e "****************** Backup Failed ******************\n\n\n" &>>$logfile
    exit 1
fi

ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo -e "$ELAPSED" &>>$logfile
echo -e "****************** Backup successfully completed ******************\n\n\n" &>>$logfile
