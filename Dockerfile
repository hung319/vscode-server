FROM debian:latest

ENV PORT=8585
ENV TOKEN=11042006

RUN apt-get update && apt-get install -y \
    software-properties-common \
    apt-transport-https \
    wget \
    gpg

RUN wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg

RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/code stable main" | tee /etc/apt/sources.list.d/vscode.list

RUN apt-get update && apt-get install -y code

EXPOSE $PORT

CMD ["code", "serve-web", "--host", "0.0.0.0", "--port", "$PORT", "--connection-token", "$TOKEN", "--accept-server-license-terms"]
