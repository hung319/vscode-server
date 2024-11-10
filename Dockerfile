FROM debian:latest

# Cài đặt các gói cần thiết và Visual Studio Code
RUN apt-get update && apt-get install -y software-properties-common apt-transport-https wget gpg
RUN wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/code stable main" | tee /etc/apt/sources.list.d/vscode.list
RUN apt-get update && apt-get install -y code

# Định nghĩa các biến môi trường cho PORT và TOKEN
ENV PORT=8585
ENV TOKEN=11042006

# Sử dụng biến môi trường để cấu hình cổng và token đăng nhập
EXPOSE ${PORT}
CMD ["code", "serve-web", "--host", "0.0.0.0", "--port", "$PORT", "--connection-token", "$TOKEN"]
