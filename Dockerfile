# =========================================================================
# STAGE 1: Builder - Cài đặt gói VS Code Desktop
# =========================================================================
FROM debian:bullseye-slim AS builder

# Cài các gói cần thiết
RUN apt-get update && apt-get install -y \
    curl \
    gpg \
    ca-certificates \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Thêm kho của Microsoft với kiến trúc được xác định động
# *** SỬA LỖI QUAN TRỌNG NHẤT LÀ Ở ĐÂY ***
RUN curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg \
    && install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list \
    && rm -f packages.microsoft.gpg

# Cài đặt gói 'code'
RUN apt-get update && apt-get install -y code --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# =========================================================================
# STAGE 2: Final Image - Tạo image cuối cùng để chạy
# =========================================================================
FROM debian:bullseye-slim

# Dùng biến môi trường cho linh hoạt
ENV VSCODE_PORT=8080
ENV VSCODE_TOKEN=11042006
ENV WORKSPACE_DIR=/workspace

# Cài đặt các thư viện phụ thuộc tối thiểu để 'code' có thể chạy
RUN apt-get update && apt-get install -y \
    libx11-6 \
    libxkbfile1 \
    libsecret-1-0 \
    libnss3 \
    libasound2 \
    libgtk-3-0 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libxshmfence1 \
    ca-certificates \
    && useradd -ms /bin/bash vscode \
    && rm -rf /var/lib/apt/lists/*

# Sao chép các file của ứng dụng 'code' từ stage builder
COPY --from=builder /usr/share/code /usr/share/code
COPY --from=builder /usr/bin/code /usr/bin/code

# Tạo thư mục làm việc và gán quyền
RUN mkdir -p ${WORKSPACE_DIR} /home/vscode/.vscode \
    && chown -R vscode:vscode ${WORKSPACE_DIR} /home/vscode

# Chuyển sang user không có quyền root để tăng bảo mật
USER vscode
WORKDIR ${WORKSPACE_DIR}

EXPOSE ${VSCODE_PORT}

# Sử dụng lệnh CMD từ Dockerfile gốc, nhưng với biến môi trường
CMD ["code", "serve-web", "--host", "0.0.0.0", "--port", "${VSCODE_PORT}", "--connection-token", "${VSCODE_TOKEN}"]
