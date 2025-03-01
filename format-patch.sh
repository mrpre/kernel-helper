#!/bin/bash

workspace="$HOME/.patchjob/"
mkdir -p ${workspace}
echo "####"
echo "current saved job: " && ls ${workspace}
echo "####"
read -p "Choose/Create a job name, used to save/display history: " jobname

old_var_file=${workspace}${jobname}
if [ -f ${old_var_file} ];then
    source ${old_var_file}
fi

read -p "patch version [1,2..] (default: ${old_version}): " version
version=${version:-$old_version}

read -p "branch [bpf,net,bpf-next...] (default: ${old_branch}): " branch
branch=${branch:-$old_branch}

read -p "how many commit to be formated [1,2,3...] (default: ${old_commitcnt}): " commitcnt
commitcnt=${commitcnt:-$old_commitcnt}

dstdir=""
read -p "target patchsets dir (default: ${old_dstdir}): " dstdir
dstdir=${dstdir:-$old_dstdir}

coverletter=""
read -p "need cover letter [Y/N] (default: y): " input
case $input in
  [Nn]) coverletter="" ;;
  *) coverletter="--cover-letter" ;;
esac

gitcmd="git format-patch ${coverletter} --subject-prefix=\"PATCH ${branch}\" HEAD~${commitcnt} -v${version} -o ${dstdir}"
echo ${gitcmd}

eval $gitcmd

if [ -n $coverletter ]; then
    read -p "subject of cover letter (default: ${old_cover_letter_subject}): " cover_letter_subject
    cover_letter_subject=${cover_letter_subject:-$old_cover_letter_subject}

    read -p "file contain the detail of cover letter (default: ${old_cover_letter_file}): " cover_letter_file
    cover_letter_file=${cover_letter_file:-$old_cover_letter_file}

    target_file=`find $dstdir -maxdepth 1 -name '*-0000-cover-letter.patch' -print -quit`
    if [ -n "$cover_letter_subject" ]; then
        content=$cover_letter_subject
        if [ -n $target_file ];then
            sed -i  "s/\*\*\* SUBJECT HERE \*\*\*/$content/g" $target_file
        fi
    fi
    if [ -n "$cover_letter_file" ]; then
        content=`cat $cover_letter_file`
        if [ -n $target_file ];then
            line=`grep -n "BLURB HERE" $target_file | awk -F ":" '{print $1}'`
            sed -i "${line}r $cover_letter_file" $target_file
            sed -i '/BLURB HERE/d' $target_file
        fi
    fi
fi


if [ -n $jobname ]; then
    saved_var="${workspace}${jobname}"
    touch ${saved_var}
    echo "saving current var into $saved_var ..."
    echo "old_version=${version}" > ${saved_var}
    echo "old_branch=${branch}" >> ${saved_var}
    echo "old_commitcnt=${commitcnt}" >> ${saved_var}
    echo "old_dstdir=${dstdir}" >> ${saved_var}
    echo "old_coverletter=${coverletter}" >> ${saved_var}
    echo "old_cover_letter_subject=\"${cover_letter_subject}\""  >> ${saved_var}
    echo "old_cover_letter_file=${cover_letter_file}" >> ${saved_var}
fi

./scripts/checkpatch.pl --strict ${dstdir}/*
