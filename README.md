# 朴素JupyterLab容器开发环境

本项目用于构建基于 **JupyterLab** 的 GPU/CPU 容器镜像，支持多版本 `Python` / `CUDA`，内置多个实用插件，并可在容器中训练模型和运行 Web 推理服务，供外部测试。
- https://hub.docker.com/r/scisaga/jupyterlab


## 项目结构
```yaml
jupyterlab-naive/
├── build.py          # 镜像构建脚本
├── build_and_push.sh # 构建 + 推送镜像脚本（支持多版本组合）
├── deploy.sh         # 镜像部署容器
├── .dockerignore # 构建时忽略文件
├── docker/
│ ├── Dockerfile # 镜像构建模板，支持 python_version / base_image 等变量
│ ├── init.sh    # 容器初始化脚本（作为 entrypoint）
│ └── logviewer/ # 自定义日志查看插件（可选）
├── config/
│ └── py310-cuda121.yaml # 构建配置文件（base_image + python_version + tag）
├── docker-compose/
│ ├── .env              # 容器环境变量配置
│ └── py310-cuda121.yml # 启动容器配置
├── setup_host.sh # 安装 NVIDIA 驱动、Docker、容器工具（适用于 GPU 主机）
├── setup_host_cpu.sh # 安装 Docker 环境（适用于 CPU 主机）
├── set_proxy.sh # 设置/取消 HTTP/HTTPS 代理（含 Docker daemon）
└── workspace/ # 映射至容器中的 /home/jovyan/work 工作区
```

## 镜像构建与部署

### 构建镜像

基础镜像选取
- https://hub.docker.com/r/nvidia/cuda/tags

```bash
python build.py config/py310-cuda121.yaml
```
自动解析 Dockerfile 和对应变量，构建支持 CUDA 的 JupyterLab 镜像。

### 启动容器（含 GPU）
```bash
docker compose -f docker-compose/py310-cuda121.yml up -d
```
可以通过 docker-compose/.env 控制：
- 使用几张 GPU（NVIDIA_VISIBLE_DEVICES）
- 是否使用 GPU（设为 "" 表示 CPU 模式）
- 资源配额（CPU / MEM）
- HTTP/HTTPS代理
- 默认登录token：**letmein**

### 宿主机环境准备

#### GPU 主机环境（Ubuntu）
```bash
sudo bash scripts/setup_host_gpu.sh
```
会自动完成以下操作：
- 安装 Docker 与 docker-compose（使用国内源）
- 安装最新版 NVIDIA 驱动（默认安装 555）
- 配置 NVIDIA Container Toolkit
- 验证 nvidia-smi 与 nvidia-docker 支持

#### CPU 主机环境
```bash
sudo bash scripts/setup_host.sh
```
仅安装 Docker 环境，无需安装 GPU 驱动或容器插件。

#### 网络环境设置（代理支持）
如果拉去镜像或者pip安装受限，可设置代理：
```bash
# 启用代理（shell + 系统 + Docker）
./setup_proxy.sh on

# 关闭并清理所有代理配置
./setup_proxy.sh off
```
支持系统级 / Docker daemon 的代理配置，适配公司内网和 VPN 环境。

## 已集成 JupyterLab 插件
| 分类               | 插件                                                                          | 说明                    |
| ---------------- | --------------------------------------------------------------------------- | --------------------- |
| 🧠 核心增强          | `jupyterlab` `ipywidgets` `traitlets`                                       | JupyterLab 主体及增强组件    |
| 📦 管理工具          | `pipreqs` `pipreqsnb`                                                       | 自动生成 requirements.txt |
| 📊 监控可视          | `jupyter-resource-usage`                                                    | 显示内存/CPU 用量           |
| 🧬 Git 集成        | `jupyterlab-git`                                                            | 图形化 Git 操作            |
| 🧠 LSP 支持        | `jupyterlab-lsp` `python-lsp-server[all]`                                   | 自动补全、跳转、诊断            |
| 🧹 代码格式化         | `jupyterlab-code-formatter` `black` `isort[requirements_deprecated_finder]` | 支持多格式化器               |
| 🌐 多语言支持         | `jupyterlab-translate` `jupyterlab-language-pack-zh-CN`                     | 中文界面                  |
| 🕐 Cell 时间       | `jupyterlab_execute_time`                                                   | 显示每个 Cell 的执行时间       |
| 🔬 变量检查          | `lckr_jupyterlab_variableinspector`                                         | 查看当前变量状态              |
| 🖥️ 系统监控         | `jupyterlab-system-monitor`                                                 | 顶栏显示资源使用率             |
| 🔍 Notebook Diff | `nbdime`                                                                    | 查看两个 Notebook 的差异     |
| 📊 数据可视化         | `plotly`                                                                    | 高交互性的图表组件             |
| 🪪 实用库           | `boto3` `pyjwt`                                                             | AWS 访问 / JWT 解码支持     |

同时支持：
- S3 文件系统挂载（s3fs）
- 日志服务 logviewer

## 推理服务支持（API / Web UI）

### Flask API 示例
适合模型推理 API，轻量易集成：
```python
# serv_flask.py
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()
    text = data.get("text", "")
    result = f"Echo: {text}"
    return jsonify({ "result": result })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```
```shell
# 启动命令（容器内）
python serv_flask.py

# 调用方式
curl -X POST http://localhost:<WEB_SERVER_PORT>/predict \
     -H "Content-Type: application/json" \
     -d '{"text": "Hello JupyterLab!"}'
```
### Streamlit 示例
适合快速构建 demo / 前端 UI：
```python
# serv_streamlit.py
import streamlit as st

st.set_page_config(page_title="JupyterLab Demo", layout="wide")
st.title("🧪 Streamlit Demo in JupyterLab")

text = st.text_input("输入内容：")
if text:
    st.success(f"你输入了：{text}")
```
```shell
# 启动命令
streamlit run serv_streamlit.py --server.port 5000 --server.address 0.0.0.0
# 打开浏览器访问 http://<宿主机IP>:<WEB_SERVER_PORT>
```

## 已构建镜像简述

`scisaga/jupyterlab:py310-cuda121`
- **Python**：3.10  
- **CUDA**：12.1
- **说明**：主流稳定组合，兼容大多数 AI 框架（如 PyTorch 2.1+、TensorFlow 2.13 等）
- **适用场景**：
   - 线上部署与教学环境
   - 工程稳定性要求高的模型开发任务
   - PyTorch、Transformers 等标准生态支持良好

`scisaga/jupyterlab:py312-cuda128`
- **Python**：3.12
- **CUDA**：12.8
- **说明**：面向前沿研发，适合测试新版本框架、最新驱动与显卡兼容性
- **适用场景**：
   - Python 3.12+ 特性验证
   - 新模型、新库兼容性测试
   - 实验性部署、探索未来主力环境

---

- 🎉 感谢关注与使用！
- ⭐ 欢迎 Star、反馈或贡献！
- 🔧 如需定制插件、构建推理接口或扩展平台，请联系维护者或提交 PR。
- ☕ 如果你觉得这个项目有帮助，欢迎 ~~打钱~~ 一起讨论
