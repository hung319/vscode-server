FROM debian:latest

ENV PORT=8585
ENV TOKEN=11042006
ENV WS=/workspace

# Cài đặt các gói cần thiết và Visual Studio Code
RUN apt-get update && apt-get install -y sudo software-properties-common apt-transport-https wget gpg git
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
RUN sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
RUN echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
RUN rm -f packages.microsoft.gpg
RUN apt-get update && apt-get install -y code

RUN useradd -ms /bin/bash coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p $WS && chown coder:coder $WS
USER coder
WORKDIR $WS

CMD ["code", "serve-web", "--host", "0.0.0.0", "--port", "$PORT", "--connection-token", "$TOKEN"]
