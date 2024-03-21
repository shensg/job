#!/usr/bin/env python3
# -*- coding: utf-8 -*-
__author__ = 'shensg'

"""
调用此脚本需要3个特定的参数：
    1、图片的imageKey
    2、具体的发送的内容信息
        1.如果内容需要换行，则使用换行符分割
    3、发送的机器人webhook
    
发布程序通知例子：
bash执行
export image="img_v3_025s_6be37f73-896f-4b0f-950f-533decfeff9g"
export content="**${title}**
==========
发布项目名称：${CI_PROJECT_NAME}
构建耗时：${use_time}
提交人：${GITLAB_USER_NAME}
构建编号：${CI_PIPELINE_ID}
提交信息：${gitlab_commit_message}
构建分支：${CI_COMMIT_REF_NAME}
构建状态：${1}...${CI_JOB_STATUS}
[查看流水线详情](${CI_PROJECT_URL}/pipelines/${CI_PIPELINE_ID})"
export webhook="f8feb224-1234-5678-9000-ef1cd75feb3a"
python3 notice-feishu.py $image $content $webhook
"""

import sys
import requests
import json

def notice(image, title, content, webhook):
    # 告警信息
    card = json.dumps({
        "config": {
            "wide_screen_mode": True
        },
        "elements": [{
            "alt": {
                "content": "",
                "tag": "plain_text"
            },
            "img_key": image,
            "tag": "img"
        },
            {
                "tag": "div",
                "text": {
                    "content": content,
                    "tag": "lark_md"
                }
            }
        ],
        "header": {
            "title": {
                "content": title,
                "tag": "plain_text"
            },
            "template": "red"
        }
    })
    url = "https://open.feishu.cn/open-apis/bot/v2/hook/" + webhook
    body = json.dumps({"msg_type": "interactive", "card": card})
    headers = {"Content-Type": "application/json"}
    res = requests.post(url=url, data=body, headers=headers)
    print(res.text)


if __name__ == '__main__':
    notice(image=sys.argv[1], title=sys.argv[2], content=sys.argv[3], webhook=sys.argv[4])
