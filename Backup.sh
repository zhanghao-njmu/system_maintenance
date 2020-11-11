#!/usr/bin/env bash
######################### Parameters ##########################################
backup_arr=("/boot" "/data" "/etc" "/home" "/opt" "/reference" "/root" "/usr" "/var")
backup_number=7
repo="/mnt/usb2/backup"
threads=16
###############################################################################

pigz --version &>/dev/null
[ $? -eq 127 ] && {
    echo -e "Cannot find the command pigz.\n"
    exit 1
}

if [[ ! -d $repo ]]; then
    echo -e "ERROR! Cannot find the repository directory: $repo"
    exit 1
fi


####### Start preocessing #######
backup_dir=$repo/$(date +"%Y%m%d%H%M%S")
logfile=$backup_dir/Backup.log
error_pattern="(error)|(fatal)|(corrupt)|(interrupt)|(EOFException)|(no such file or directory)"

if (( $(ls -d $repo/*/ | wc -l) >= $backup_number ));then
    rm_num=$(( $(ls -d $repo/*/ | wc -l) - $backup_number + 1 ))
    ls -dt $repo/*/ | tail -$rm_num |xargs -i rm -rf {}
fi

mkdir -p $backup_dir

SECONDS=0
echo -e "****************** Start Backup ******************" &>>$logfile
echo -e ">>> Backup start at $(date)" &>>$logfile
echo -e ">>> Backup destinations: ${backup_arr[*]}\n" &>>$logfile


for dest in "${backup_arr[@]}"; do
    echo -e "*** Make a backup for the destination: $dest" &>>$logfile
    dest_trim=${dest#/}
    dest_trim=${dest_trim//\//.}.tar.gz
    tar -cpPf - $dest | pigz -9 -p $threads >$backup_dir/$dest_trim 2>>$logfile
    pigz -t $backup_dir/$dest_trim 2>/dev/null
    #if [[ $? != 0 ]]; then
        echo -e "Backup failed: $dest\n" &>>$logfile
        echo -e "****************** Backup Failed ******************\n\n\n" &>>$logfile
        cat $logfile >>$repo/Backup.log
        rm -rf $backup_dir
        exit 1
    #fi

    if [[ ! $(grep -iP "${error_pattern}" "$logfile") ]]; then
        echo -e "Backup completed: $dest" &>>$logfile
    else
        echo -e "Backup failed: $dest\n" &>>$logfile
        echo -e "****************** Backup Failed ******************\n\n\n" &>>$logfile
        cat $logfile >>$repo/Backup.log
        rm -rf $backup_dir
        exit 1
    fi

done

ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo -e "\n$ELAPSED" &>>$logfile
echo -e "****************** Backup Done ******************\n\n\n" &>>$logfile
cat $logfile >>$repo/Backup.log
