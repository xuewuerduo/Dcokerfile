# 第一阶段：提取和精简JDK
FROM ubuntu:24.04@sha256:b59d21599a2b151e23eea5f6602f4af4d7d31c4e236d22bf0b62b86d2e386b8f as jdk-build

# 安装必要工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    file \
    binutils \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /tmp

# 添加并解压JDK
ADD jdk-8u451-linux-x64.tar.gz .
RUN mv jdk1.8.0_451 /opt/jdk

# 创建精简JRE（修复目录不存在问题）
RUN mkdir -p /opt/jre && \
    cd /opt/jre && \
    # 复制核心运行时组件（跳过不存在的目录）
    cp -r /opt/jdk/jre/lib . && \
    cp -r /opt/jdk/jre/bin . && \
    [ -d "/opt/jdk/jre/include" ] && cp -r /opt/jdk/jre/include . || true && \
    [ -d "/opt/jdk/jre/plugin" ] && cp -r /opt/jdk/jre/plugin . || true && \
    # 移除不必要的文件
    find . -name "*.bat" -delete && \
    find . -name "*.exe" -delete && \
    find . -name "*.pdb" -delete && \
    find . -name "*.zip" -delete && \
    find . -name "javaws" -delete && \
    # 清理文档和源码
    rm -rf /opt/jre/lib/src.zip /opt/jre/lib/docs /opt/jre/lib/man && \
    # 清理字体和国际化资源
    find /opt/jre/lib/fonts -type f ! -name "L*" -delete && \
    find /opt/jre/lib/ext -type f ! -name "*.jar" -delete && \
    # 清理locale资源（保留中文和英文）
    find /opt/jre/lib -name "locale" | while read dir; do \
        cd "$dir"; \
        find . -type f ! -name "zh_CN*" ! -name "en_US*" -delete; \
    done

# 第二阶段：创建最终镜像
FROM ubuntu:24.04@sha256:b59d21599a2b151e23eea5f6602f4af4d7d31c4e236d22bf0b62b86d2e386b8f

# 设置环境变量
ENV TZ=Asia/Shanghai
ENV VNC_PORT=5900
ENV JAR_FILE=app.jar
ENV JAVA_OPTS="-Xmx512m -XX:MaxMetaspaceSize=128m"
ENV JAR_DIR=/app
ENV JAVA_HOME=/opt/jre
ENV PATH=$PATH:$JAVA_HOME/bin

# 安装最小化依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb \
    x11vnc \
    tzdata \
    fonts-wqy-zenhei \
    && rm -rf /var/lib/apt/lists/* \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 从第一阶段复制精简JRE
COPY --from=jdk-build /opt/jre /opt/jre

# 创建应用目录
RUN mkdir -p ${JAR_DIR}

# 创建日志目录
RUN mkdir -p /var/log/x11vnc

# 复制入口脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 暴露VNC端口
EXPOSE ${VNC_PORT}

# 设置工作目录
WORKDIR /home/user

# 支持两种方式提供JAR包
ARG JAR_PATH
COPY ${JAR_PATH:-empty} ${JAR_DIR}/${JAR_FILE}

# 启动命令
ENTRYPOINT ["/entrypoint.sh"]