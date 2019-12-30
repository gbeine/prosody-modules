local json = require "util.json";
local array = require "util.array";
local get_stats = require "core.statsmanager".get_stats;
local os_time = os.time;

module:depends("http");
module:depends("lastlog");

local expose_posts = module:get_option_boolean("nodeinfo2_expose_posts", true);
if expose_posts then
	module:depends("measure_message_e2ee");
end

local main_store = module:open_store();
local lastlog_store = module:open_store("lastlog");

local total_users = 0;
local half_year_users = 0;
local month_users = 0;
local week_users = 0;
for user in require "core.usermanager".users(module.host) do -- TODO refresh at some interval?
	total_users = total_users + 1;
	local lastlog = lastlog_store:get(user);
	if lastlog and lastlog.timestamp then
		local delta = os_time() - lastlog.timestamp;
		if delta < 6 * 30 * 24 * 60 * 60 then
			half_year_users = half_year_users + 1;
		end
		if delta < 30 * 24 * 60 * 60 then
			month_users = month_users + 1;
		end
		if delta < 7 * 24 * 60 * 60 then
			week_users = week_users + 1;
		end
	end
end

-- Remove the properties if we couldn’t find a single active user.  It most likely means mod_lastlog isn’t in use.
if half_year_users == 0 and month_users == 0 and week_users == 0 then
	half_year_users = nil;
	month_users = nil;
	week_users = nil;
end

local data;
if expose_posts then
	data = main_store:get("nodeinfo2") or { message_count = 0 };
end

module:provides("http", {
	default_path = "/.well-known/x-nodeinfo2";
	route = {
		GET = function (event)
			local usage = {
				users = {
					total = total_users;
					activeHalfyear = half_year_users;
					activeMonth = month_users;
					activeWeek = week_users;
				};
			};

			if expose_posts then
				local stats, changed_only, extras = get_stats();
				for stat, _ in pairs(stats) do
					if stat == "/"..module.host.."/mod_measure_message_e2ee/message:rate" then
						local new_message_count = extras[stat].total;
						if new_message_count ~= data.message_count then
							data = { message_count = new_message_count };
							main_store:set("nodeinfo2", data);
						end
					end
				end
				usage.localPosts = data.message_count;
				-- TODO: also count PubSub replies here.
				usage.localComments = 0;
			end

			event.response.headers.content_type = "application/json";
			return json.encode({
				version = "1.0";
				server = {
					baseUrl = module:http_url("","/");
					name = module.host;
					software = "Prosody";
					version = prosody.version;
				};
				--[[ TODO re-use data from mod_server_contact_info ?
				organization = {
					name = "";
					contact = "";
					account = "";
				};
				--]]
				protocols = array {
					"xmpp",
				};
				--[[ TODO would be cool to identify local transports
				services = {
					inbound = array {
						"irc";
					};
					outbound = array {
					};
				};
				--]]
				openRegistrations = module:get_option_boolean("allow_registration", false);
				usage = usage;
			});
		end;
	}
});
