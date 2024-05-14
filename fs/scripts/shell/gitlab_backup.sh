#!/bin/bash
_author_='shensg'
#
# 用途：备份gitlab数据
#
# set -x

function notice() {
    # 发消息到飞书、钉钉或企业微信的群机器人 #

    msg_access=$1
    msg_error=$2
    webhoob=$3
    notice_type=$4

    # 设置状态、标题和文本内容
    status=''
    title=''
    text=''

    # 飞书群机器人
    if [[ $notice_type == 'feishu' ]];then
        # 筛选通知内容
        text+='#####备份内容：\n'$msg_access

        if [[ $msg_error != '' ]]; then
            title='<<<<<<<<<<备份警告>>>>>>>>>>'
            text+='#####异常信息：\n'$msg_error
        else
            title='<<<<<<<<<<备份通知>>>>>>>>>>'
        fi
        echo "title: $title"
        echo "text: $text"

        curl -X POST "https://open.feishu.cn/open-apis/bot/v2/hook/${webhoob}" \
            -H "Content-Type: application/json" \
            -d '{
                    "open_ids": [
                        "ou_a18fe85d22e7633852d8104226e99eac"
                    ],
                    "department_ids": [
                        "od-5b91c9affb665451a16b90b4be367efa"
                    ],
                    "msg_type": "post",
                    "content": {
                        "post":{
                            "zh_cn": {
                                "title": "'${title}'",
                                "content": [
                                    [{
                                        "tag": "text",
                                        "text": "'${text}'"
                                    }
                                    ]
                                ]
                            }
                        }
                    }
                }'
    fi
}

# FUSEN 备份机器人
# https://open.feishu.cn/open-apis/bot/v2/hook/

# 设置通知类型和webhoob。'qywx'表示企业微信群机器人，'dingding'表示钉钉群机器人
notice_type='feishu'
webhoob="$1"

# 获取现在时间的时间戮
now_time=`date +%s`

# 收集群机器人的通知信息
msg_access='主机：fs-devops-gitlab-repo\n'
msg_error=''

# 载入环境变量
. /etc/profile

## 移走gitlab旧备份数据
mv /var/opt/gitlab/backups/* /var/opt/gitlab/git-backups/

# 备份gitlab数据
echo '* 开始备份gitlab数据' &&
/usr/bin/gitlab-rake gitlab:backup:create &&
echo '* 备份成功' || msg_error+="gitlab备份异常\n"
echo

# 获取文件的名称
file_name=$(basename /var/opt/gitlab/backups/*_gitlab_backup.tar) &&
echo "* 备份文件：$file_name" &&
msg_access+="备份文件：$file_name\n"
echo

# 计算文件的大小
file_size=$(ls -lh /var/opt/gitlab/backups/*_gitlab_backup.tar | gawk '{print$5}') &&
echo "* 文件大小：$file_size" &&
msg_access+="文件大小：$file_size\n"
echo

# 获取备份耗时
acc_time=`date +%s`
(( use_time = acc_time - now_time ))
use_time=`date -d @$use_time "+%M分%S秒"`
echo "* 备份耗时：$use_time" && msg_access+="备份耗时：$use_time\n"

# 发送通知
notice "$msg_access" "$msg_error" "$webhoob" "$notice_type"

# 保留数据
find /var/opt/gitlab/git-backups/  -maxdepth 1 -mindepth 1 -type f -ctime +10 -exec rm -f {} \;
