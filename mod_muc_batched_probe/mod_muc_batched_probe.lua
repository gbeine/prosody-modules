-- This module allows you to probe the MUC presences for multiple occupants.
-- Copyright (C) 2020 JC Brand

local st = require "util.stanza";
local mod_muc = module:depends"muc";
local get_room_from_jid = rawget(mod_muc, "get_room_from_jid") or
	function (jid)
		local rooms = rawget(mod_muc, "rooms");
		return rooms[jid];
	end

module:log("debug", "Module loaded");


local function respondToBatchedProbe(event)
	local stanza = event.stanza;
	if stanza.attr.type ~= "get" then
		return;
	end
	local query = stanza:get_child("query", "http://jabber.org/protocol/muc#user");
	if not query then
		return;
	end;

	local room = get_room_from_jid(stanza.attr.to);
	for item in query:children() do
		local probed_jid = item.attr.jid;
		room:respond_to_probe(stanza.attr.from, probed_jid);
	end
	event.origin.send(st.reply(stanza));
	return true;
end


module:hook("iq/bare", respondToBatchedProbe, 1);
