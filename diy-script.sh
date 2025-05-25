#!/bin/bash

# 修改默认IP为10.0.0.1
sed -i 's/192.168.1.1/10.0.0.1/g' package/base-files/files/bin/config_generate

# 修改默认网关为10.0.0.111
sed -i "/set network.\$1.gateway/s/192.168.1.1/10.0.0.111/g" package/base-files/files/bin/config_generate

# 移除所有非必要组件
rm -rf feeds/packages/net/mosdns
rm -rf feeds/packages/net/msd_lite
rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/luci/applications/luci-app-netdata

# 仅保留passwall核心依赖
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# 仅添加passwall必要组件
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages package/openwrt-passwall
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall package/luci-app-passwall

# 保留默认主题配置（不删除bootstrap主题）
sed -i '/set luci.main.mediaurlbase/d' package/feeds/luci/luci-theme-bootstrap/root/etc/uci-defaults/30_luci-theme-bootstrap

# 基础网络配置
./scripts/feeds update -a
./scripts/feeds install -a

# 强制覆盖默认主题设置
echo "uci set luci.main.mediaurlbase='/luci-static/bootstrap'" >> package/base-files/files/etc/uci-defaults/30_luci-theme-bootstrap
