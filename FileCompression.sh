#!/usr/bin/env bash
######################### Parameters ##########################################
data_dir="/ssd"
filetype_tocompress=("fastq" "fq" "vcf" "sam")
threads=16
###############################################################################

samtools &>/dev/null
[ $? -eq 127 ] && {
    echo -e "Cannot find the command samtools.\n"
    exit 1
}

####### Start preocessing #######
script_folder=$(dirname $(readlink -f "$0"))
logfile=$script_folder/FileCompression.log
error_pattern="(error)|(fatal)|(corrupt)|(interrupt)|(EOFException)|(no such file or directory)"

SECONDS=0
echo -e "\n\n****************** Start Compression ******************" &>>$logfile
echo -e ">>> Compression start at $(date +'%Y-%m-%d %H:%M:%S')" &>>$logfile
echo -e "File types to compress: ${filetype_tocompress[*]}" &>>$logfile

if [[ " ${filetype_tocompress[*]} " == *" sam "* ]]; then
    filetype_tocompress=("${filetype_tocompress[@]/sam/}")
    for filetype in "${filetype_tocompress[@]}"; do
        [[ $filetype != "sam" ]] && new_array+=($filetype)
    done
    filetype_tocompress=("${new_array[@]}")
    unset new_array
    arr=($(find "$data_dir" -type f | grep -iP ".*.sam$"))
    for file in "${arr[@]}"; do
        if [[ ! -L $file ]] && [[ -f $file ]]; then
            echo -e "*** The file will be convert to BAM:\n$file" &>>$logfile | tee -a ${file}.compress.log
            prefix=${file%%.sam}
            samtools view -@ $threads -Shb $file -o ${prefix}.bam &>>$logfile | tee -a ${file}.compress.log

            if [[ ! $(grep -iP "${error_pattern}" "${file}.compress.log") ]]; then
                rm -f $file
                echo -e "SAM-to-BAM conversion completed. New bam file:\n${prefix}.bam" &>>$logfile | tee -a ${file}.compress.log
            else
                echo -e "ERROR! SAM-to-BAM conversion failed:\n$file" &>>$logfile | tee -a ${file}.compress.log
            fi
        fi
    done
fi

regex=$(printf -- "(.*.%s$)|" "${filetype_tocompress[@]}")
regex=${regex%|}
arr=($(find "$data_dir" -type f | grep -iP "$regex"))
if [[ ${#arr[@]} != 0 ]]; then

    for file in "${arr[@]}"; do
        if [[ ! -L $file ]] && [[ -f $file ]]; then
            echo -e "*** The file will be gzipped:\n$file" &>>$logfile | tee -a ${file}.compress.log
            pigz -p $threads -f $file &>>$logfile | tee -a ${file}.compress.log
            if [[ ! $(grep -iP "${error_pattern}" "${file}.compress.log") ]]; then
                echo -e "Compression completed. New gzipped file:\n${file}.gz" &>>$logfile | tee -a ${file}.compress.log
            else
                echo -e "ERROR! Compression failed:\n$file" &>>$logfile | tee -a ${file}.compress.log
            fi
        fi
    done
else
    echo -e "No file need to be compressed.\nCompression completed.\n" &>>$logfile
fi

ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo -e "$ELAPSED" &>>$logfile
echo -e "****************** Compression successfully completed ******************\n\n" &>>$logfile
