#!/bin/bash
##
# 清理项目备份，保留3个版本备份
##

# 保留的数量
remain_num=5

#find /mnt/data/ -mindepth 2 -maxdepth 2 -type d -name "${1}_bak_*[0-9]"

tag_list=$(/usr/bin/ls -lh ${1} | grep -i "${2}_bak_" | awk '{print $NF}')
total_num=$(/usr/bin/ls -lh ${1} | grep -i "${2}_bak_" | awk '{print $NF}' | wc -l)
(( clean_num = total_num - remain_num ))

if [ $clean_num -gt 0 ];then
    for name in ${tag_list[@]};do
        if [ $clean_num -gt 0 ]; then
            echo "清理项目备份：${1}/$name"
            rm -rf ${1}/$name
	else
            break
        fi
        (( clean_num = clean_num - 1 ))
    done
fi