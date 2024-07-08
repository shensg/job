# -*- coding: utf-8 -*-

__author__ = 'shensg168@gmail.com'

import os
import sys
import json
import requests
import socket
import pymysql
import subprocess
import time
from datetime import datetime

db_key = "database"  # database以库为单位备份，table以表为单位备份
webhook = ""  # 机器人，目前是飞书
key = 60  # 备份保留天数

# MySQL信息
user = ""
password = ""
port = 3306
host = ""
charset = ""
database = ""
backup_path = "/data/backup/mysql/dev"

# 初始化MySQL信息
db_config = {
    "user": user,
    "password": password,
    "port": port,
    "host": host,
    "charset": charset,
    "database": database,
    "init_command": "use master"
}

# 开始时间
now_time = int(time.time())
# 备份主机名
hostname = socket.gethostname()


def mkdir(path):
    """判断文件夹是否存在，不存在则创建"""
    isExists = os.path.exists(path)
    if not isExists:
        os.makedirs(path)


def rm(path, key, message):
    """删除 key 天前的文件"""
    f = list(os.listdir(path))
    for i in range(len(f)):
        filedate = os.path.getmtime(path + f[i])
        t_time = datetime.fromtimestamp(filedate).strftime('%Y-%m-%d')
        t_date = time.time()
        num = (t_date - filedate) / 60 / 60 / 24
        if num >= key:
            os.remove(path + f[i])
            print("* 已删除文件：" + f[i])
            message['access'].append("删除文件：%s" % f[i])


def elapsedtime(now_time, end_time):
    """计算耗时"""
    use_time = end_time - now_time

    hours = use_time // 3600
    minutes = (use_time - hours * 3600) // 60
    seconds = use_time - hours * 3600 - minutes * 60

    if hours > 0:
        return str(hours) + "小时" + str(minutes) + "分" + str(seconds) + "秒"
    elif minutes > 0:
        return str(minutes) + "分" + str(seconds) + "秒"
    else:
        return str(seconds) + "秒"


def notice(image, content, webhook):
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
            }]
    })
    url = "https://open.feishu.cn/open-apis/bot/v2/hook/" + webhook
    body = json.dumps({"msg_type": "interactive", "card": card})
    headers = {"Content-Type": "application/json"}
    res = requests.post(url=url, data=body, headers=headers)
    print(res.text)


try:
    path = backup_path + '/' + database
    mkdir(path)
    """备份数据库"""
    if db_key == "table":
        conn = pymysql.connect(**db_config)
        cursor = conn.cursor()
        SHOW_TABLE_SQL = """SHOW TABLES"""
        cursor.execute(SHOW_TABLE_SQL)
        r = cursor.fetchall()
        # 按表备份
        for i in range(len(list(r))):
            BACKUP_MYSQL_TABLE = """/usr/bin/mysqldump -h{} -u{} -p{} {} {} > {}/{}/{}.sql""".format(
                host, user, password, database, list(r)[i][0], backup_path, database, list(r)[i][0])
            try:
                retcode = subprocess.call(BACKUP_MYSQL_TABLE, shell=True)
                # break
                if retcode > 0:
                    print("backup failed")
                    sys.exit(777)
                else:
                    print("backup success")
            except OSError as e:
                print(e)
        cursor.close()
    elif db_key == "database":
        try:
            BACKUP_MYSQL_DATABASE = """/usr/bin/mysqldump -h{} -u{} -p{} {} > {}/{}/{}.sql""".format(
                host, user, password, database, backup_path, database, database)
            retcode = subprocess.call(BACKUP_MYSQL_DATABASE, shell=True)
            if retcode > 0:
                print("backup failed")
                sys.exit(777)
            else:
                print("backup success")
        except OSError as e:
            print(e)
    # 压缩备份
    today = datetime.now().strftime("%Y-%m-%d-%H%M%S")
    tar_files = """{}/{}_{}.tar.gz""".format(backup_path, database, today)
    TAR_CMD = """tar -czf {} {}/{}""".format(tar_files, backup_path, database)
    subprocess.call(TAR_CMD, shell=True)
    # rm(backup_path, key=60)
    file_name = os.path.basename(tar_files)
    file_size_cmd = """ls -lht %s | awk '{print $5}'""" % tar_files
    stats, file_size = subprocess.getstatusoutput(file_size_cmd)

    subprocess.call("/usr/bin/find %s -mtime +%s -type d -exec rm -rf {} \;" % (backup_path, key), shell=True)
    title = "备份通知"
    image = "img_v3_025s_bdc4954d-e00b-4d4f-9b01-0d1eaf3d0ddg"

except EOFError as e:
    print(e)
    title = "备份告警"
    image = "img_v3_025s_6be37f73-896f-4b0f-950f-533decfeff9g"

end_time = int(time.time())
use_time = elapsedtime(now_time, end_time)
message = """<<<<<<<<<<{}>>>>>>>>>>
#####备份内容：
主机：{}
数据库地址：{}
备份文件：{}
文件大小：{}
备份耗时：{}""".format(title, hostname, host, file_name, file_size, use_time)

notice(image, message, webhook)
