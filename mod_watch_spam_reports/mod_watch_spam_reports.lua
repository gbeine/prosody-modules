local jid = require "util.jid";
local st = require "util.stanza";
local admins = module:get_option_inherited_set("admins");
local host = module.host;

module:depends("spam_reporting")

module:hook("spam_reporting/spam-report", function(event)
	local report = reporter_bare_jid.." reported "..event.jid.." as spammer: "..event.reason
	local reporter_bare_jid = jid.bare(event.stanza.attr.from)
	for admin_jid in admins
		do
			module:send(st.message({from=host,
			type="chat",to=admin_jid},
                       report));
		end
end)
