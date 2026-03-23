#!/bin/bash

#移除luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

WIFI_SH=$(find ./target/linux/{mediatek/filogic,qualcommax}/base-files/etc/uci-defaults/ -type f -name "*set-wireless.sh" 2>/dev/null)
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -f "$WIFI_SH" ]; then
	#修改WIFI名称
	sed -i "s/BASE_SSID='.*'/BASE_SSID='$WRT_SSID'/g" $WIFI_SH
	#修改WIFI密码
	sed -i "s/BASE_WORD='.*'/BASE_WORD='$WRT_WORD'/g" $WIFI_SH
elif [ -f "$WIFI_UC" ]; then
	#修改WIFI名称
	sed -i "s/ssid='.*'/ssid='$WRT_SSID'/g" $WIFI_UC
	#修改WIFI密码
	sed -i "s/key='.*'/key='$WRT_WORD'/g" $WIFI_UC
	#修改WIFI地区
	sed -i "s/country='.*'/country='CN'/g" $WIFI_UC
	#修改WIFI加密
	sed -i "s/encryption='.*'/encryption='psk2+ccmp'/g" $WIFI_UC
fi

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

#高通平台调整
#DTS_PATH="./target/linux/qualcommax/dts/"
#if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
	#取消nss相关feed
#	echo "CONFIG_FEED_nss_packages=n" >> ./.config
#	echo "CONFIG_FEED_sqm_scripts_nss=n" >> ./.config
	#开启sqm-nss插件
#	echo "CONFIG_PACKAGE_luci-app-sqm=y" >> ./.config
#	echo "CONFIG_PACKAGE_sqm-scripts-nss=y" >> ./.config
	#设置NSS版本
#	echo "CONFIG_NSS_FIRMWARE_VERSION_11_4=n" >> ./.config
#	if [[ "${WRT_CONFIG,,}" == *"ipq50"* ]]; then
#		echo "CONFIG_NSS_FIRMWARE_VERSION_12_2=y" >> ./.config
#	else
#		echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> ./.config
#	fi
	#无WIFI配置调整Q6大小
#	if [[ "${WRT_CONFIG,,}" == *"wifi"* && "${WRT_CONFIG,,}" == *"no"* ]]; then
#		echo "WRT_WIFI=wifi-no" >> $GITHUB_ENV
#		find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
#		echo "qualcommax set up nowifi successfully!"
#	fi
	#其他调整
#	echo "CONFIG_PACKAGE_kmod-usb-serial-qualcomm=y" >> ./.config
#fi

function cat_ebpf_config() {
#ebpf相关
  cat >> .config <<EOF
# eBPF
# 生成内核调试信息 可选，daed可能需要
CONFIG_KERNEL_DEBUG_INFO=y
# 不使用简化调试信息 配合DEBUG_INFO=y使用
CONFIG_KERNEL_DEBUG_INFO_REDUCED=n
# 开启BTF支持 必选 ，现代eBPF程序依赖BTF
CONFIG_KERNEL_DEBUG_INFO_BTF=y
# 开启cgroups支持 必选 ，cgroup BPF依赖
CONFIG_KERNEL_CGROUPS=y1
# 开启cgroup BPF挂载点 必选 ，daed可能使用cgroup BPF
CONFIG_KERNEL_CGROUP_BPF=y
# 开启BPF事件支持 可选，用于BPF程序事件监控
CONFIG_KERNEL_BPF_EVENTS=y
# 使用主机BPF工具链 建议开启，提高编译效率
CONFIG_BPF_TOOLCHAIN_HOST=y
# 开启XDP套接字 必选 ，daed可能使用XDP加速
CONFIG_KERNEL_XDP_SOCKETS=y
# XDP套接字诊断模块 可选，用于调试XDP套接字
CONFIG_PACKAGE_kmod-xdp-sockets-diag=y

# 为了完整支持daed的eBPF功能，建议补充以下配置：
# 启用BPF JIT编译器（显著提升eBPF性能）
CONFIG_KERNEL_BPF_JIT=y
CONFIG_KERNEL_HAVE_BPF_JIT=y
# # 启用BPF LSM（可选，取决于daed是否使用）
# CONFIG_KERNEL_SECURITY_BPF=y
# # 启用BPF系统调用
# CONFIG_KERNEL_BPF_SYSCALL=y
# # 启用BPF挂载点
# CONFIG_KERNEL_BPF_LSM=y
# CONFIG_KERNEL_BPF_PRELOAD=y
# # 启用XDP支持（完整）
# CONFIG_KERNEL_XDP=y
# CONFIG_PACKAGE_kmod-ebpf-core=y
# CONFIG_PACKAGE_kmod-ebpf-filter=y
# CONFIG_PACKAGE_kmod-ebpf-testing=y
# # 启用libbpf库（用户空间eBPF支持）
# CONFIG_PACKAGE_libbpf=y
# CONFIG_PACKAGE_libbpf-dev=y
# # 启用cgroup相关BPF功能
# CONFIG_KERNEL_CGROUP_BPF=y
# CONFIG_KERNEL_CGROUP_NET_PRIO=y
# CONFIG_KERNEL_CGROUP_NET_CLASSID=y
EOF
}
cat_ebpf_config

# BPFtool 支持 eBPF 程序 反汇编（disassembly）
echo "CONFIG_PACKAGE_bpftool-full=y" >> ./.config
echo "CONFIG_PACKAGE_zoneinfo-all=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-daed=y" >> ./.config
