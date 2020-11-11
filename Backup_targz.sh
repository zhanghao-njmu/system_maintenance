#!/usr/bin/env bash
######################### Parameters ##########################################
backup_arr=("/boot" "/data" "/etc" "/home" "/opt" "/reference" "/root" "/srv" "/usr" "/var")
exclude_arr=("")
targz_repo="/mnt/usb2/backup"
bkNumber=7
threads=16
###############################################################################

pigz --version &>/dev/null
[ $? -eq 127 ] && {
    echo -e "Cannot find the command pigz.\n"
    exit 1
}

if [[ ! -d $targz_repo ]]; then
    echo -e "ERROR! Cannot find the repository directory: $targz_repo"
    exit 1
fi

####### Start preocessing #######
backup_dir=$targz_repo/$(date +"%Y-%m-%d-%H.%M.%S")
logfile=$backup_dir/Backup.log
error_pattern="(error)|(fatal)|(corrupt)|(interrupt)|(EOFException)|(no such file or directory)"

if [[ $(ls -A $targz_repo) != "" ]]; then
    if (($(ls -d $targz_repo/*/ | wc -l) >= $bkNumber)); then
        rm_num=$(($(ls -d $targz_repo/*/ | wc -l) - $bkNumber + 1))
        ls -dt $targz_repo/*/ | tail -$rm_num | xargs -i rm -rf {}
    fi
fi

mkdir -p $backup_dir

SECONDS=0
echo -e "****************** Start Backup ******************" &>>$logfile
echo -e ">>> Backup start at $(date +'%Y-%m-%d %H:%M:%S')" &>>$logfile
echo -e ">>> Backup destinations: ${backup_arr[*]}\n" &>>$logfile

exclude_par=$(printf -- " --exclude '*%s*'" "${exclude_arr[@]}")
for dest in "${backup_arr[@]}"; do
    echo -e "*** Make a backup for the destination: $dest" &>>$logfile
    bkfile=${dest#/}
    bkfile=${bkfile//\//.}.tar.gz
    tar $exclude_par -cpPf - $dest  2>>$logfile | pigz -9 -p $threads >$backup_dir/$bkfile 2>>$logfile

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
