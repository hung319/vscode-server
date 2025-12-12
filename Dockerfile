# --- Giai đoạn 1: "Builder" ---
FROM debian:bookworm AS builder
ENV DEBIAN_FRONTEND=noninteractive
# Tối ưu layer RUN để giảm số lượng layer và dọn dẹp sạch sẽ
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget gpg ca-certificates apt-transport-https && \
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/packages.microsoft.gpg && \
    echo "deb [arch=amd64,arm64,armhf] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    apt-get update && \
    apt-get download code && \
    rm -rf /var/lib/apt/lists/*
RUN dpkg-deb -x code_*.deb /opt/vscode

# --- Giai đoạn 2: "Final" ---
FROM debian:bookworm-slim
ENV PORT=8585
ENV WS=/workspace
ENV DEBIAN_FRONTEND=noninteractive

# Cài đặt các thư viện cần thiết cho VS Code
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    sudo \
    libx11-6 \
    libxkbfile1 \
    libsecret-1-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libgbm1 \
    libasound2 \
    libatspi2.0-0 \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/vscode/usr/share/code /usr/share/code
RUN ln -s /usr/share/code/bin/code /usr/bin/code

# Thiết lập user và quyền hạn
RUN useradd -ms /bin/bash coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p $WS && chown coder:coder $WS

USER coder
WORKDIR $WS

# --- THAY ĐỔI QUAN TRỌNG Ở ĐÂY ---
# 1. Thêm --accept-server-license-terms để tự động đồng ý điều khoản
# 2. Thêm "$WS" vào cuối để mở folder /workspace mặc định
CMD code serve-web --host 0.0.0.0 --port "$PORT" --connection-token "$TOKEN" --accept-server-license-terms "$WS"
