# =========================================================================
# STAGE 1: Builder - Giai đoạn cài đặt các công cụ và download VS Code
# =========================================================================
FROM debian:bullseye-slim AS builder

# Cài đặt các gói cần thiết cho việc tải và cài đặt VS Code
# Thêm 'curl' vào danh sách cài đặt
RUN apt-get update && apt-get install -y \
    curl \
    gpg \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Tải, xác thực và thêm repo của Microsoft
# *** DÙNG CURL THAY THẾ CHO WGET Ở ĐÂY ***
RUN curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg \
    && install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg \
    && echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list \
    && rm -f packages.microsoft.gpg

# Cài đặt VS Code
RUN apt-get update && apt-get install -y code --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# =========================================================================
# STAGE 2: Final Image - Giai đoạn tạo image cuối cùng để chạy
# (Phần này giữ nguyên không thay đổi)
# =========================================================================
FROM debian:bullseye-slim

ENV VSCODE_PORT=8585
ENV VSCODE_TOKEN=11042006
ENV WORKSPACE_DIR=/workspace

RUN apt-get update && apt-get install -y \
    libx11-6 \
    libxkbfile1 \
    libsecret-1-0 \
    libnss3 \
    libnspr4 \
    libasound2 \
    && useradd -ms /bin/bash vscode \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/share/code /usr/share/code
COPY --from=builder /usr/bin/code /usr/bin/code

RUN mkdir -p ${WORKSPACE_DIR} /home/vscode/.vscode-server \
    && chown -R vscode:vscode /home/vscode ${WORKSPACE_DIR}

USER vscode
WORKDIR ${WORKSPACE_DIR}
EXPOSE ${VSCODE_PORT}

CMD code serve-web \
    --host 0.0.0.0 \
    --port ${VSCODE_PORT} \
    --connection-token ${VSCODE_TOKEN} \
    --user-data-dir /home/vscode/.vscode-server
