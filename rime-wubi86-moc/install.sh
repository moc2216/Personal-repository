#!/usr/bin/env bash
# 项目根一键部署：清空 ~/Library/Rime + 拷贝 dist 全量数据 + 自动编译字典。
# 完成后选 moc_wubi86_simp 或 moc_wubi86_simp_plus 即可。
# ⚠ 手填的 moc_wubi86_user.dict.yaml 会被重置为空壳——如需保留请先备份。
set -e
D="$(cd "$(dirname "$0")" && pwd)"
DIST="$D/dist"
if [ ! -f "$DIST/moc_wubi86_core.dict.yaml" ]; then
    echo "❌ dist/ 不存在或不完整，请先运行：python3 work/build_moc_wubi86.py"
    exit 1
fi

R=~/Library/Rime
echo "→ 清空 $R ..."
rm -rf "$R"
mkdir -p "$R"
echo "→ 拷贝 dist 全量数据 ..."
cp -R "$DIST/." "$R/"

# 自动编译字典（含 moc_reverse 反查 prism）
# 1) 优先 rime_deployer --build（离线编译，不中断输入法）
# 2) 找不到/失败则重启 Squirrel（启动时自动编译缺失 prism/bin）
SQUIRREL=""
for cand in "/Library/Input Methods/Squirrel.app" "$HOME/Library/Input Methods/Squirrel.app"; do
    [ -d "$cand" ] && SQUIRREL="$cand" && break
done
DEP="$SQUIRREL/Contents/MacOS/rime_deployer"
SH="$SQUIRREL/Contents/SharedSupport"
BUILT=0
if [ -n "$SQUIRREL" ] && [ -x "$DEP" ]; then
    echo "→ 编译字典（rime_deployer）..."
    if "$DEP" --build "$R" "$SH"; then
        echo "✓ 已编译字典（含反查 prism）"
        BUILT=1
    else
        echo "⚠ rime_deployer 编译失败，改用重启 Squirrel 兜底"
    fi
else
    echo "⚠ 未找到 rime_deployer（探测路径: ${SQUIRREL:-无}），改用重启 Squirrel 兜底"
fi

# 重启 Squirrel：让它加载新字典，缺失的 prism/bin 会自动编译
if pgrep -x Squirrel >/dev/null 2>&1; then
    echo "→ 重启 Squirrel 加载新字典..."
    killall Squirrel 2>/dev/null || true
    sleep 1
    if [ -n "$SQUIRREL" ]; then
        open "$SQUIRREL" 2>/dev/null || true
    else
        open -a Squirrel 2>/dev/null || true
    fi
    echo "✓ Squirrel 已重启（首次激活会自动编译字典）"
fi

echo "✓ 已部署到 $R"
echo "→ 切换到 moc_wubi86_simp 或 moc_wubi86_simp_plus 即可。"
