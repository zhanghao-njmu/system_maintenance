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




mkdir -p $backup_dir

SECONDS=0
echo -e "\n\n****************** Start Backup ******************" &>>$logfile
echo -e ">>> Backup start at $(date)" &>>$logfile
echo -e "Backup destinations: ${backup_arr[*]}\n" &>>$logfile


for dest in "${backup_arr[@]}"; do
    echo -e "*** Make a backup for the destination: $dest" &>>$logfile
    dest_trim=${dest#/}
    dest_trim=${dest_trim//\//__}.tar.gz
    tar -cpf - $dest | pigz -9 -p $threads >$backup_dir/$dest_trim 2>>$logfile
    pigz -t $backup_dir/$dest_trim 2>/dev/null
    if [[ $? != 0 ]]; then
        echo -e "ERROR! Backup failed: $dest" &>>$logfile
        exit 1
    fi

    if [[ ! $(grep -iP "${error_pattern}" "$logfile") ]]; then
        echo -e "Backup completed: $dest" &>>$logfile
    else
        echo -e "ERROR! Backup failed: $dest" &>>$logfile
    fi

done

ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo -e "\n$ELAPSED" &>>$logfile
echo -e "****************** Compression Done ******************\n\n" &>>$logfile
