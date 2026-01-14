#
# Copyright 2019 Xingwang Liao <kuoruan@gmail.com>
# Licensed to the public under the MIT License.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-frpc-ext
PKG_VERSION:=1.2.1
PKG_RELEASE:=1

PKG_LICENSE:=MIT
PKG_MAINTAINER:=Xingwang Liao <kuoruan@gmail.com>

LUCI_TITLE:=LuCI support for Frpc (ext)
LUCI_DEPENDS:=+luci-base +frpc-ext
LUCI_PKGARCH:=all

define Package/$(PKG_NAME)/conffiles
/etc/config/frpc_ext
endef

include $(TOPDIR)/feeds/luci/luci.mk

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	if [ -f "/etc/uci-defaults/40_luci-frpc_ext" ]; then
		. /etc/uci-defaults/40_luci-frpc_ext
		rm -f /etc/uci-defaults/40_luci-frpc_ext
	fi
fi

chmod 755 "$${IPKG_INSTROOT}/etc/init.d/frpc_ext" >/dev/null 2>&1
ln -sf "../init.d/frpc_ext" \
	"$${IPKG_INSTROOT}/etc/rc.d/S99frpc_ext" >/dev/null 2>&1
exit 0
endef

# call BuildPackage - OpenWrt buildroot signature
