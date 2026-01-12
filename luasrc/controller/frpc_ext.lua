-- Copyright 2019 Xingwang Liao <kuoruan@gmail.com>
-- Licensed to the public under the MIT License.

local http = require "luci.http"
local uci = require "luci.model.uci".cursor()
local sys = require "luci.sys"

module("luci.controller.frpc_ext", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/frpc_ext") then
		return
	end

	local page = entry({"admin", "services", "frpc-ext"},
		firstchild(), _("Frpc (ext)"))
	page.dependent = false
	page.i18n = "frpc-ext"

	entry({"admin", "services", "frpc-ext", "common"},
		cbi("frpc_ext/common"), _("Settings"), 1)

	entry({"admin", "services", "frpc-ext", "rules"},
		arcombine(cbi("frpc_ext/rules"), cbi("frpc_ext/rule-detail")),
		_("Rules"), 2).leaf = true

	entry({"admin", "services", "frpc-ext", "servers"},
		arcombine(cbi("frpc_ext/servers"), cbi("frpc_ext/server-detail")),
		_("Servers"), 3).leaf = true

	entry({"admin", "services", "frpc-ext", "status"}, call("action_status"))
end


function action_status()
	local running = false

	local client = uci:get("frpc_ext", "main", "client_file")
	if client and client ~= "" then
		local file_name = client:match(".*/([^/]+)$") or ""
		if file_name ~= "" then
			running = sys.call("pidof %s >/dev/null" % file_name) == 0
		end
	end

	http.prepare_content("application/json")
	http.write_json({
		running = running
	})
end
