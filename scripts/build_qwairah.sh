#!/usr/bin/env bash
set -e
ROOT_DIR="$(pwd)"

rm -rf openwrt
git clone --branch openwrt-23.05 --depth 1 https://github.com/openwrt/openwrt.git openwrt
cd openwrt

mkdir -p package/kernel/mac80211/patches/subsys
sed -i 's/20)/40)/g' package/firmware/wireless-regdb/Makefile 2>/dev/null || true

./scripts/feeds update -a
./scripts/feeds install -a

find feeds/luci package -type f \( -name "*.htm" -o -name "*.js" -o -name "*.lua" -o -name "*.po" \) \
  -exec sed -i 's|AL-MALAKI|QWAIRAH|gi; s|https://github.com/openwrt/luci|#|g; s|Powered by LuCI.*|QWAIRAH|g' {} + 2>/dev/null || true

cat << 'CONF' > .config
CONFIG_TARGET_ipq40xx=y
CONFIG_TARGET_ipq40xx_generic=y
CONFIG_TARGET_ipq40xx_generic_DEVICE_giga_kt-9200=y
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-mod-admin-full=y
CONFIG_PACKAGE_luci-i18n-base-ar=y
CONFIG_PACKAGE_luci-i18n-base-en=y
CONFIG_PACKAGE_luci-i18n-opkg-ar=y
CONFIG_PACKAGE_luci-theme-bootstrap=y
CONFIG_PACKAGE_luci-app-lldpd=y
CONFIG_PACKAGE_lldpd=y
CONFIG_PACKAGE_luci-app-sqm=y
CONFIG_PACKAGE_luci-i18n-sqm-ar=y
CONFIG_PACKAGE_luci-app-nlbwmon=y
CONFIG_PACKAGE_luci-app-commands=y
CONFIG_PACKAGE_luci-app-ttyd=y
CONFIG_PACKAGE_luci-app-watchcat=y
CONFIG_PACKAGE_vnstat2=y
CONFIG_PACKAGE_wpad-mesh-openssl=y
CONFIG_PACKAGE_kmod-batman-adv=y
CONFIG_PACKAGE_openssh-sftp-server=y
CONFIG_PACKAGE_dropbear=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_jq=y
CONFIG_PACKAGE_iw=y
CONFIG_PACKAGE_iwinfo=y
CONFIG_PACKAGE_ethtool=y
CONFIG_PACKAGE_ip-full=y
CONFIG_PACKAGE_iptables-mod-extra=y
CONF

make defconfig
make toolchain/install -j"$(nproc)"

CC_BIN=$(find staging_dir/toolchain-arm_cortex-a7*gcc*/bin/arm-openwrt-linux-gcc 2>/dev/null | head -n 1)
mkdir -p "$ROOT_DIR/files/usr/bin"
if [ -n "$CC_BIN" ]; then
    "$CC_BIN" -O2 -s "$ROOT_DIR/src/qwairah_mndp.c" -o "$ROOT_DIR/files/usr/bin/qwairah_mndp"
    chmod +x "$ROOT_DIR/files/usr/bin/qwairah_mndp"
fi

cp -rf "$ROOT_DIR/files/." files/

make -j"$(nproc)" || { make -j1 target/linux/install V=sc; exit 1; }

mkdir -p "$ROOT_DIR/artifacts_out"
cp -f bin/targets/ipq40xx/generic/*sysupgrade.bin bin/targets/ipq40xx/generic/*kernel.bin "$ROOT_DIR/artifacts_out/" 2>/dev/null || true
ls -lh "$ROOT_DIR/artifacts_out/"
