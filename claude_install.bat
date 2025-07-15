@echo off
setlocal enabledelayedexpansion

:: Claude Code Installation Script for Windows
:: This script installs Node.js (if needed), Claude Code, and configures the environment

echo ================================================
echo Claude Code Installation for Windows
echo ================================================
echo.

:: Check if running as administrator
echo Checking administrator privileges...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Please run this script as Administrator

    exit /b 1
)

:: Proxy configuration
echo Proxy Configuration
echo Do you want to use a proxy? (y/n)
set /p use_proxy=

set proxy_scope=none
set proxy_url=

if /i "%use_proxy%"=="y" (
    echo Please enter your proxy URL (e.g., http://proxy.company.com:8080 or http://user:pass@proxy:8080^):
    set /p proxy_url=
    
    if not "!proxy_url!"=="" (
        echo.
        echo Proxy scope:
        echo 1. Global proxy (affects all commands and persists in system environment^)
        echo 2. npm-only proxy (only affects npm, no global environment variables^)
        set /p proxy_scope_choice=
        
        if "!proxy_scope_choice!"=="2" (
            set proxy_scope=npm_only
            echo Configuring npm-only proxy...
            call npm config set proxy "!proxy_url!"
            call npm config set https-proxy "!proxy_url!"
            echo npm proxy configured: !proxy_url!
        ) else (
            set proxy_scope=global
            echo Configuring global proxy...
            set "HTTP_PROXY=!proxy_url!"
            set "HTTPS_PROXY=!proxy_url!"
            set "http_proxy=!proxy_url!"
            set "https_proxy=!proxy_url!"
            
            :: Configure npm to use proxy
            call npm config set proxy "!proxy_url!"
            call npm config set https-proxy "!proxy_url!"
            
            echo Global proxy configured: !proxy_url!
        )
    ) else (
        echo No proxy URL provided, continuing without proxy...
    )
) else (
    echo Continuing without proxy configuration...
)

goto :after_proxy
:after_proxy

echo.
echo Installing Node.js on Windows...

:: Check if Node.js is already installed and version >= 18
node --version >nul 2>&1
if %errorlevel% equ 0 (
    :: Capture and display raw version output
      for /f "usebackq delims=" %%i in (`node --version 2^>^&1`) do (
          echo Raw Node.js version output: %%i
          set "raw_version=%%i"
      )
    :: Extract major version directly by splitting version string
          for /f "delims=" %%a in ('powershell -Command "$raw = \"!raw_version!\"; $cleaned = $raw.TrimStart('vV'); $dotIndex = $cleaned.IndexOf('.'); if ($dotIndex -ge 0) { $major = $cleaned.Substring(0, $dotIndex) } else { $major = $cleaned }; if ([int]::TryParse($major, [ref]$null)) { $major } else { Write-Error \"Invalid version format: $raw\"; exit 1 }"') do set "major_version=%%a"
      )
        :: Validate major version extraction
        if not defined major_version (
            echo Error: Failed to extract Node.js major version. Please ensure Node.js is installed correctly.
            exit /b 1
        )
        echo Extracted major version: !major_version!
    
    if !major_version! geq 18 (
          echo Node.js is already installed: v!major_version!
          goto :install_claude
      ) else (
        echo Node.js v!major_version! is installed but version ^< 18. Upgrading...
        goto :install_node_with_nvm
    )
) else (
    echo Node.js not found. Installing...
    goto :install_node_with_nvm
)

:: Skip to Claude Code installation
goto :install_claude

:install_node_with_nvm
echo Checking for nvm-windows...

:: Check if nvm is installed
nvm version >nul 2>&1
if %errorlevel% neq 0 (
    echo Downloading and installing nvm-windows...
    
    :: Download nvm-windows installer
    :: Use WebClient with proxy credential support
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $webClient = New-Object System.Net.WebClient; $webClient.Timeout = 300000; Write-Host 'Downloading nvm-setup.exe from GitHub...'; if ('!proxy_url!' -ne '') { Write-Host 'Using proxy: !proxy_url!'; $proxy = New-Object System.Net.WebProxy('!proxy_url!', $true); $creds = [System.Net.CredentialCache]::DefaultCredentials; if ($proxy.Address.UserInfo) { $userPass = $proxy.Address.UserInfo -split ':'; $creds = New-Object System.Net.NetworkCredential($userPass[0], $userPass[1]); Write-Host 'Using proxy credentials for user: ' $userPass[0]; } $webClient.Proxy = $proxy; $webClient.Proxy.Credentials = $creds; }; try { $webClient.DownloadFile('https://github.com/coreybutler/nvm-windows/releases/download/1.1.12/nvm-setup.exe', '%TEMP%\nvm-setup.exe'); Write-Host 'Download completed successfully'; } catch { Write-Host 'Download failed: ' $_.Exception.Message; Write-Host 'Attempting alternative download...'; try { $webClient.DownloadFile('https://cdn.npmmirror.com/binaries/nvm-windows/1.1.12/nvm-setup.exe', '%TEMP%\nvm-setup.exe'); Write-Host 'Alternative download completed successfully'; } catch { Write-Host 'Alternative download failed: ' $_.Exception.Message; exit 1 } }"
    if %errorlevel% neq 0 (
        echo Failed to download nvm-setup.exe. Check your network/proxy settings.
        exit /b 1
    )
    
    :: Check if installer exists
    if not exist "%TEMP%\nvm-setup.exe" (
        echo Failed to download nvm-setup.exe
        exit /b 1
    )
    :: Run the installer
    "%TEMP%\nvm-setup.exe" || (echo Failed to run installer & exit /b 1)
    
    :: Refresh environment variables
    :: Refresh environment variables and add NVM to PATH
    set "NVM_HOME=%USERPROFILE%\AppData\Roaming\nvm"
    :: Get NVM root directory with error handling
      for /f "tokens=*" %%i in ('nvm root 2^>nul') do set "NVM_ROOT=%%i"
      if not defined NVM_ROOT (
          echo Failed to determine NVM root directory
          set "NVM_ROOT=%USERPROFILE%\AppData\Roaming\nvm"
          echo Using default NVM root: !NVM_ROOT!
      )
    set "NVM_SYMLINK=%NVM_ROOT%\v22.17.0"
    set "PATH=%NVM_HOME%;%NVM_SYMLINK%;%PATH%"
    :: Verify nvm installation
    nvm version >nul 2>&1
    if %errorlevel% neq 0 (
        echo nvm installation not detected. Attempting to locate...
        if exist "%NVM_HOME%\nvm.exe" (
            set "PATH=%NVM_HOME%;%PATH%"
            nvm version >nul 2>&1 || (
                echo Failed to initialize nvm. Please restart your terminal.
                pause
                exit /b 1
            )
        ) else (
            echo nvm.exe not found in default path. Please reinstall nvm-windows.
            pause
            exit /b 1
        )
    )
)

echo Downloading and installing Node.js v22...
nvm install 22 || (
        echo Failed to install Node.js v22 using nvm
        exit /b 1
    )
nvm use 22 || (
        echo Failed to set Node.js v22 as active version
        exit /b 1
    )
nvm use 22

echo Node.js installation completed!
node --version
echo npm version:
npm --version

goto :install_claude

:install_claude
echo.
echo Installing Claude Code globally...
call npm install -g @anthropic-ai/claude-code --verbose

  if !errorlevel! neq 0 (
      echo [ERROR] npm installation failed with code !errorlevel!
      pause
      exit /b !errorlevel!
  )
  where claude >nul 2>&1
  if !errorlevel! equ 0 (
      call claude --version
  ) else (
      echo [ERROR] Claude not found in PATH after installation
      npm root -g
      pause
  )



:: Configure Claude Code to skip onboarding
echo.
echo Configuring Claude Code to skip onboarding...
powershell -Command "$homeDir = $env:USERPROFILE; $filePath = Join-Path $homeDir '.claude.json'; if (Test-Path $filePath) { $content = Get-Content $filePath -Raw | ConvertFrom-Json; $content | Add-Member -MemberType NoteProperty -Name 'hasCompletedOnboarding' -Value $true -Force; $content | ConvertTo-Json -Depth 10 | Set-Content $filePath; } else { @{ hasCompletedOnboarding = $true } | ConvertTo-Json -Depth 10 | Set-Content $filePath; }"

:: Prompt user for API key
echo.
echo Please enter your Moonshot API key:
echo    You can get your API key from: https://platform.moonshot.cn/console/api-keys
echo    Note: The input is hidden for security. Please paste your API key directly.
echo.

:: Create a temporary PowerShell script to get secure input
powershell -Command "$apiKey = Read-Host 'Enter your API key' -AsSecureString; $plainApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey)); $plainApiKey | Out-File -FilePath '%TEMP%\claude_api_key.txt' -Encoding ASCII -NoNewline;"

:: Read the API key from file
for /f "delims=" %%a in ('type %TEMP%\claude_api_key.txt') do set "api_key=%%a"
del %TEMP%\claude_api_key.txt

if "%api_key%"=="" (
    echo API key cannot be empty. Please run the script again.
    pause
    exit /b 1
)

:: Add environment variables to user profile
echo.
echo Adding environment variables to user profile...

:: Check if variables already exist
set key_exists=0
for /f "delims=" %%i in ('reg query "HKEY_CURRENT_USER\Environment" /v ANTHROPIC_API_KEY 2^>nul') do (
    set key_exists=1
)

if %key_exists%==1 (
    echo Environment variables already exist. Updating...
) else (
    echo Adding new environment variables...
)

:: Set user environment variables
setx ANTHROPIC_BASE_URL "https://api.moonshot.cn/anthropic/" >nul
setx ANTHROPIC_API_KEY "!api_key!" >nul

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
echo Installation completed successfully!
echo ================================================
echo.
echo Please restart your terminal for changes to take effect
echo.
echo Then you can start using Claude Code with:
echo    claude
echo.

if "%proxy_scope%"=="global" if not "!proxy_url!"=="" (
    echo Proxy is configured: !proxy_url!
    echo.
)

pause
