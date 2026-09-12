#!/usr/bin/env bash
# ============================================================
# Liquid Glass Signer · 证书管理工具
# 查看 p12 证书 / mobileprovision 描述文件的详细信息，
# 以及从 IPA 中提取原始签名信息，用于排查签名问题。
#
# 用法:
#   ./scripts/inspect.sh p12   cert.p12   <密码>
#   ./scripts/inspect.sh prov  profile.mobileprovision
#   ./scripts/inspect.sh ipa   app.ipa
# ============================================================
set -euo pipefail

MODE="${1:-}"
shift || true

case "$MODE" in
  p12)
    CERT="${1:?用法: inspect.sh p12 <cert.p12> <密码>}"
    PASS="${2:?缺少密码}"
    echo "===== p12 证书信息 ====="
    openssl pkcs12 -in "$CERT" -passin pass:"$PASS" -info -noout 2>&1
    echo
    echo "===== 证书主题 / 有效期 ====="
    openssl pkcs12 -in "$CERT" -passin pass:"$PASS" -clcerts -nokeys \
      | openssl x509 -noout -subject -issuer -dates -fingerprint -sha1
    ;;
  prov)
    PROV="${1:?用法: inspect.sh prov <profile.mobileprovision>}"
    echo "===== 描述文件信息 ====="
    if command -v security >/dev/null 2>&1; then
      security cms -D -i "$PROV"
    else
      openssl smime -inform DER -verify -noverify -in "$PROV" 2>/dev/null \
        || openssl smime -inform PEM -verify -noverify -in "$PROV" 2>/dev/null \
        || { echo "无法解析描述文件（需要 macOS 的 security 或 openssl smime）" >&2; exit 1; }
    fi
    ;;
  ipa)
    IPA="${1:?用法: inspect.sh ipa <app.ipa>}"
    TMP=$(mktemp -d)
    echo "===== IPA 签名信息 ====="
    unzip -q "$IPA" -d "$TMP"
    APP=$(find "$TMP/Payload" -maxdepth 1 -name "*.app" | head -n 1)
    [ -n "$APP" ] || { echo "错误: IPA 中没有 .app" >&2; exit 1; }
    echo "应用: $(basename "$APP")"
    echo "Bundle ID: $(defaults read "$APP/Info" CFBundleIdentifier 2>/dev/null || /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP/Info.plist" 2>/dev/null || echo 'N/A')"
    echo
    echo "签名信息:"
    codesign -dv --verbose=4 "$APP" 2>&1 || true
    echo
    echo "已安装描述文件:"
    if [ -f "$APP/embedded.mobileprovision" ]; then
      security cms -D -i "$APP/embedded.mobileprovision" 2>/dev/null || echo "(需要 macOS 才能完整解析)"
    else
      echo "(IPA 中未发现 embedded.mobileprovision)"
    fi
    rm -rf "$TMP"
    ;;
  *)
    echo "用法: $0 {p12|prov|ipa} ..." >&2
    echo "  $0 p12  <cert.p12> <密码>             查看证书信息" >&2
    echo "  $0 prov <profile.mobileprovision>     查看描述文件信息" >&2
    echo "  $0 ipa  <app.ipa>                     查看 IPA 签名状态" >&2
    exit 1
    ;;
esac
