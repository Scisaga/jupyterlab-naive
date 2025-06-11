# syntax=docker/dockerfile:1.4
FROM nvidia/cuda:12.1.0-cudnn8-runtime-ubuntu22.04

SHELL ["/bin/bash", "-c"]

WORKDIR /opt
VOLUME /opt
ENV LANG=C.UTF-8

# 更换为清华源，加快国内 apt 下载速度
RUN echo $'deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse\n \
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse\n \
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse\n \
deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse' > /etc/apt/sources.list

# 安装通用系统工具
RUN apt update && \
    apt install -qy --no-install-recommends \
      vim wget git xz-utils yarn cron jq nethogs curl ntpdate iputils-ping && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 安装 Python 和 Pip（支持自定义 Python 版本）
# https://www.linuxcapable.com/how-to-install-python-3-10-on-ubuntu-linux/
RUN apt install -y software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt install -y python3.10 python3.10-distutils && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 && \
    update-alternatives --set python3 /usr/bin/python3.10 && \
    apt install -y python-is-python3 && \
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3 && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# S3 文件系统挂载工具
# https://github.com/s3fs-fuse/s3fs-fuse
RUN apt install -y s3fs

# 安装通用 Python 库
RUN pip install wheel

# -------------------- JupyterLab 核心及插件安装 --------------------

# JupyterLab 主程序（使用最新稳定版）
# https://jupyterlab.readthedocs.io/en/stable/
RUN pip install --no-cache-dir jupyterlab==4.4.3

# pipreqs: 自动生成 requirements.txt 文件（基于 import 分析）
# https://github.com/bndr/pipreqs
RUN pip install --no-cache-dir pipreqs pipreqsnb

# 资源监控插件
# https://github.com/jupyter-server/jupyter-resource-usage
RUN pip install --no-cache-dir jupyter-resource-usage==1.1.0

# Git 集成插件（支持 Git 操作可视化）
# https://github.com/jupyterlab/jupyterlab-git
RUN pip install --no-cache-dir --pre jupyterlab-git==0.50.0rc0

# 进度条控件，Jupyter Notebook 内展示进度
# https://github.com/jupyter-widgets/ipywidgets
RUN pip install ipywidgets

# Traitlets：Python 数据描述符框架（Jupyter 内部广泛使用）
# https://github.com/ipython/traitlets
RUN pip install --no-cache-dir traitlets

# AWS SDK for Python
# https://github.com/boto/boto3
RUN pip install --no-cache-dir boto3

# JSON Web Token 加解密库
# https://pyjwt.readthedocs.io/en/stable/
RUN pip install --no-cache-dir pyjwt

# Jupyter LSP：代码补全、跳转、语法提示
# https://github.com/jupyter-lsp/jupyterlab-lsp
RUN pip install --no-cache-dir 'jupyterlab>=4.0.0,<5.0.0a0' jupyterlab-lsp 'python-lsp-server[all]'

# 代码格式化插件（支持 black、isort 等格式化器）
# https://github.com/ryantam626/jupyterlab_code_formatter
RUN pip install --no-cache-dir jupyterlab-code-formatter==2.2.1

# Python 代码格式化器：black
# https://pypi.org/project/black/
RUN pip install --no-cache-dir black

# Python import 自动排序工具：isort
# https://pycqa.github.io/isort/
RUN pip install --no-cache-dir isort[requirements_deprecated_finder]

# 多语言支持（翻译界面）
# https://github.com/jupyterlab/jupyterlab-translate
RUN pip install --no-cache-dir jupyterlab-translate jupyterlab-language-pack-zh-CN

# Plotly 可视化库（支持图形交互）
# https://plotly.com/python/
RUN pip install --no-cache-dir plotly==5.18.0

# 显示代码执行时间的插件（适合教学、性能调优）
# https://github.com/deshaw/jupyterlab-execute-time
RUN pip install --no-cache-dir jupyterlab_execute_time==3.1.0

# 变量查看器：Jupyter 版的 MATLAB Workspace
# https://github.com/jupyterlab-contrib/jupyterlab-variableInspector
RUN pip install --no-cache-dir lckr_jupyterlab_variableinspector==3.1.0

# 系统资源监控侧边栏（CPU/内存/磁盘）增强版
# https://github.com/jtpio/jupyterlab-system-monitor
RUN pip install --no-cache-dir jupyterlab-system-monitor

# nbdime：Notebook Git 差异可视化
# https://github.com/jupyter/nbdime
RUN pip install --no-cache-dir nbdime && nbdime extensions --enable

# 生成 notebook 目录导航（Table of Contents）
# https://github.com/jupyterlab/jupyterlab-toc
RUN pip install --no-cache-dir jupyterlab-toc

# Solarized 暗色主题（可选 UI 主题美化）
# https://github.com/mohirio/jupyterlab-theme-solarized-dark
RUN pip install --no-cache-dir jupyterlab-theme-solarized-dark

# -------------------- Jupyter 配置区 --------------------

# 生成配置文件
RUN jupyter lab --allow-root --generate-config

# 修改 Jupyter 启动配置（含空闲回收、日志配置、默认 shell）
RUN mkdir -p /home/jovyan/.jupyter && echo -e "\
c.ServerApp.allow_root = True\n\
c.ServerApp.ip = '0.0.0.0'\n\
c.ExtensionApp.open_browser = False\n\
c.ServerApp.port = 8888\n\
c.MappingKernelManager.cull_idle_timeout = 600\n\
c.MappingKernelManager.cull_interval = 60\n\
c.MappingKernelManager.cull_connected = True\n\
c.MappingKernelManager.cull_busy = False\n\
c.TerminalManager.cull_inactive_timeout = 300\n\
c.TerminalManager.cull_interval = 60\n\
c.TerminalInteractiveShell.shell = '/bin/bash'\n\
c.Application.log_level = 'DEBUG'\n\
c.ServerApp.logging_config = {\n\
  'handlers': {\n\
    'file': {\n\
      'class': 'logging.handlers.TimedRotatingFileHandler',\n\
      'level': 'DEBUG',\n\
      'formatter': 'standard',\n\
      'filename': '/opt/jupyter_server.log',\n\
      'when': 'S',\n\
      'interval': 3600,\n\
      'backupCount': 1,\n\
    }\n\
  },\n\
  'loggers': {\n\
    'ServerApp': {\n\
      'level': 'DEBUG',\n\
      'handlers': ['console','file'],\n\
    }\n\
  },\n\
  'formatters': {\n\
    'standard': {\n\
      'format': '%(asctime)s - %(name)s - %(levelname)s - %(message)s',\n\
      'datafmt': '%Y-%m-%d %H:%M:%S'\n\
    }\n\
  }\n\
}" >> /home/jovyan/.jupyter/jupyter_lab_config.py

# 设置中文界面默认语言
RUN mkdir -p /home/jovyan/.jupyter/lab/user-settings/@jupyterlab/translation-extension && \
    echo '{ "locale": "zh_CN" }' > /home/jovyan/.jupyter/lab/user-settings/@jupyterlab/translation-extension/plugin.jupyterlab-settings

# 安装本地 logviewer 插件（日志查看器）
COPY docker/logviewer /opt/logviewer
RUN cd /opt/logviewer && pip install -r requirements.txt

# 初始化脚本
COPY docker/init.sh /opt/init.sh
RUN chmod a+x /opt/init.sh

# 设置 cron 日志文件
RUN touch /var/log/cron.log && \
    (crontab -l ; echo "") | crontab

# 设置默认工作目录（与挂载目录一致）
WORKDIR /home/jovyan/work

# 设置默认 Token（可被 docker-compose 或部署脚本覆盖）
ENV JUPYTER_TOKEN=letmein

# 端口暴露
EXPOSE 8765
EXPOSE 8888

# 启动命令：显式读取 Token，默认 shell 为 bash
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--allow-root", "--no-browser", "--ServerApp.token=${JUPYTER_TOKEN}"]