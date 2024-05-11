#!/bin/bash
#
_author_='shensg'

STIME=$2
WORKER_DIR="/mnt/data/wwwroot/$1"
REDIS_HOST='redis.hosts'
REDIS_PORT=6379
REDIS_PASS=''

if [[ -z $STIME ]];then
    STIME=60
fi

function clean_cache() {
    echo "Cleaning cache..."
    if [[ -z "$REDIS_PASS" ]];then
        redis-cli -h $REDIS_HOST -p $REDIS_PORT FLUSHALL
    else
        redis-cli -h $REDIS_HOST -p $REDIS_PORT -a "$REDIS_PASS" FLUSHALL
    fi
    echo "Clean cache success..."

}

function stopped() {
    # 直接掉程序
    echo "Application started stopping..."
    py_pid=$(ps -ef | grep "gunicorn -c ${WORKER_DIR}/gunicorn.py -k uvicorn.workers.UvicornH11Worker main:app --daemon" |
    grep -v 'grep' | awk '{print $2}')
    if [[ -n "$py_pid" ]];then
        ps -ef | grep "gunicorn -c ${WORKER_DIR}/gunicorn.py -k uvicorn.workers.UvicornH11Worker main:app --daemon" |
        grep -v 'grep' | awk '{print $2}' | xargs kill -9
        echo "Application is stopped..."
    else
        echo "Application not running..."
    fi
    sleep 2
}

function started() {
    # 启动程序
    echo "Application starting..."
    source /mnt/data/anaconda3/bin/activate py310 && pip uninstall -y -r /mnt/data/scripts/.requirements.txt && pip install -r requirements.txt && python main.py &
    sleep $STIME
    ps -auxf | grep -E "/mnt/data/anaconda3/envs/py310/bin/python -c from multiprocessing|python main.py" | grep -v "grep" | awk '{print $2}' | xargs kill -9
    source /mnt/data/anaconda3/bin/activate py310 && gunicorn -c ${WORKER_DIR}/gunicorn.py -k uvicorn.workers.UvicornH11Worker  main:app --daemon

    py_pid=$(ps -ef | grep "gunicorn -c ${WORKER_DIR}/gunicorn.py -k uvicorn.workers.UvicornH11Worker main:app --daemon" |
    grep -v 'grep' | awk '{print $2}')
    if [[ -n "$py_pid" ]];then
        echo "Application is running..."
    else
        echo "Application running failed..."
    fi
}

# 切换目录
cd ${WORKER_DIR}

# 停止服务
stopped

# 清理缓存
clean_cache

# 启动服务
started
