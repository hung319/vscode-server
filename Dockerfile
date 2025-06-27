# Stage 1: Base với các gói cần thiết để cài VS Code
FROM debian:latest as base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    sudo \
    software-properties-common \
    apt-transport-https \
    wget \
    gpg \
    curl \
    ca-certificates

# Stage 2: Cài đặt VS Code
FROM base as vscode-install

# Thêm key và repo
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/keyrings/packages.microsoft.gpg
RUN echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list

RUN apt-get update && apt-get install -y code

# Stage 3: Final image (sạch và tối ưu)
FROM base

# Copy VS Code từ stage trước
COPY --from=vscode-install /usr/bin/code /usr/bin/code
COPY --from=vscode-install /usr/share/code /usr/share/code
COPY --from=vscode-install /usr/lib/code /usr/lib/code

# Tạo user vscode với sudo và thư mục làm việc
RUN useradd -ms /bin/bash vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /workspace && chown vscode:vscode /workspace

# Đặt user và thư mục làm việc
USER vscode
WORKDIR /workspace

# Biến môi trường có thể override khi chạy
ENV PORT=8585
ENV TOKEN=11042006

# Lệnh mặc định chạy code-server
CMD ["sh", "-c", "code serve-web --host 0.0.0.0 --port $PORT --connection-token $TOKEN --folder-uri file:///workspace"]
