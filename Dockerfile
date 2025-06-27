# =================================================================================
# STAGE 1: Builder - Tải, giải nén và chuẩn hóa tên thư mục
# =================================================================================
FROM debian:bullseye-slim AS builder

RUN apt-get update && apt-get install -y \
    curl \
    tar \
    ca-certificates \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

ARG TARGETARCH
RUN case ${TARGETARCH} in \
        "amd64") ARCH="x64" ;; \
        "arm64") ARCH="arm64" ;; \
    esac \
    && curl -L "https://update.code.visualstudio.com/latest/server-linux-${ARCH}/stable" --output vscode-server.tar.gz \
    && tar -xzf vscode-server.tar.gz \
    && mv vscode-server-linux-* vscode-server-final

# =================================================================================
# STAGE 2: Final Image - Tạo image cuối cùng để chạy
# =================================================================================
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
    ca-certificates \
    && useradd -ms /bin/bash vscode \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /tmp/vscode-server-final /vscode-server

RUN mkdir -p ${WORKSPACE_DIR} /home/vscode/.vscode-server \
    && chown -R vscode:vscode /vscode-server ${WORKSPACE_DIR} /home/vscode

USER vscode
WORKDIR ${WORKSPACE_DIR}
EXPOSE ${VSCODE_PORT}

# THÊM CỜ ĐỂ ĐỒNG Ý VỚI ĐIỀU KHOẢN SỬ DỤNG
CMD /vscode-server/bin/code-server serve-web \
    --host 0.0.0.0 \
    --port ${VSCODE_PORT} \
    --connection-token ${VSCODE_TOKEN} \
    --accept-server-license-terms
