# =================================================================================
# STAGE 1: Builder - Tải và giải nén bản VS Code Server độc lập
# =================================================================================
FROM debian:bullseye-slim AS builder

# SỬA LỖI: Thêm 'ca-certificates' vào đây để curl có thể xác thực SSL/TLS
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    ca-certificates \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

# Docker tự động cung cấp biến TARGETARCH (amd64, arm64, etc.)
# Chúng ta sẽ dùng nó để tải đúng phiên bản cho kiến trúc CPU
ARG TARGETARCH
RUN case ${TARGETARCH} in \
        "amd64") ARCH="x64" ;; \
        "arm64") ARCH="arm64" ;; \
    esac \
    && curl -L "https://update.code.visualstudio.com/latest/server-linux-${ARCH}/stable" --output vscode-server.tar.gz \
    && tar -xzf vscode-server.tar.gz

# =================================================================================
# STAGE 2: Final Image - Tạo image cuối cùng để chạy
# =================================================================================
FROM debian:bullseye-slim

# Thiết lập các biến môi trường với giá trị mặc định
ENV VSCODE_PORT=8585
ENV VSCODE_TOKEN=11042006
ENV WORKSPACE_DIR=/workspace

# Cài đặt các thư viện cần thiết để VS Code có thể chạy
# (Giữ ca-certificates ở đây vẫn là một good practice cho runtime)
RUN apt-get update && apt-get install -y \
    libx11-6 \
    libxkbfile1 \
    libsecret-1-0 \
    libnss3 \
    libnspr4 \
    libasound2 \
    ca-certificates \
    && useradd -ms /bin/bash vscode \
    && rm -rf /var/lib/apt/lists/*

# Sao chép toàn bộ thư mục VS Code Server đã được giải nén từ stage builder
COPY --from=builder /tmp/vscode-server-linux-* /vscode-server

RUN mkdir -p ${WORKSPACE_DIR} /home/vscode/.vscode-server \
    && chown -R vscode:vscode /vscode-server ${WORKSPACE_DIR} /home/vscode

# Chuyển sang user không phải root
USER vscode

# Đặt thư mục làm việc mặc định
WORKDIR ${WORKSPACE_DIR}

# Thông báo port sẽ được sử dụng
EXPOSE ${VSCODE_PORT}

# Lệnh để khởi động VS Code web server
# CẢI TIẾN: Bỏ cờ --without-connection-token để tránh xung đột với token bạn đã đặt
CMD /vscode-server/bin/code serve-web \
    --host 0.0.0.0 \
    --port ${VSCODE_PORT} \
    --connection-token ${VSCODE_TOKEN} \
    --user-data-dir /home/vscode/.vscode-server
