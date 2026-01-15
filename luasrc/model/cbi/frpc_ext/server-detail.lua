-- Copyright 2019 Xingwang Liao <kuoruan@gmail.com>
-- Licensed to the public under the MIT License.

local dsp = require "luci.dispatcher"

local m, s, o

local sid = arg[1]

m = Map("frpc_ext", "%s - %s" % { translate("Frpc"), translate("Edit Frps Server") })
m.redirect = dsp.build_url("admin/services/frpc-ext/servers")

if m.uci:get("frpc_ext", sid) ~= "server" then
	luci.http.redirect(m.redirect)
	return
end

s = m:section(NamedSection, sid, "server")
s.anonymous = true
s.addremove = false

o = s:option(Value, "alias", translate("Alias"))

o = s:option(Value, "server_addr", translate("Server addr"))
o.datatype = "host"
o.rmempty = false

o = s:option(Value, "server_port", translate("Server port"))
o.datatype = "port"
o.rmempty = false
o.description = translate("Legacy port for TCP; if multi-protocol ports below are set, this is used as fallback.")

o = s:option(Value, "tcp_port", translate("TCP port"))
o.datatype = "port"
o.placeholder = "7000"
o.description = translate("TCP control / work connection port for this frps.")

o = s:option(Value, "kcp_port", translate("KCP port"))
o.datatype = "port"
o.placeholder = "7000"
o.description = translate("KCP port; frpc will open an extra KCP connection if set.")

o = s:option(Value, "quic_port", translate("QUIC port"))
o.datatype = "port"
o.placeholder = "7000"
o.description = translate("QUIC port; frpc will open an extra QUIC connection if set.")

o = s:option(Value, "websocket_port", translate("WebSocket port"))
o.datatype = "port"
o.placeholder = "7000"
o.description = translate("WebSocket port; frpc will open an extra WebSocket connection if set.")

o = s:option(Value, "wss_port", translate("WSS port"))
o.datatype = "port"
o.placeholder = "7001"
o.description = translate("Secure WebSocket (wss) port; frpc will open an extra WSS connection if set.")

o = s:option(Value, "token", translate("Token"))
o.password = true

return m
