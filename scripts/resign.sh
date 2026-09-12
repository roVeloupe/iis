#!/usr/bin/env bash
# ============================================================
# Liquid Glass Signer · IPA 重签名脚本（基于 zsign）
#
# 用法:
#   ./scripts/resign.sh -i app.ipa -c cert.p12 -p 密码 \
#       -m profile.mobileprovision [-b 新BundleID] [-n 新名称] [-o 输出.ipa]
# ============================================================
set -euo pipefail

INPUT=""
CERT=""
PASS=""
PROV=""
BUNDLE_ID=""
NAME=""
OUTPUT="signed.ipa"
REMOVE_PLUGINS=0

usage() {
  echo "用法: $0 -i <input.ipa> -c <cert.p12> -p <密码> -m <profile.mobileprovision> [-b <新BundleID>] [-n <新名称>] [-r] [-o <输出.ipa>]" >&2
  exit 1
}

while getopts "i:c:p:m:b:n:o:rh" opt; do
  case "$opt" in
    i) INPUT="$OPTARG" ;;
    c) CERT="$OPTARG" ;;
    p) PASS="$OPTARG" ;;
    m) PROV="$OPTARG" ;;
    b) BUNDLE_ID="$OPTARG" ;;
    n) NAME="$OPTARG" ;;
    o) OUTPUT="$OPTARG" ;;
    r) REMOVE_PLUGINS=1 ;;
    h) usage ;;
    *) usage ;;
  esac
done

[ -f "$INPUT" ] || { echo "错误: 找不到 IPA 文件 $INPUT" >&2; exit 1; }
[ -f "$CERT" ]  || { echo "错误: 找不到证书 $CERT" >&2; exit 1; }
[ -f "$PROV" ]  || { echo "错误: 找不到描述文件 $PROV" >&2; exit 1; }

# 校验 p12 密码是否正确
if ! openssl pkcs12 -in "$CERT" -passin pass:"$PASS" -info -noout >/dev/null 2>&1; then
  echo "错误: p12 证书密码不正确或证书已损坏" >&2
  exit 1
fi

# 准备 zsign（没有则自动编译）
if ! command -v zsign >/dev/null 2>&1 && [ ! -x ./zsign ]; then
  echo "未找到 zsign，正在从源码编译..."
  sudo apt-get update >/dev/null 2>&1 || true
  sudo apt-get install -y build-essential cmake libssl-dev zlib1g-dev git >/dev/null 2>&1 || true
  rm -rf /tmp/zsign
  git clone --depth 1 https://github.com/zhlynn/zsign.git /tmp/zsign
  (cd /tmp/zsign && cmake . >/dev/null && make >/dev/null)
  ZSIGN=/tmp/zsign/zsign
else
  ZSIGN="$(command -v zsign || echo ./zsign)"
fi

EXTRA=()
[ -n "$BUNDLE_ID" ] && EXTRA+=(-b "$BUNDLE_ID")
[ -n "$NAME" ] && EXTRA+=(-n "$NAME")
[ "$REMOVE_PLUGINS" = "1" ] && EXTRA+=(-r plugins)

echo "开始重签名: $INPUT -> $OUTPUT"
"$ZSIGN" -k "$CERT" -p "$PASS" -m "$PROV" -z 9 -o "$OUTPUT" "${EXTRA[@]}" "$INPUT"
echo "完成: $OUTPUT"
