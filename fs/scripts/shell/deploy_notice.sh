#!/bin/bash
_author_='shensg'

# set -x

function finally_notice() {
    title=$1
    text=$2
    webhook=$3
    # 飞书
    curl -X POST "https://open.feishu.cn/open-apis/bot/v2/hook/${webhook}" \
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
}


# echo $CI_JOB_STARTED_AT $CI_PROJECT_NAME $GITLAB_USER_NAME $CI_PIPELINE_ID $CI_COMMIT_REF_NAME $CI_PROJECT_URL $CI_JOB_STATUS $CI_COMMIT_MESSAGE

gitlab_user=""
gitlab_commit_message=""
# username
#for n in $${GITLAB_USER_NAME};do
#    gitlab_user+=$n
#done
# commit message
for m in $CI_COMMIT_MESSAGE;do
    gitlab_commit_message+=$m
done


# 获取构建时长
now_time=`date --date="${CI_JOB_STARTED_AT}" +'%s'`
acc_time=`date +%s`
(( use_time = acc_time - now_time ))
use_time=`date -d @$use_time "+%M分%S秒"`

webhook=${2}

# 设置状态、标题和文本内容
title=''
text=''
msg_access=''

# 红色：img_v3_025s_6be37f73-896f-4b0f-950f-533decfeff9g
# 绿色：img_v3_025s_bdc4954d-e00b-4d4f-9b01-0d1eaf3d0ddg
# 通知内容
msg_access+="--------------------------\n"
msg_access+=">发布项目名称：${CI_PROJECT_NAME}\n"
msg_access+=">构建耗时：${use_time}\n"
msg_access+=">提交人：${GITLAB_USER_NAME}\n"
msg_access+=">构建编号：${CI_PIPELINE_ID}\n"
msg_access+=">提交信息：${gitlab_commit_message}\n"
msg_access+=">构建分支：${CI_COMMIT_REF_NAME}\n"
msg_access+=">构建状态：${1}...${CI_JOB_STATUS}\n"
msg_access+="查看流水线详情：${CI_PROJECT_URL}/pipelines/${CI_PIPELINE_ID}\n"

# 筛选通知内容
text+='>>通知内容：\n'$msg_access

if [[ ${CI_JOB_STATUS} != "success" ]]; then
    title="<<<<<告警通知>>>>>"
    image="img_v3_025s_6be37f73-896f-4b0f-950f-533decfeff9g"
else
    title="<<<<<发布通知>>>>>"
    image="img_v3_025s_bdc4954d-e00b-4d4f-9b01-0d1eaf3d0ddg"
fi

# shell发送通知信息
# finally_notice "$title" "$text" "$webhook"


# 调用python发送通知内容
content=""

# 筛选通知内容
if [[ ${CI_JOB_STATUS} != "success" ]]; then
    title="告警通知"
    image="img_v3_025s_6be37f73-896f-4b0f-950f-533decfeff9g"
else
    title="发布通知"
    image="img_v3_025s_bdc4954d-e00b-4d4f-9b01-0d1eaf3d0ddg"
fi

content="发布项目名称：${CI_PROJECT_NAME}
构建耗时：${use_time}
提交人：${GITLAB_USER_NAME}
构建编号：${CI_PIPELINE_ID}
提交信息：${gitlab_commit_message}
构建分支：${CI_COMMIT_REF_NAME}
构建状态：${1}...${CI_JOB_STATUS}
[查看流水线详情](${CI_PROJECT_URL}/pipelines/${CI_PIPELINE_ID})"

# 发送通知信息
#python3 /data/scripts/notice.py "$image" "$content" "$webhook"
/bin/bash -c "python3 <(curl -sSL https://raw.githubusercontent.com/shensg/job/master/fs/scripts/notice-feishu.py) \"$image\" \"$title\" \"$content\" \"$webhook\""
