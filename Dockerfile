# --- Giai đoạn 1: "Builder" ---
FROM debian:bookworm AS builder
ENV DEBIAN_FRONTEND=noninteractive
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
ENV TOKEN=11042006
ENV WS=/workspace
ENV DEBIAN_FRONTEND=noninteractive

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
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/vscode/usr/share/code /usr/share/code
RUN ln -s /usr/share/code/bin/code /usr/bin/code
RUN useradd -ms /bin/bash coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p $WS && chown coder:coder $WS
USER coder
WORKDIR $WS

# --- THAY ĐỔI Ở ĐÂY ---
# Thêm "/workspace" vào cuối để chỉ định thư mục mặc định khi khởi động
CMD ["code", "serve-web", "--host", "0.0.0.0", "--port", "8585", "--connection-token", "11042006", "--default-workspace", "~/workspace"]
