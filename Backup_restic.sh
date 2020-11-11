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
if [[ $? != 0 ]];then
    echo -e "ERROR! restic check failed for the repository directory: $restic_repo"
    exit 1
fi

####### Start preocessing #######
logfile=$restic_repo/Backup.log
error_pattern="(error)|(fatal)|(corrupt)|(interrupt)|(EOFException)|(no such file or directory)"

SECONDS=0
echo -e "****************** Start Backup ******************" &>>$logfile
echo -e ">>> Backup start at $(date +'%Y-%m-%d %H:%M:%S')" &>>$logfile
echo -e ">>> Backup destinations: ${backup_arr[*]}\n" &>>$logfile
echo -e ">>> Backup exclude: ${exclude_arr[*]}\n" &>>$logfile

exclude_par=$(printf -- " --exclude '%s'" "${exclude_arr[@]}")
for dest in "${backup_arr[@]}"; do
    echo -e "*** Make a backup for the destination: $dest" &>>$logfile
    bkfile=${dest#/}
    bkfile=${bkfile//\//.}.tar.gz
    tar $exclude_par -cpPf - $dest 2>>$logfile | pigz -9 -p $threads >$backup_dir/$bkfile 2>>$logfile

    if [[ ! $(grep -iP "${error_pattern}" "$logfile") ]]; then
        echo -e "Backup completed: $dest\n" &>>$logfile
    else
        echo -e "Backup failed: $dest\n" &>>$logfile
        echo -e "****************** Backup Failed ******************\n\n\n" &>>$logfile
        cat $logfile >>$targz_repo/Backup.log
        rm -rf $backup_dir
        exit 1
    fi

done

ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo -e "$ELAPSED" &>>$logfile
echo -e "****************** Backup successfully completed ******************\n\n\n" &>>$logfile
cat $logfile >>$targz_repo/Backup.log
