#!/usr/bin/bash
data_dir="/ssd"
filetype_togz=("fastq" "fq" "vcf")
threads=16

samtools --version &>/dev/null
[ $? -ne 0 ] && {
    echo -e "Cannot find the command samtools.\n"
    exit 1
}

####### Start preocessing #######
shell_folder=$(dirname $(readlink -f "$0"))
logfile=$shell_folder/File_Compression.log
error_pattern="(error)|(fatal)|(corrupt)|(interrupt)|(EOFException)|(no such file or directory)"

SECONDS=0
echo -e "\n\n****************** Start Compression ******************" &>>$logfile
echo -e ">>> Compression start at $(date)" &>>$logfile
echo -e "Compression type: sam ${filetype_togz[*]}" &>>$logfile

arr=($(find "$data_dir" -type f | grep -iP ".*.sam$"))
for file in "${arr[@]}"; do
    if [[ ! -L $file ]] && [[ -f $file ]]; then
        echo -e "*** The file will be convert to BAM:\n$file" &>>$logfile | tee -a ${file}.toBam.log
        prefix=${file%%.sam}
        samtools view -@ $threads -Shb $file -o ${prefix}.bam &>>$logfile | tee -a ${file}.toBam.log

        if [[ ! $(grep -iP "${error_pattern}" "${file}.toBam.log") ]]; then
            rm -f $file
            echo -e "SAM-to-BAM conversion completed. New bam file:\n${prefix}.bam" &>>$logfile | tee -a ${file}.toBam.log
        else
            echo -e "ERROR! SAM-to-BAM conversion failed:\n$file" &>>$logfile | tee -a ${file}.toBam.log
        fi
    fi
done

regex=$(printf -- "(.*.%s$)|" "${filetype_togz[@]}")
regex=${regex%|}
arr=($(find "$data_dir" -type f | grep -iP "$regex"))
for file in "${arr[@]}"; do
    if [[ ! -L $file ]] && [[ -f $file ]]; then
        echo -e "*** The file will be gzipped:\n$file" &>>$logfile | tee -a ${file}.togz.log
        pigz -p $threads -f $file &>>$logfile | tee -a ${file}.togz.log
        if [[ ! $(grep -iP "${error_pattern}" "${file}.togz.log") ]]; then
            echo -e "Compression completed. New gzipped file:\n${file}.gz" &>>$logfile | tee -a ${file}.togz.log
        else
            echo -e "ERROR! Compression failed:\n$file" &>>$logfile | tee -a ${file}.togz.log
        fi
    fi
done

ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo -e "\n$ELAPSED" &>>$logfile
echo -e "****************** Compression Done ******************\n\n" &>>$logfile
