#!/bin/bash

set -e

# Proxy configuration prompt
configure_proxy() {
    echo "🔧 Proxy Configuration"
    echo "Do you want to use a proxy? (y/n)"
    read -r use_proxy
    
    if [[ $use_proxy =~ ^[Yy]$ ]]; then
        echo "Please enter your proxy URL (e.g., http://proxy.company.com:8080 or http://user:pass@proxy:8080):"
        read -r proxy_url
        
        if [[ -n $proxy_url ]]; then
            echo "Configuring proxy settings..."
            export HTTP_PROXY="$proxy_url"
            export HTTPS_PROXY="$proxy_url"
            export http_proxy="$proxy_url"
            export https_proxy="$proxy_url"
            
            # Configure npm to use proxy
            npm config set proxy "$proxy_url"
            npm config set https-proxy "$proxy_url"
            
            echo "✅ Proxy configured: $proxy_url"
        else
            echo "⚠️  No proxy URL provided, continuing without proxy..."
        fi
    else
        echo "Continuing without proxy configuration..."
    fi
}

install_nodejs() {
    local platform=$(uname -s)
    
    case "$platform" in
        Linux|Darwin)
            echo "🚀 Installing Node.js on Unix/Linux/macOS..."
            
            echo "📥 Downloading and installing nvm..."
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
            
            echo "🔄 Loading nvm environment..."
            \. "$HOME/.nvm/nvm.sh"
            
            echo "📦 Downloading and installing Node.js v22..."
            nvm install 22
            
            echo -n "✅ Node.js installation completed! Version: "
            node -v # Should print "v22.17.0".
            echo -n "✅ Current nvm version: "
            nvm current # Should print "v22.17.0".
            echo -n "✅ npm version: "
            npm -v # Should print "10.9.2".
            ;;
        *)
            echo "Unsupported platform: $platform"
            exit 1
            ;;
    esac
}

# Configure proxy first
configure_proxy

# Install Claude Code globally first
echo "📦 Installing Claude Code globally..."
npm install -g @anthropic-ai/claude-code

# Then proceed with the rest of the installation
# Check if Node.js is already installed and version is >= 18
if command -v node >/dev/null 2>&1; then
    current_version=$(node -v | sed 's/v//')
    major_version=$(echo $current_version | cut -d. -f1)
    
    if [ "$major_version" -ge 18 ]; then
        echo "Node.js is already installed: v$current_version"
    else
        echo "Node.js v$current_version is installed but version < 18. Upgrading..."
        install_nodejs
    fi
else
    echo "Node.js not found. Installing..."
    install_nodejs
fi

# Check if Claude Code is already installed
if command -v claude >/dev/null 2>&1; then
    echo "Claude Code is already installed: $(claude --version)"
else
    echo "Claude Code not found. Installing..."
    npm install -g @anthropic-ai/claude-code
fi

# Configure Claude Code to skip onboarding
echo "Configuring Claude Code to skip onboarding..."
node --eval '
    const fs = require("fs");
    const path = require("path");
    const os = require("os");
    
    const homeDir = os.homedir(); 
    const filePath = path.join(homeDir, ".claude.json");
    
    if (fs.existsSync(filePath)) {
        const content = JSON.parse(fs.readFileSync(filePath, "utf-8"));
        fs.writeFileSync(filePath, JSON.stringify({ ...content, hasCompletedOnboarding: true }, null, 2), "utf-8");
    } else {
        fs.writeFileSync(filePath, JSON.stringify({ hasCompletedOnboarding: true }, null, 2), "utf-8");
    }
'

# Prompt user for API key
echo "🔑 Please enter your Moonshot API key:"
echo "   You can get your API key from: https://platform.moonshot.cn/console/api-keys"
echo "   Note: The input is hidden for security. Please paste your API key directly."
echo ""
read -s api_key
echo ""

if [ -z "$api_key" ]; then
    echo "⚠️  API key cannot be empty. Please run the script again."
    exit 1
fi

# Detect current shell and determine rc file
current_shell=$(basename "$SHELL")
case "$current_shell" in
    bash)
        rc_file="$HOME/.bashrc"
        ;;
    zsh)
        rc_file="$HOME/.zshrc"
        ;;
    fish)
        rc_file="$HOME/.config/fish/config.fish"
        ;;
    *)
        rc_file="$HOME/.profile"
        ;;
esac

# Add environment variables to rc file
echo ""
echo "📝 Adding environment variables to $rc_file..."

# Check if variables already exist to avoid duplicates
if [ -f "$rc_file" ] && grep -q "ANTHROPIC_BASE_URL\|ANTHROPIC_API_KEY" "$rc_file"; then
    echo "⚠️ Environment variables already exist in $rc_file. Skipping..."
else
    # Append new entries
    echo "" >> "$rc_file"
    echo "# Claude Code environment variables" >> "$rc_file"
    echo "export ANTHROPIC_BASE_URL=https://api.moonshot.cn/anthropic/" >> "$rc_file"
    echo "export ANTHROPIC_API_KEY=$api_key" >> "$rc_file"
    echo "✅ Environment variables added to $rc_file"
fi

# Add proxy configuration to rc file if proxy was configured
if [[ -n $HTTP_PROXY ]]; then
    echo "# Proxy configuration for Claude Code" >> "$rc_file"
    echo "export HTTP_PROXY=$HTTP_PROXY" >> "$rc_file"
    echo "export HTTPS_PROXY=$HTTPS_PROXY" >> "$rc_file"
    echo "export http_proxy=$http_proxy" >> "$rc_file"
    echo "export https_proxy=$https_proxy" >> "$rc_file"
    echo "✅ Proxy configuration added to $rc_file"
fi

echo ""
echo "🎉 Installation completed successfully!"
echo ""
echo "🔄 Please restart your terminal or run:"
echo "   source $rc_file"
echo ""
echo "🚀 Then you can start using Claude Code with:"
echo "   claude"
echo ""
if [[ -n $HTTP_PROXY ]]; then
    echo "📡 Proxy is configured: $HTTP_PROXY"
fi