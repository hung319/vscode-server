FROM debian:latest

# Cài đặt các gói cần thiết và Visual Studio Code
RUN apt-get update && apt-get install -y sudo software-properties-common apt-transport-https wget gpg
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
RUN sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
RUN echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
RUN rm -f packages.microsoft.gpg
RUN apt-get update && apt-get install -y code
RUN mkdir /workspace
WORKDIR /workspace

CMD ["code", "serve-web", "--host", "0.0.0.0", "--port", "8585", "--connection-token", "11042006"]
