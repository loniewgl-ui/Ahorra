FROM cirrusci/flutter:stable

# Install Android SDK and tools
RUN sudo apt-get update && sudo apt-get install -y \
    android-tools-adb \
    android-tools-fastboot \
    openjdk-11-jdk \
    && sudo rm -rf /var/lib/apt/lists/*

# Set Java environment
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$PATH:$JAVA_HOME/bin

# Install additional Flutter dependencies
RUN flutter config --enable-web && \
    flutter config --enable-android && \
    flutter doctor

# Expose ports for development
EXPOSE 8080

# Set working directory
WORKDIR /workspace

# Gitpod specific configuration
RUN git config --global core.autocrlf input
