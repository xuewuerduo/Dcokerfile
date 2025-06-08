#!/bin/bash

# 检查JAR文件是否存在
if [ ! -f "${JAR_DIR}/${JAR_FILE}" ]; then
    echo "[ERROR] JAR文件不存在: ${JAR_DIR}/${JAR_FILE}"
    exit 1
fi

# 启动Xvfb虚拟显示器
echo "[INFO] 启动Xvfb虚拟显示器..."
Xvfb :0 -screen 0 1920x1080x24 -nolisten tcp -nolisten unix &
XVFB_PID=$!
sleep 2

# 启动Java应用
echo "[INFO] 启动Java应用: java $JAVA_OPTS -jar ${JAR_DIR}/${JAR_FILE}"
DISPLAY=:0 java $JAVA_OPTS -jar ${JAR_DIR}/${JAR_FILE} &
JAVA_PID=$!

# 启动x11vnc服务（无密码模式）
echo "[INFO] 启动x11vnc服务（无密码模式）..."
x11vnc -display :0 -rfbport ${VNC_PORT} -noxrecord -noxfixes -noxdamage -nopw -forever -o /var/log/x11vnc/x11vnc.log &
X11VNC_PID=$!

# 定义清理函数
cleanup() {
    echo "[INFO] 清理进程..."
    kill -9 $XVFB_PID $JAVA_PID $X11VNC_PID 2>/dev/null
    echo "[INFO] 容器关闭"
}

# 注册清理钩子
trap cleanup EXIT

# 监控Java进程状态
echo "[INFO] 容器启动完成，VNC服务在端口${VNC_PORT}运行，Java应用PID: $JAVA_PID"
wait $JAVA_PID
echo "[ERROR] Java应用已退出，状态码: $?"
cleanup
exit 1