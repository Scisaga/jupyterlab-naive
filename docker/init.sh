#!/bin/bash

export SHELL=/bin/bash

export PATH="/opt/venv/bin:$PATH"

log_file="/opt/jupyter_server.log"
echo "`date '+%Y-%m-%d %H:%M:%S,%3N'` - Init - INFO - start init sequence" >> ${log_file}

# pypi repo
python -m pip config set global.index-url ${pypi_repo}
python -m pip config set global.extra-index-url https://pypi.tuna.tsinghua.edu.cn/simple
echo "`date '+%Y-%m-%d %H:%M:%S,%3N'` - Init - INFO - pypi source set" >> ${log_file}

# logviewer
cd /opt/logviewer && python server.py --host 0.0.0.0 --prefix /opt &
echo "`date '+%Y-%m-%d %H:%M:%S,%3N'` - Init - INFO - logviewer started" >> ${log_file}

# jupyter lab
exec jupyter lab \
    --ip=0.0.0.0 \
    --allow-root \
    --ServerApp.base_url="${JUPYTER_BASE_URL}" \
    --ServerApp.token=${JUPYTER_TOKEN} \
    --ResourceUseDisplay.mem_limit=$((MEM*1024*1024*1024)) \
    --ResourceUseDisplay.cpu_limit=${CPUS} \
    --ResourceUseDisplay.track_cpu_percent=True &> /opt/jupyter_lab.log &
    
if [ $? -eq 0 ]; then
    echo "`date '+%Y-%m-%d %H:%M:%S,%3N'` - Init - INFO - Jupyter Lab started" >> ${log_file}
else
		echo "`date '+%Y-%m-%d %H:%M:%S,%3N'` - Init - INFO - Jupyter Lab go west" >> ${log_file}
fi

tail -f /dev/null
