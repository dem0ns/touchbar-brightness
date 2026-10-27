#!/bin/bash
# Installs a per-user LaunchAgent that re-applies the remembered Touch Bar
# brightness at login and after corebrightnessd restarts.
#
#   ./install-agent.sh              install / update
#   ./install-agent.sh --uninstall  remove
#
# Run ./build.sh first so bin/tbright exists.

set -euo pipefail
cd "$(dirname "$0")"

LABEL="com.dem0ns.TouchBarBrightness.agent"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
DIR="$HOME/Library/Application Support/TouchBarBrightness"
BIN="$DIR/tbright"

if [ "${1:-}" = "--uninstall" ]; then
    launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
    rm -f "$PLIST"
    echo "已卸载 LaunchAgent（记住的亮度值保留，可用 tbright restore 手动恢复）"
    exit 0
fi

if [ ! -x "bin/tbright" ]; then
    echo "找不到 bin/tbright，先运行 ./build.sh" >&2
    exit 1
fi

mkdir -p "$DIR" "$HOME/Library/LaunchAgents"
cp bin/tbright "$BIN"
chmod +x "$BIN"

cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BIN</string>
        <string>restore</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>60</integer>
    <key>ProcessType</key>
    <string>Background</string>
    <key>ThrottleInterval</key>
    <integer>10</integer>
    <key>StandardOutPath</key>
    <string>$DIR/agent.log</string>
    <key>StandardErrorPath</key>
    <string>$DIR/agent.log</string>
</dict>
</plist>
PLIST

launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$UID" "$PLIST" 2>/dev/null || launchctl load "$PLIST"
launchctl kickstart -k "gui/$UID/$LABEL" 2>/dev/null || true

echo "已安装: $PLIST"
echo "  二进制: $BIN"
echo "  行为  : 登录时 + 每 60 秒执行一次 tbright restore（仅在记住过值时生效）"
echo "  日志  : $DIR/agent.log"
echo
echo "当前状态:"; "$BIN" || true
