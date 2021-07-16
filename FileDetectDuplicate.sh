#!/usr/bin/env bash
######################### Parameters ##########################################
dir_detect=("/data/lab")
dir_trash="/data/trash"
broadcast="TRUE"
###############################################################################

fdupes --version &>/dev/null
[ $? -eq 127 ] && {
    echo -e "Cannot find the command fdupes.\n"
    exit 1
}

####### Start preocessing #######
mkdir -p $dir_trash
logfile=$dir_trash/FileDetectDuplicate.log

SECONDS=0
echo -e "****************** Start FileDetectDuplicate ******************" &>>$logfile
echo -e ">>> FileDetectDuplicate start at $(date +'%Y-%m-%d %H:%M:%S')" &>>$logfile
echo -e ">>> dir_detect: ${dir_detect[*]}" &>>$logfile
echo -e ">>> dir_trash: $dir_trash\n" &>>$logfile

tmpfile1=$(mktemp /tmp/tmp.XXXXXXXXXXXXXX)
tmpfile2=$(mktemp /tmp/tmp.XXXXXXXXXXXXXX)
for dir_target in "${dir_detect[@]}"; do
    echo -e "*** Detect duplicate files in the dir: $dir_target" &>>$logfile
    fdupes --noempty --nohidden --recurse --quiet $dir_target 1>$tmpfile1 2>>$logfile
    file_array=()
    while read line; do
        if [[ $line != "" ]]; then
            file_array+=("$line")
        else
            firstfile="${file_array[0]}"
            unset 'file_array[0]'
            file_user=$(stat -c '%U' "$firstfile")
            echo -e "user:${file_user}; status:Reserved; file:'${firstfile}'" >>$tmpfile2
            for file in "${file_array[@]}"; do
                file_dir="${file%/*}"
                file_user="$(stat -c '%U' "${file}")"
                mkdir -p $dir_trash/$file_dir
                cp "$file" $dir_trash/$file_dir/
                echo -e ">>> $(date +'%Y-%m-%d %H:%M:%S') \n'$file' has been moved to the dir:$dir_trash/$file_dir\n" >>"${file}".FileDetectDuplicate.log
                echo -e "All same duplicate files:\n$firstfile" >>"${file}".FileDetectDuplicate.log
                printf '%s\n' "${file_array[@]}" >>"${file}".FileDetectDuplicate.log
                echo -e "user:${file_user}; status:   Moved; file:'${file}'" >>$tmpfile2
            done
            file_array=()
        fi
    done <$tmpfile1
done
cat $tmpfile2 >>$logfile

declare -A user_count_dict
declare -A user_file_dict
while IFS=';' read -r user status file; do
    user_count_dict[$user]=$((${user_count_dict[$user]} + 1))
    user_file_dict[$user]="${user_file_dict[$user]}... $status  $file\n"
done <$tmpfile2

for user in $(echo ${!user_count_dict[*]}); do
    echo -e ">>> $(date +'%Y-%m-%d %H:%M:%S') FileDetectDuplicate result:\n${user_file_dict[$user]}" >>$dir_trash/${user##user:}.FileDetectDuplicate.log
    if [[ $broadcast == "TRUE" ]]; then
        echo -e ">>> $(date +'%Y-%m-%d %H:%M:%S') FileDetectDuplicate: User ${user##user:} has ${user_count_dict[$user]} duplicate files detected! Please check the log." >>/etc/motd
    fi
done

rm -f $tmpfile1 $tmpfile2
ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo -e "\n$ELAPSED" &>>$logfile
echo -e "****************** Duplicate detection successfully ******************\n\n\n" &>>$logfile
