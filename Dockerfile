# =========================================================================
# STAGE 1: Builder - Giai đoạn cài đặt các công cụ và download VS Code
# =========================================================================
FROM debian:bullseye-slim AS builder

# Cài đặt các gói cần thiết cho việc tải và cài đặt VS Code
RUN apt-get update && apt-get install -y \
    wget \
    gpg \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Tải, xác thực và thêm repo của Microsoft
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg \
    && install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg \
    && echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list \
    && rm -f packages.microsoft.gpg

# Cài đặt VS Code
RUN apt-get update && apt-get install -y code --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*


# =========================================================================
# STAGE 2: Final Image - Giai đoạn tạo image cuối cùng để chạy
# =========================================================================
FROM debian:bullseye-slim

# Thiết lập các biến môi trường với giá trị mặc định
# Bạn có thể thay đổi chúng khi chạy container
ENV VSCODE_PORT=8585
ENV VSCODE_TOKEN=11042006
ENV WORKSPACE_DIR=/workspace

# Cài đặt các thư viện cần thiết để VS Code có thể chạy
# mà không cần toàn bộ build dependencies
RUN apt-get update && apt-get install -y \
    libx11-6 \
    libxkbfile1 \
    libsecret-1-0 \
    libnss3 \
    libnspr4 \
    libasound2 \
    # Thêm một user không phải root để tăng cường bảo mật
    && useradd -ms /bin/bash vscode \
    && rm -rf /var/lib/apt/lists/*

# Sao chép ứng dụng VS Code đã được cài đặt từ stage 'builder'
COPY --from=builder /usr/share/code /usr/share/code
COPY --from=builder /usr/bin/code /usr/bin/code

# Tạo thư mục làm việc và gán quyền cho user 'vscode'
# Đồng thời tạo thư mục cho dữ liệu người dùng của VS Code
RUN mkdir -p ${WORKSPACE_DIR} /home/vscode/.vscode-server \
    && chown -R vscode:vscode /home/vscode ${WORKSPACE_DIR}

# Chuyển sang user không phải root
USER vscode

# Đặt thư mục làm việc mặc định
WORKDIR ${WORKSPACE_DIR}

# Thông báo port sẽ được sử dụng (chủ yếu để tham khảo)
EXPOSE ${VSCODE_PORT}

# Lệnh để khởi động VS Code web server
# Sử dụng biến môi trường để cấu hình
# --user-data-dir để đảm bảo user 'vscode' có quyền ghi dữ liệu
CMD code serve-web \
    --host 0.0.0.0 \
    --port ${VSCODE_PORT} \
    --connection-token ${VSCODE_TOKEN} \
    --user-data-dir /home/vscode/.vscode-server
