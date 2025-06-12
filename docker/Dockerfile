# syntax=docker/dockerfile:1.4
FROM {{ base_image }}

SHELL ["/bin/bash", "-c"]

WORKDIR /opt
VOLUME /opt
ENV LANG=C.UTF-8
ENV PATH="/usr/local/bin:/usr/bin:/bin:/root/.local/bin"

# 更换为清华源，加快国内 apt 下载速度
{% if 'ubuntu24.04' in base_image %}
RUN echo $'deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble main restricted universe multiverse\n \
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-updates main restricted universe multiverse\n \
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-backports main restricted universe multiverse\n \
deb http://security.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse' > /etc/apt/sources.list
{% elif 'ubuntu22.04' in base_image %}
RUN echo $'deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse\n \
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse\n \
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse\n \
deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse' > /etc/apt/sources.list
{% else %}
RUN echo "Unsupported base image: {{ base_image }}" && exit 1
{% endif %}

ENV DEBIAN_FRONTEND=noninteractive TZ=Asia/Shanghai
# 安装通用系统工具
RUN apt update && \
    apt install -qy --no-install-recommends \
      vim wget git xz-utils yarn cron jq curl ntpdate iputils-ping \
      software-properties-common build-essential \
      libssl-dev libffi-dev

# S3 文件系统挂载工具
RUN apt install -y s3fs

# 安装 pip、venv、dev
RUN apt install -y --no-install-recommends \
      python3-pip python3-venv python3-dev python-is-python3

# 配置 pip 为清华源
RUN echo "[global]\nindex-url = https://pypi.tuna.tsinghua.edu.cn/simple" > /etc/pip.conf

# 创建虚拟环境
RUN python3 -m venv /opt/venv

# 使用 venv pip 安装 wheel 和其他依赖
RUN /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install --no-cache-dir wheel

# 设置 PATH，后续 pip、python 都使用虚拟环境
ENV PATH="/opt/venv/bin:$PATH"

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

# Notebook Git 差异可视化
# https://github.com/jupyter/nbdime
RUN pip install --no-cache-dir nbdime && nbdime extensions --enable

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

# 安装本地 logviewer 插件（可选）
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

# 设置默认登录 Token（可被 docker-compose 覆盖）
ENV JUPYTER_TOKEN=letmein

# 健康检查
HEALTHCHECK CMD curl --fail http://localhost:8888 || exit 1

# 端口暴露
EXPOSE 8765
EXPOSE 8888

CMD ["/bin/bash"]
