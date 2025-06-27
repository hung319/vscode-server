# Stage 1: Base với các gói cần thiết
FROM debian:latest AS base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    sudo \
    software-properties-common \
    apt-transport-https \
    wget \
    gpg \
    curl \
    ca-certificates

# Stage 2: Final image, cài VSCode trực tiếp
FROM base

# Cài key và repo VS Code
RUN mkdir -p /etc/apt/keyrings && \
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/keyrings/packages.microsoft.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    apt-get update && apt-get install -y code

# Tạo user vscode
RUN useradd -ms /bin/bash vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /workspace && chown vscode:vscode /workspace

USER vscode
WORKDIR /workspace

# Biến môi trường có thể chỉnh
ENV PORT=8585
ENV TOKEN=11042006

# Chạy VSCode Web tự động
CMD ["sh", "-c", "code serve-web --host 0.0.0.0 --port $PORT --connection-token $TOKEN --folder-uri file:///workspace"]
