-- Copyright 2019 Xingwang Liao <kuoruan@gmail.com>
-- Licensed to the public under the MIT License.

local uci = require "luci.model.uci".cursor()
local util = require "luci.util"
local fs = require "nixio.fs"
local sys = require "luci.sys"

local m, s, o
local server_table = { }

uci:foreach("frpc_ext", "server", function(s)
	if s.alias then
		server_table[s[".name"]] = s.alias
	elseif s.server_addr and s.server_port then
		local ip = s.server_addr
		if s.server_addr:find(":") then
			ip = "[%s]" % s.server_addr
		end
		server_table[s[".name"]] = "%s:%s" % { ip, s.server_port }
	end
end)

local function frpc_version()
	local file = uci:get("frpc_ext", "main", "client_file")

	if not file or file == "" or not fs.stat(file) then
		return "<em style=\"color: red;\">%s</em>" % translate("Invalid client file")
	end

	if not fs.access(file, "rwx", "rx", "rx") then
		fs.chmod(file, 755)
	end

	local version = util.trim(sys.exec("%s -v 2>/dev/null" % file))
	if version == "" then
		return "<em style=\"color: red;\">%s</em>" % translate("Can't get client version")
	end
	return translatef("Version: %s", version)
end

m = Map("frpc_ext", "%s - %s" % { translate("Frpc"), translate("Common Settings") },
"<p>%s</p><p>%s</p>" % {
	translate("Frp is a fast reverse proxy to help you expose a local server behind a NAT or firewall to the internet."),
	translatef("For more information, please visit: %s",
		"<a href=\"https://github.com/fatedier/frp\" target=\"_blank\">https://github.com/fatedier/frp</a>")
})

m:append(Template("frpc_ext/status_header"))

s = m:section(NamedSection, "main", "frpc")
s.addremove = false
s.anonymous = true

s:tab("general", translate("General Options"))
s:tab("advanced", translate("Advanced Options"))
s:tab("manage", translate("Manage Options"))

o = s:taboption("general", Flag, "enabled", translate("Enabled"))
o.description = translate("Enable frpc service at boot and keep it running.")

o = s:taboption("general", Value, "client_file", translate("Client file"), frpc_version())
o.datatype = "file"
o.rmempty = false
o.description = translate("Path to the frpc binary; used for version checks and startup.")

o = s:taboption("general", MultiValue, "servers", translate("Servers"))
o.widget = "checkbox"
for k, v in pairs(server_table) do
	o:value(k, v)
end
o.description = translate("Select frps servers to register; leave empty to use all defined servers.")

o = s:taboption("general", ListValue, "run_user", translate("Run daemon as user"))
o:value("", translate("-- default --"))
local user
for user in util.execi("cat /etc/passwd | cut -d':' -f1") do
	o:value(user)
end
o.description = translate("Run frpc under this system user (drops privileges after start).")

o = s:taboption("general", Flag, "enable_logging", translate("Enable logging"))
o.description = translate("Write frpc logs to a file.")

o = s:taboption("general", Value, "log_file", translate("Log file"))
o:depends("enable_logging", "1")
o.placeholder = "/var/log/frpc.log"
o.description = translate("Log output path; default is /var/log/frpc.log.")

o = s:taboption("general", ListValue, "log_level", translate("Log level"))
o:depends("enable_logging", "1")
o:value("trace", translate("Trace"))
o:value("debug", translate("Debug"))
o:value("info", translate("Info"))
o:value("warn", translate("Warn"))
o:value("error", translate("Error"))
o.default = "warn"
o.description = translate("Minimum severity written to the log.")

o = s:taboption("general", Value, "log_max_days", translate("Log max days"))
o:depends("enable_logging", "1")
o.datatype = "uinteger"
o.placeholder = '3'
o.description = translate("Rotate or delete logs after N days; 0 keeps all logs.")

o = s:taboption("general", Value, "disable_log_color", translate("Disable log color"))
o:depends("enable_logging", "1")
o.enabled = "true"
o.disabled = "false"
o.description = translate("Strip ANSI color codes from log output.")

o = s:taboption("advanced", Value, "pool_count", translate("Pool count"),
	translate("Work connection pool size (pre-established connections); 0 disables preallocation."))
o.datatype = "uinteger"
o.defalut = '0'
o.placeholder = '0'

o = s:taboption("advanced", Flag, "tcp_mux", translate("TCP mux"),
	translate("Enable TCP stream multiplexing between frpc and frps"))
o.enabled = "true"
o.disabled = "false"
o.default = o.enabled
o.rmempty = false

o = s:taboption("advanced", Value, "tcp_mux_session_count", translate("TCP mux session count"),
	translate("Number of underlying TCP connections when tcpMux is enabled (e.g. 8 or 16)"))
o.datatype = "uinteger"
o.placeholder = "8"

o = s:taboption("advanced", ListValue, "tcp_mux_link_probe_mode", translate("TCP mux link probe mode"),
	translate("Select how to estimate per-link quality among TCP mux sessions"))
o:value("disabled", translate("Disabled"))
o:value("passive", translate("Passive"))
o:value("active", translate("Active"))
o:value("auto", translate("Auto"))
o.default = "auto"

o = s:taboption("advanced", Value, "tcp_mux_link_probe_interval", translate("TCP mux link probe interval (s)"),
	translate("Probe interval in seconds, 0 means disabled"))
o.datatype = "uinteger"
o.placeholder = "0"

o = s:taboption("advanced", Value, "tcp_mux_link_probe_timeout", translate("TCP mux link probe timeout (s)"),
	translate("Probe timeout in seconds"))
o.datatype = "uinteger"
o.placeholder = "3"

o = s:taboption("advanced", Value, "user", translate("Proxy user"),
	translate("Your proxy name will be changed to {user}.{proxy}"))

o = s:taboption("advanced", Flag, "login_fail_exit", translate("Login fail exit"))
o.enabled = "true"
o.disabled = "false"
o.defalut = o.enabled
o.rmempty = false

o = s:taboption("advanced", ListValue, "protocol", translate("Protocol"),
	translate("Communication protocol used to connect to server, default is tcp"))
o:value("tcp", "TCP")
o:value("kcp", "KCP")
o:value("websocket", "Websocket")
o:value("quic", "quic")
o.default = "tcp"
o.description = translate("Main control/work connection protocol. With multi-port servers, frpc still opens extra ports (tcp/kcp/quic/websocket/wss) if configured.")

o = s:taboption("advanced", Value, "http_proxy", translate("HTTP proxy"),
	translate("Connect frps by http proxy or socks5 proxy, format: [protocol]://[user]:[passwd]@[ip]:[port]"))

o = s:taboption("advanced", Flag, "tls_enable", translate("TLS enable"),
	translate("If true, Frpc will connect Frps by TLS"))
o.enabled = "true"
o.disabled = "false"

o = s:taboption("advanced", Value, "dns_server", translate("DNS server"))
o.datatype = "host"

o = s:taboption("advanced", Value, "heartbeat_interval", translate("Heartbeat interval"))
o.datatype = "uinteger"
o.placeholder = "30"

o = s:taboption("advanced", Value, "heartbeat_timeout", translate("Heartbeat timeout"))
o.datatype = "uinteger"
o.placeholder = "90"

o = s:taboption("advanced", Value, "virtual_net_address", translate("VirtualNet address"),
	translate("Experimental: virtualNet.address (requires exactly one frps server)"))
o.placeholder = "100.86.1.1/24"

o = s:taboption("manage", Value, "admin_addr", translate("Admin addr"))
o.datatype = "host"

o = s:taboption("manage", Value, "admin_port", translate("Admin port"))
o.datatype = "port"

o = s:taboption("manage", Value, "admin_user", translate("Admin user"))

o = s:taboption("manage", Value, "admin_pwd", translate("Admin password"))
o.password = true

return m
