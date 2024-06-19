#!/usr/bin/env bash
_author_='shensg'

#
# OpenLDAP备份
#

#set -x

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

#fs-devops-ldap-center
# 设置通知类型和webhoob。'feishu'表示飞书群机器人,'qywx'表示企业微信群机器人，'dingding'表示钉钉群机器人
notice_type='feishu'
webhoob="$1"

# 获取现在时间的时间戮
now_time=`date +%s`
today=`date +%Y%m%d%H%M`

# 收集群机器人的通知信息
msg_access='主机：fs-devops-ldap-center\n'
msg_error=''

# 载入环境变量
. /etc/profile

# 备份OpenLDAP数据
echo '* 开始备份OpenLDAP数据' &&
/sbin/slapcat -v -l  /home/ldapbackup/${today}_ldapbackup.ldif &&
gzip /home/ldapbackup/${today}_ldapbackup.ldif &&
echo '* 备份成功' || msg_error+="OpenLDAP备份异常\n"
echo

# 获取文件的名称
file_name=$(basename /home/ldapbackup/${today}_ldapbackup.ldif.gz) &&
echo "* 备份文件：$file_name" &&
msg_access+="备份文件：$file_name\n"
echo

# 计算文件的大小
file_size=$(ls -lh /home/ldapbackup/${today}_ldapbackup.ldif.gz | gawk '{print$5}') &&
echo "* 文件大小：$file_size" &&
msg_access+="文件大小：$file_size\n"
echo

# 准备异地备文件
rm -f /home/ldapbackup/remote/*.gz
cp -f /home/ldapbackup/${today}_ldapbackup.ldif.gz /home/ldapbackup/remote/${today}_ldapbackup.ldif.gz

# 获取备份耗时
acc_time=`date +%s`
(( use_time = acc_time - now_time ))
use_time=`date -d @$use_time "+%M分%S秒"`
echo "* 备份耗时：$use_time" && msg_access+="备份耗时：$use_time\n"

# 发送通知
notice "$msg_access" "$msg_error" "$webhoob" "$notice_type"

# 保留数据
find /home/ldapbackup/ -maxdepth 1 -mindepth 1 -type f -ctime +2 -exec rm -f {} \;
