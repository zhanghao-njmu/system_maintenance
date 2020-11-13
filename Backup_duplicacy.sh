#!/usr/bin/env bash
######################### Parameters ##########################################
snapshot_id="archive_backup"
repository="/archive"
storage="/archive_cold/Backup_duplicacy"
uploading_threads=16
broadcast="TRUE"
###############################################################################

duplicacy &>/dev/null
[ $? -eq 127 ] && {
    echo -e "Cannot find the command duplicacy.\n"
    exit 1
}

if [[ ! -d $repository ]]; then
    echo -e "ERROR! Cannot find the repository directory (the directory to be backed up): $repository"
    exit 1
fi

if [[ ! -d $storage ]]; then
    echo -e "ERROR! Cannot find the storage directory (the directory used to store data): $storage"
    exit 1
fi

cd $repository

duplicacy check &>/dev/null
if [[ $? != 0 ]]; then
    echo -e "ERROR! duplicacy check failed. Please make sure repository or storage has been initialized."
    echo -e "One can use the command to initialize: \nrm -rf $repository/.duplicacy ;duplicacy init -repository $repository $snapshot_id $storage"
    exit 1
fi

####### Start preocessing #######
logfile=$storage/AllBackup.log

SECONDS=0
echo -e "****************** Start Backup ******************" &>>$logfile
echo -e ">>> Backup start at $(date +'%Y-%m-%d %H:%M:%S')" &>>$logfile
echo -e ">>> Backup repository: ${repository}" &>>$logfile
echo -e ">>> Backup storage: ${storage}\n" &>>$logfile

echo -e "*** Make a duplicacy backup for the repository" &>>$logfile
tag="bk_$(date +"%Y-%m-%d-%H.%M.%S")"
cmd="duplicacy backup -storage $storage -threads $uploading_threads -t \"$tag\""

echo -e "*** Run duplicacy command: \n$cmd" &>>$logfile
#echo "$cmd"
eval $cmd &>>$logfile

if [[ $? != 0 ]]; then
    echo -e "Backup failed!\n" &>>$logfile
    ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
    echo -e "$ELAPSED" &>>$logfile
    echo -e "****************** Backup failed ******************\n\n\n" &>>$logfile
    if [[ $broadcast == "TRUE" ]]; then
        echo -e "\n>>> Backup_duplicacy: $(date +'%Y-%m-%d %H:%M:%S') Backup failed! Please check the log: $storage/AllBackup.log\n" >>/etc/motd
    fi
    exit 1
else
    echo -e "Backup completed.\n" &>>$logfile
    ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
    echo -e "$ELAPSED" &>>$logfile
    echo -e "****************** Backup successfully completed ******************\n\n\n" &>>$logfile
fi
