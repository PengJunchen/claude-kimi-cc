@echo off
setlocal enabledelayedexpansion

:: Claude Code Installation Script for Windows
:: This script installs Node.js (if needed), Claude Code, and configures the environment

echo ================================================
echo 🚀 Claude Code Installation for Windows
echo ================================================
echo.

:: Check if running as administrator
echo Checking administrator privileges...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Please run this script as Administrator
    pause
    exit /b 1
)

:: Proxy configuration
echo 🔧 Proxy Configuration
echo Do you want to use a proxy? (y/n)
set /p use_proxy=

if /i "%use_proxy%"=="y" (
    echo Please enter your proxy URL (e.g., http://proxy.company.com:8080 or http://user:pass@proxy:8080):
    set /p proxy_url=
    
    if not "%proxy_url%"=="" (
        set proxy_url=%proxy_url%
        echo.
        echo Proxy scope:
        echo 1. Global proxy (affects all commands and persists in system environment)
        echo 2. npm-only proxy (only affects npm, no global environment variables)
        set /p proxy_scope_choice=
        
        if "%proxy_scope_choice%"=="2" (
            set proxy_scope=npm_only
            echo Configuring npm-only proxy...
            call npm config set proxy "%proxy_url%"
            call npm config set https-proxy "%proxy_url%"
            echo ✅ npm proxy configured: %proxy_url%
        ) else (
            set proxy_scope=global
            echo Configuring global proxy...
            set HTTP_PROXY=%proxy_url%
            set HTTPS_PROXY=%proxy_url%
            set http_proxy=%proxy_url%
            set https_proxy=%proxy_url%
            
            :: Configure npm to use proxy
            call npm config set proxy "%proxy_url%"
            call npm config set https-proxy "%proxy_url%"
            
            echo ✅ Global proxy configured: %proxy_url%
        )
    ) else (
        echo ⚠️  No proxy URL provided, continuing without proxy...
        set proxy_scope=none
    )
) else (
    echo Continuing without proxy configuration...
    set proxy_scope=none
)

:: Function to install Node.js using nvm-windows
goto :install_nodejs

:install_nodejs
echo.
echo 🚀 Installing Node.js on Windows...

:: Check if Node.js is already installed and version >= 18
node --version >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=1 delims=v" %%i in ('node --version') do set current_version=%%i
    for /f "tokens=1 delims=." %%i in ("%current_version%") do set major_version=%%i
    
    if %major_version% geq 18 (
        echo Node.js is already installed: v%current_version%
    ) else (
        echo Node.js v%current_version% is installed but version ^< 18. Upgrading...
        goto :install_node_with_nvm
    )
) else (
    echo Node.js not found. Installing...
    goto :install_node_with_nvm
)

:: Skip to Claude Code installation
goto :install_claude

:install_node_with_nvm
echo 📥 Checking for nvm-windows...

:: Check if nvm is installed
nvm version >nul 2>&1
if %errorlevel% neq 0 (
    echo 📥 Downloading and installing nvm-windows...
    
    :: Download nvm-windows installer
    if "%proxy_scope%"=="npm_only" if not "%proxy_url%"=="" (
        powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $webClient = New-Object System.Net.WebClient; $webClient.Proxy = New-Object System.Net.WebProxy('%proxy_url%'); $webClient.DownloadFile('https://github.com/coreybutler/nvm-windows/releases/download/1.1.12/nvm-setup.exe', '%TEMP%\nvm-setup.exe')"
    ) else (
        powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/coreybutler/nvm-windows/releases/download/1.1.12/nvm-setup.exe' -OutFile '%TEMP%\nvm-setup.exe'"
    )
    
    :: Run the installer
    %TEMP%\nvm-setup.exe
    
    :: Refresh environment variables
    call refreshenv.cmd >nul 2>&1 || (
        echo ⚠️  Please restart your terminal and run this script again
        pause
        exit /b 1
    )
)

echo 📦 Downloading and installing Node.js v22...
nvm install 22
nvm use 22

echo ✅ Node.js installation completed!
node --version
echo ✅ npm version:
npm --version

goto :install_claude

:install_claude
echo.
echo 📦 Installing Claude Code globally...

:: Check if Claude Code is already installed
claude --version >nul 2>&1
if %errorlevel% equ 0 (
    echo Claude Code is already installed: 
    claude --version
) else (
    echo Claude Code not found. Installing...
    call npm install -g @anthropic-ai/claude-code
)

:: Configure Claude Code to skip onboarding
echo.
echo Configuring Claude Code to skip onboarding...
powershell -Command "
$homeDir = $env:USERPROFILE;
$filePath = Join-Path $homeDir '.claude.json';

if (Test-Path $filePath) {
    $content = Get-Content $filePath -Raw | ConvertFrom-Json;
    $content | Add-Member -MemberType NoteProperty -Name 'hasCompletedOnboarding' -Value $true -Force;
    $content | ConvertTo-Json -Depth 10 | Set-Content $filePath;
} else {
    @{ hasCompletedOnboarding = $true } | ConvertTo-Json -Depth 10 | Set-Content $filePath;
}"

:: Prompt user for API key
echo.
echo 🔑 Please enter your Moonshot API key:
echo    You can get your API key from: https://platform.moonshot.cn/console/api-keys
echo    Note: The input is hidden for security. Please paste your API key directly.
echo.

:: Create a temporary PowerShell script to get secure input
powershell -Command "
$apiKey = Read-Host 'Enter your API key' -AsSecureString;
$plainApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey));
$plainApiKey | Out-File -FilePath '%TEMP%\claude_api_key.txt' -Encoding UTF8;
"

:: Read the API key from file
set /p api_key=<%TEMP%\claude_api_key.txt
del %TEMP%\claude_api_key.txt

if "%api_key%"=="" (
    echo ⚠️  API key cannot be empty. Please run the script again.
    pause
    exit /b 1
)

:: Add environment variables to user profile
echo.
echo 📝 Adding environment variables to user profile...

:: Check if variables already exist
set key_exists=0
for /f "delims=" %%i in ('reg query "HKEY_CURRENT_USER\Environment" /v ANTHROPIC_API_KEY 2^>nul') do (
    set key_exists=1
)

if %key_exists%==1 (
    echo ⚠️  Environment variables already exist. Updating...
) else (
    echo ✅ Adding new environment variables...
)

:: Set user environment variables
setx ANTHROPIC_BASE_URL "https://api.moonshot.cn/anthropic/" >nul
setx ANTHROPIC_API_KEY "%api_key%" >nul

:: Clean up global proxy if configured
if "%proxy_scope%"=="global" (
    echo.
    echo Cleaning up global proxy settings...
    set HTTP_PROXY=
    set HTTPS_PROXY=
    set http_proxy=
    set https_proxy=
    echo ✅ Global proxy settings removed from current session
)

echo.
echo ================================================
echo 🎉 Installation completed successfully!
echo ================================================
echo.
echo 🔄 Please restart your terminal for changes to take effect
echo.
echo 🚀 Then you can start using Claude Code with:
echo    claude
echo.

if "%proxy_scope%"=="global" if not "%proxy_url%"=="" (
    echo 📡 Proxy is configured: %proxy_url%
    echo.
)

pause