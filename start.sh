#!/bin/bash

# Chờ VS Code khởi động hoàn toàn
sleep 5

# Mở workspace
code /workspace 

# Chạy lệnh gốc
code serve-web --host 0.0.0.0 --port 8585 --connection-token 11042006
