local st = require "util.stanza";
local admins = module:get_option_inherited_set("admins");
local host = module.host;

module:depends("spam_reporting")

module:hook("spam_reporting/spam-report", function(event)
	for admin_jid in admins
		do
			module:send(st.message({from=host,
			type="chat",to=admin_jid},
			event.stanza.attr.from.." reported "..event.jid.." as spammer: "..event.reason));
		end
end)
