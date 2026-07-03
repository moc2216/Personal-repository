#!/usr/bin/env bash
# moc 86 五笔全量部署脚本（清空 ~/Library/Rime 后运行此脚本）
# 会覆盖同名文件；手填的 user 词表会被重置为空壳——如需保留请先备份。
set -e
D="$(cd "$(dirname "$0")" && pwd)"      # 本脚本所在 dist 目录
R=~/Library/Rime
rm -rf "$R"                              # 清空整个 ~/Library/Rime（手填 user.dict 会丢，需保留先备份）
mkdir -p "$R"
cp -R "$D/." "$R/"                        # 全量拷贝：schema/dict/lua/squirrel/default.custom.yaml/user 词表

# 自动编译字典（含 moc_reverse 反查 prism），免去手动点「重新部署」
DEP="/Library/Input Methods/Squirrel.app/Contents/MacOS/rime_deployer"
SH="/Library/Input Methods/Squirrel.app/Contents/SharedSupport"
if [ -x "$DEP" ]; then
    "$DEP" --build "$R" "$SH" && echo "✓ 已编译字典（含反查 prism）"
else
    echo "⚠ 未找到 Squirrel rime_deployer，请鼠须管菜单点「重新部署」"
fi

echo "✓ 已部署到 $R"
echo "→ 切换到 moc_wubi86_simp 或 moc_wubi86_simp_plus 即可。"
