import os
import sys
import yaml
import subprocess
from jinja2 import Template

REPOSITORY = "scisaga/jupyterlab"
PROJECT_ROOT = os.path.abspath(os.path.dirname(__file__))

def render_template(config_path):
    with open(config_path) as f:
        config = yaml.safe_load(f)

    with open(os.path.join(PROJECT_ROOT, "docker", "Dockerfile"), encoding='utf-8') as f:
        template = Template(f.read())

    output = template.render(**config)
    name = config["name"]
    target_dir = os.path.join(PROJECT_ROOT, "generated", name)
    os.makedirs(target_dir, exist_ok=True)

    dockerfile_path = os.path.join(target_dir, "Dockerfile")
    with open(dockerfile_path, "w") as f:
        f.write(output)

    print(f"✅ Dockerfile generated at: {dockerfile_path}")
    return config, dockerfile_path

def build_image(config, dockerfile_path):
    name = config["name"]
    tag = f"{REPOSITORY}:{name}"

    print(f"\n🚀 Building image: {tag}")
    cmd = [
        "docker", "buildx", "build",
        "--load",  # 如果你想推送用 --push
        "-t", tag,
        "-f", dockerfile_path,
        PROJECT_ROOT  # 上下文是项目根目录，确保能 COPY docker/
    ]

    try:
        subprocess.run(cmd, check=True)
        print(f"✅ Image built successfully: {tag}")
    except subprocess.CalledProcessError as e:
        print("❌ Build failed. Please check Dockerfile or build context.")
        sys.exit(e.returncode)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python build.py configs/your-config.yaml")
        sys.exit(1)

    config_path = sys.argv[1]
    config, dockerfile_path = render_template(config_path)
    build_image(config, dockerfile_path)
