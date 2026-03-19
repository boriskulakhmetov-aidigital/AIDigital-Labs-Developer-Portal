# AI Digital Labs MCP Server — Windows Installer
# Run this script in PowerShell to set up the MCP server for Claude Desktop.
#
# Usage: Right-click → Run with PowerShell
# Or: powershell -ExecutionPolicy Bypass -File install-windows.ps1

param(
    [string]$ApiKey = ""
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "  ║   AI Digital Labs — MCP Server Setup     ║" -ForegroundColor Blue
Write-Host "  ║   For Claude Desktop                     ║" -ForegroundColor Blue
Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

# Step 1: Check Node.js
Write-Host "[1/4] Checking Node.js..." -ForegroundColor Yellow
$nodeVersion = $null
try { $nodeVersion = (node --version 2>$null) } catch {}

if (-not $nodeVersion) {
    Write-Host "  Node.js not found. Opening download page..." -ForegroundColor Red
    Write-Host "  Please install Node.js from https://nodejs.org and run this script again." -ForegroundColor Red
    Start-Process "https://nodejs.org"
    Read-Host "Press Enter after installing Node.js"
    try { $nodeVersion = (node --version 2>$null) } catch {}
    if (-not $nodeVersion) {
        Write-Host "  Node.js still not found. Please restart this script after installation." -ForegroundColor Red
        exit 1
    }
}
Write-Host "  Node.js $nodeVersion found." -ForegroundColor Green

# Step 2: Get API Key
if (-not $ApiKey) {
    Write-Host ""
    Write-Host "[2/4] Enter your AI Digital Labs API key" -ForegroundColor Yellow
    Write-Host "  (starts with 'aidl_' — get one from your admin)" -ForegroundColor Gray
    $ApiKey = Read-Host "  API Key"
}

if (-not $ApiKey.StartsWith("aidl_")) {
    Write-Host "  Invalid API key format. Must start with 'aidl_'" -ForegroundColor Red
    exit 1
}
Write-Host "  API key accepted." -ForegroundColor Green

# Step 3: Install MCP server
Write-Host ""
Write-Host "[3/4] Installing MCP server..." -ForegroundColor Yellow
npm install -g aidigital-labs-mcp 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  npm install failed — installing from GitHub instead..." -ForegroundColor Yellow
    npm install -g "https://github.com/boriskulakhmetov-aidigital/AIDigital-Labs-Design-System.git#main" --install-strategy=nested 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Falling back to local npx mode (will download on first use)." -ForegroundColor Yellow
    }
}
Write-Host "  MCP server ready." -ForegroundColor Green

# Step 4: Configure Claude Desktop
Write-Host ""
Write-Host "[4/4] Configuring Claude Desktop..." -ForegroundColor Yellow

$configDir = "$env:APPDATA\Claude"
$configFile = "$configDir\claude_desktop_config.json"

# Create directory if needed
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

# Build config
$config = @{
    mcpServers = @{
        "aidigital-labs" = @{
            command = "npx"
            args = @("-y", "aidigital-labs-mcp")
            env = @{
                AIDIGITAL_API_KEY = $ApiKey
            }
        }
    }
}

# If config exists, merge (don't overwrite other MCP servers)
if (Test-Path $configFile) {
    try {
        $existing = Get-Content $configFile -Raw | ConvertFrom-Json -AsHashtable
        if ($existing.mcpServers) {
            $existing.mcpServers["aidigital-labs"] = $config.mcpServers["aidigital-labs"]
            $config = $existing
        }
    } catch {
        Write-Host "  Warning: Could not parse existing config. Creating new one." -ForegroundColor Yellow
    }
}

$config | ConvertTo-Json -Depth 10 | Set-Content $configFile -Encoding UTF8
Write-Host "  Config written to: $configFile" -ForegroundColor Green

# Done
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║   Setup complete!                        ║" -ForegroundColor Green
Write-Host "  ║                                          ║" -ForegroundColor Green
Write-Host "  ║   1. Restart Claude Desktop              ║" -ForegroundColor Green
Write-Host "  ║   2. Look for the hammer icon (tools)    ║" -ForegroundColor Green
Write-Host "  ║   3. Ask: 'Run a website audit on        ║" -ForegroundColor Green
Write-Host "  ║      example.com'                        ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  Available tools:" -ForegroundColor Cyan
Write-Host "    - website_audit" -ForegroundColor White
Write-Host "    - neuromarketing_audit" -ForegroundColor White
Write-Host "    - prompt_engineering" -ForegroundColor White
Write-Host "    - aio_scan" -ForegroundColor White
Write-Host "    - synthetic_focus_group" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to close"
