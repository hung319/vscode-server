# --- Giai đoạn 1: "Builder" ---
# Giai đoạn này dùng để cài đặt tất cả các công cụ cần thiết và tải về VS Code.
# Chúng ta sử dụng một base image đầy đủ để có các công cụ build.
FROM debian:latest AS builder

# Thiết lập các biến môi trường
ENV DEBIAN_FRONTEND=noninteractive

# Cài đặt các gói cần thiết cho việc tải và cài đặt VS Code
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    gpg \
    ca-certificates \
    apt-transport-https && \
    # Thêm Microsoft GPG key và repository
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/packages.microsoft.gpg && \
    echo "deb [arch=amd64,arm64,armhf] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    # Cập nhật lại và chỉ tải về gói 'code' mà không cài đặt
    apt-get update && \
    apt-get download code && \
    # Dọn dẹp cache để giữ stage này gọn gàng
    rm -rf /var/lib/apt/lists/*

# Giải nén file .deb để lấy các file thực thi của VS Code
# Điều này cho phép chúng ta sao chép chính xác những gì cần thiết mà không cần cài đặt đầy đủ.
RUN dpkg-deb -x code_*.deb /opt/vscode


# --- Giai đoạn 2: "Final" ---
# Giai đoạn này sẽ tạo ra image cuối cùng, chỉ chứa những gì cần thiết để chạy VS Code server.
# Chúng ta sử dụng một base image nhỏ gọn (slim) để giảm dung lượng.
FROM debian:slim

# Các biến môi trường cần thiết cho runtime
ENV PORT=8585
ENV TOKEN=11042006
ENV WS=/workspace
ENV DEBIAN_FRONTEND=noninteractive

# Cài đặt các dependencies tối thiểu mà VS Code Server cần để chạy
# Thêm 'git' và 'sudo' nếu bạn cần chúng trong môi trường làm việc cuối cùng.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    sudo \
    # Các thư viện mà VS Code có thể cần
    libx11-6 \
    libxkbfile1 \
    libsecret-1-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    # Dọn dẹp cache
    && rm -rf /var/lib/apt/lists/*

# Sao chép các file của VS Code đã được giải nén từ giai đoạn "builder"
COPY --from=builder /opt/vscode/usr/share/code /usr/share/code
COPY --from=builder /opt/vscode/usr/bin/code /usr/bin/code

# Tạo user không phải root để tăng cường bảo mật
RUN useradd -ms /bin/bash coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p $WS && chown coder:coder $WS

# Chuyển sang user 'coder'
USER coder
WORKDIR $WS

# Lệnh để khởi động VS Code server
CMD ["code", "serve-web", "--host", "0.0.0.0", "--port", "8585", "--connection-token", "11042006"]
