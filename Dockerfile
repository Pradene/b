# Use Ubuntu as base image
FROM ubuntu:22.04

# Update package lists and install basic dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    bison \
    flex \
    gcc \
    g++ \
    make \
    vim \
    git \
    wget \
    curl \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/*

# Enable 32-bit architecture support
RUN dpkg --add-architecture i386

# Update package lists again after adding i386 architecture
RUN apt-get update && apt-get install -y \
    gcc-multilib \
    g++-multilib \
    libc6-dev-i386 \
    lib32gcc-s1 \
    lib32stdc++6 \
    && rm -rf /var/lib/apt/lists/*

# Install 32-bit debugger (GDB with 32-bit support)
RUN apt-get update && apt-get install -y \
    gdb \
    gdb-multiarch \
    libc6-dbg:i386 \
    && rm -rf /var/lib/apt/lists/*

# Install additional useful development tools
RUN apt-get update && apt-get install -y \
    valgrind \
    strace \
    ltrace \
    file \
    && rm -rf /var/lib/apt/lists/*

# Create a working directory
WORKDIR /workspace

COPY . .

# Create a non-root user for development
RUN useradd -m -s /bin/bash developer && \
    chown -R developer:developer /workspace

# Switch to the developer user
USER developer

# Display versions of installed tools
RUN echo "Installed versions:" && \
    bison --version && \
    flex --version && \
    gcc --version && \
    gdb --version

# Default command
CMD ["/bin/bash"]
