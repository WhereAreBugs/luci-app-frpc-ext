-- Copyright 2019 Xingwang Liao <kuoruan@gmail.com>
-- Licensed to the public under the MIT License.

local dsp = require "luci.dispatcher"

local m, s, o

m = Map("frpc_ext", "%s - %s" % { translate("Frpc"), translate("Frps Servers") })

s = m:section(TypedSection, "server")
s.anonymous = true
s.addremove = true
s.sortable = true
s.template = "cbi/tblsection"
s.extedit = dsp.build_url("admin/services/frpc-ext/servers/%s")
function s.create(...)
	local sid = TypedSection.create(...)
	if sid then
		m.uci:save("frpc_ext")
		luci.http.redirect(s.extedit % sid)
		return
	end
end

o = s:option(DummyValue, "alias", translate("Alias"))
o.cfgvalue = function (...)
	return Value.cfgvalue(...) or translate("None")
end

o = s:option(DummyValue, "server_addr", translate("Server Addr"))
o.cfgvalue = function (...)
	return Value.cfgvalue(...) or "?"
end

o = s:option(DummyValue, "server_port", translate("Server Port"))
o.cfgvalue = function (...)
	return Value.cfgvalue(...) or "?"
end

return m
