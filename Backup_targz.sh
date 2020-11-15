#!/usr/bin/env bash
######################### Parameters ##########################################
backup_arr=("/boot" "/etc" "/home" "/opt" "/root" "/srv" "/usr" "/var")
exclude_arr=("")
targz_repo="/archive/system_maintenance/system_backup/"
bkNumber=4
threads=16
broadcast="TRUE"
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
bk_dir=$targz_repo/bk_$(date +"%Y-%m-%d-%H.%M.%S")
logfile=$bk_dir/Backup_individual.log
error_pattern="(error)|(fatal)|(corrupt)|(interrupt)|(EOFException)|(no such file or directory)"

bk_dir_existed=($(find $targz_repo -mindepth 1 -maxdepth 1 -type d -name "bk_*"))
if ((${#bk_dir_existed[*]} >= 1)); then
    if (($(ls -d $targz_repo/bk_*/ | wc -l) >= $bkNumber)); then
        rm_num=$(($(ls -d $targz_repo/bk_*/ | wc -l) - $bkNumber + 1))
        ls -dt $targz_repo/bk_*/ | tail -$rm_num | xargs -i rm -rf {}
    fi
fi

mkdir -p $bk_dir

SECONDS=0
echo -e "****************** Start Backup ******************" &>>$logfile
echo -e ">>> Backup start at $(date +'%Y-%m-%d %H:%M:%S')" &>>$logfile
echo -e ">>> Backup targets: ${backup_arr[*]}" &>>$logfile
echo -e ">>> Backup targets excluding: ${exclude_arr[*]}\n" &>>$logfile

exclude_par=$(printf -- " --exclude '%s'" "${exclude_arr[@]}")
for target in "${backup_arr[@]}"; do
    echo -e "*** Make a backup for the target: $target" &>>$logfile
    bkfile=${target#/}
    bkfile=${bkfile//\//.}.tar.gz
    tar $exclude_par -cpPf - $target 2>>$logfile | pigz -9 -p $threads >$bk_dir/$bkfile 2>>$logfile

    if [[ ! $(grep -iP "${error_pattern}" "$logfile") ]]; then
        echo -e "Backup completed: $target\n" &>>$logfile
    else
        echo -e "Backup failed: $target\n" &>>$logfile
        ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
        echo -e "$ELAPSED" &>>$logfile
        echo -e "****************** Backup failed ******************\n\n\n" &>>$logfile
        cat $logfile >>$targz_repo/AllBackup.log
        rm -rf $bk_dir
        if [[ $broadcast == "TRUE" ]]; then
            echo -e "\n>>> Backup_targz(${backup_arr[*]}): $(date +'%Y-%m-%d %H:%M:%S') Backup failed! Please check the log: $targz_repo/AllBackup.log\n" >>/etc/motd
        fi
        exit 1
    fi
done

ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo -e "$ELAPSED" &>>$logfile
echo -e "****************** Backup successfully completed ******************\n\n\n" &>>$logfile
cat $logfile >>$targz_repo/AllBackup.log
if [[ $broadcast == "TRUE" ]]; then
    echo -e "\n>>> Backup_targz(${backup_arr[*]}): $(date +'%Y-%m-%d %H:%M:%S') Backup successfully completed!\n" >>/etc/motd
fi
