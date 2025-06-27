# --- Giai đoạn 1: "Builder" ---
# Giai đoạn này dùng để cài đặt tất cả các công cụ cần thiết và tải về VS Code.
# Sử dụng phiên bản Debian cụ thể (bookworm) để đảm bảo tính ổn định.
FROM debian:bookworm AS builder

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
RUN dpkg-deb -x code_*.deb /opt/vscode


# --- Giai đoạn 2: "Final" ---
# Giai đoạn này sẽ tạo ra image cuối cùng, chỉ chứa những gì cần thiết để chạy VS Code server.
# Sử dụng phiên bản slim cụ thể (bookworm-slim) để giảm dung lượng và đảm bảo build thành công.
FROM debian:bookworm-slim

# Các biến môi trường cần thiết cho runtime
ENV PORT=8585
ENV TOKEN=11042006
ENV WS=/workspace
ENV DEBIAN_FRONTEND=noninteractive

# Cài đặt các dependencies tối thiểu mà VS Code Server cần để chạy
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

# Sao chép toàn bộ thư mục ứng dụng VS Code từ giai đoạn "builder"
COPY --from=builder /opt/vscode/usr/share/code /usr/share/code

# Tạo symbolic link để lệnh 'code' có thể truy cập được toàn cục
RUN ln -s /usr/share/code/bin/code /usr/bin/code

# Tạo user không phải root để tăng cường bảo mật
RUN useradd -ms /bin/bash coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p $WS && chown coder:coder $WS

# Chuyển sang user 'coder'
USER coder
WORKDIR $WS

# Lệnh để khởi động VS Code server
CMD ["code", "serve-web", "--host", "0.0.0.0", "--port", "8585", "--connection-token", "11042006"]
