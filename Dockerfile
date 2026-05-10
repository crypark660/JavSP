FROM python:3.11-slim

WORKDIR /app

COPY . /app

# 替换源并安装 git 和 poetry
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources && \
    apt update && apt install -y git && \
    pip install --no-cache-dir poetry -i https://mirrors.aliyun.com/pypi/simple/

# 告诉 poetry 不要创建虚拟环境，直接安装到系统环境
ENV POETRY_VIRTUALENVS_CREATE=false

# 使用 poetry 安装项目依赖（这会注册 javsp 命令）
RUN poetry install --no-interaction

# 设置入口命令为 javsp
CMD ["javsp"]
