#!/usr/bin/env bash

set -e

# Function to print error messages to STDERR and abort the script
error() {
    echo "ERROR: $*" >&2
    exit 1
}

# Function to display help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --help       Show this help message and exit"
    echo "  --uninstall  Uninstall dnscrypt-proxy and remove all files created by the script"
}

# Detect the architecture
ARCH=$(uname -m)
case "${ARCH}" in
    x86_64)
        ARCH="x86_64"
        ;;
    i386|i686)
        ARCH="i386"
        ;;
    armv*)
        ARCH="arm"
        ;;
    aarch64)
        ARCH="arm64"
        ;;
    *)
        error "Unsupported architecture: ${ARCH}"
        ;;
esac
echo "Detected architecture: ${ARCH}"

DNSCrypt_dir=/opt/dnscrypt-proxy
EXAMPLE_CONFIG_URL="https://raw.githubusercontent.com/marcomc/dnscrypt-proxy-install/refs/heads/main/example-dnscrypt-proxy.toml"

# Function to install curl based on the package manager
install_curl() {
    if ! command -v curl &> /dev/null; then
        if command -v apt-get &> /dev/null; then
            echo "Installing curl using apt-get"
            apt-get update || error "Failed to update package list"
            apt-get install -y curl || error "Failed to install curl"
        elif command -v yum &> /dev/null; then
            echo "Installing curl using yum"
            yum update -y || error "Failed to update package list"
            yum install -y curl || error "Failed to install curl"
        else
            error "Unsupported package manager"
        fi
    else
        echo "curl is already installed"
    fi
}

# Function to install dnscrypt-proxy
install_dnscrypt_proxy() {
    echo "Installing dnscrypt-proxy"
    LATEST_URL="https://api.github.com/repos/DNSCrypt/dnscrypt-proxy/releases/latest"
    echo "Fetching latest version from ${LATEST_URL}"
    VERSION=$(curl -s https://api.github.com/repos/DNSCrypt/dnscrypt-proxy/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    echo "Latest version: ${VERSION}"
    DOWNLOAD_URL="https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/${VERSION}/dnscrypt-proxy-linux_${ARCH}-${VERSION}.tar.gz"
    echo "DOWNLOAD_URL: ${DOWNLOAD_URL}"
    curl -L "${DOWNLOAD_URL}" -o dnscrypt-proxy.tar.gz || error "Failed to download dnscrypt-proxy"
    tar -xzf dnscrypt-proxy.tar.gz || error "Failed to extract dnscrypt-proxy"
    mv "linux-${ARCH}" "${DNSCrypt_dir}" || error "Failed to move dnscrypt-proxy to ${DNSCrypt_dir}"
    cp "${DNSCrypt_dir}"/dnscrypt-proxy /usr/local/bin/dnscrypt-proxy || error "Failed to copy dnscrypt-proxy binary to /usr/local/bin/"
    rm -rf "linux-${ARCH}" dnscrypt-proxy.tar.gz
}

# Function to configure dnscrypt-proxy
configure_dnscrypt_proxy() {
    echo "Configuring dnscrypt-proxy"
    if [[ ! -d "${DNSCrypt_dir}" ]]; then
        error "Failed to create ${DNSCrypt_dir} directory"
    fi

    if [[ -f "${DNSCrypt_dir}/dnscrypt-proxy.toml" ]]; then
        TIMESTAMP=$(date +%Y%m%d%H%M%S)
        cp "${DNSCrypt_dir}/dnscrypt-proxy.toml" "${DNSCrypt_dir}/dnscrypt-proxy.toml.bak.${TIMESTAMP}" || error "Failed to create backup of existing config file"
        echo "Backup of existing config file created with timestamp ${TIMESTAMP}"
    fi
    curl -L "${EXAMPLE_CONFIG_URL}" -o "${DNSCrypt_dir}/dnscrypt-proxy.toml" || error "Failed to download dnscrypt-proxy example config file"
}

# Function to create a systemd service for dnscrypt-proxy
create_systemd_service() {
    echo "Creating systemd service for dnscrypt-proxy"
    dnscrypt-proxy -config "${DNSCrypt_dir}/dnscrypt-proxy.toml" -service install || error "Failed to create systemd service"
}

# Function to enable and start the dnscrypt-proxy service
enable_and_start_service() {
    echo "Enabling and starting the dnscrypt-proxy service"
    systemctl enable dnscrypt-proxy || error "Failed to enable dnscrypt-proxy service"
    
    if systemctl is-active --quiet dnscrypt-proxy; then
        echo "dnscrypt-proxy service is already running, restarting it"
        systemctl restart dnscrypt-proxy || error "Failed to restart dnscrypt-proxy service"
    else
        echo "Starting dnscrypt-proxy service"
        systemctl start dnscrypt-proxy || error "Failed to start dnscrypt-proxy service"
    fi
    
    echo "Verifying that the dnscrypt-proxy service is running"
    systemctl status dnscrypt-proxy || error "dnscrypt-proxy service is not running"
}

# Function to uninstall dnscrypt-proxy and remove all files created by the script
uninstall_dnscrypt_proxy() {
    echo "Stopping dnscrypt-proxy service"
    systemctl stop dnscrypt-proxy || error "Failed to stop dnscrypt-proxy service"
    echo "Disabling dnscrypt-proxy service"
    systemctl disable dnscrypt-proxy || error "Failed to disable dnscrypt-proxy service"
    echo "Removing dnscrypt-proxy systemd service file"
    dnscrypt-proxy -service uninstall || error "Failed to remove dnscrypt-proxy systemd service file"
    echo "Removing ${DNSCrypt_dir} directory"
    rm -rf "${DNSCrypt_dir}" || error "Failed to remove ${DNSCrypt_dir} directory"
    echo "Removing dnscrypt-proxy binary"
    rm /usr/local/bin/dnscrypt-proxy || error "Failed to remove dnscrypt-proxy binary"
    echo "Reloading systemd daemon"
    systemctl daemon-reload || error "Failed to reload systemd daemon"
    echo "dnscrypt-proxy uninstalled successfully"
}

# Install curl if not already installed
install_curl

# Parse command line arguments
if [[ "$1" == "--help" ]]; then
    show_help
    exit 0
elif [[ "$1" == "--uninstall" ]]; then
    uninstall_dnscrypt_proxy
    exit 0
fi

# Download and install dnscrypt-proxy
if ! command -v dnscrypt-proxy &> /dev/null; then
    install_dnscrypt_proxy
    # Verify the installation
    echo "Verifying dnscrypt-proxy installation"
    dnscrypt-proxy -version || error "dnscrypt-proxy verification failed"
else
    echo "dnscrypt-proxy is already installed"
fi

# Configure dnscrypt-proxy
configure_dnscrypt_proxy

# Create a systemd service
create_systemd_service

# Enable and start the dnscrypt-proxy service
enable_and_start_service