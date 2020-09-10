module:depends("http");
local http_files = module:depends("http_files");

local app_config = module:get_option("site_apps", {
	{
		name = "Conversations";
		text = [[Conversations is a Jabber/XMPP client for Android 4.0+ smartphones that has been optimized to provide a unique mobile experience.]];
		image = "assets/logos/conversations.svg";
		link = "https://play.google.com/store/apps/details?id=eu.siacs.conversations";
		platforms = { "Android" };
		supports_preauth_uri = true;
		magic_link_format = "{app.link!}&referrer={invite.uri}";
		download = {
			buttons = {
				{
					image = "https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png";
					url = "https://play.google.com/store/apps/details?id=eu.siacs.conversations";
				};
			};
		};
	};
	{
		name  = "yaxim";
		text  = [[A lean Jabber/XMPP client for Android. It aims at usability, low overhead and security, and works on low-end Android devices starting with Android 4.0.]];
		image = "assets/logos/yaxim.svg";
		link  = "https://play.google.com/store/apps/details?id=org.yaxim.androidclient";
		platforms = { "Android" };
		supports_preauth_uri = true;
		magic_link_format = "{app.link!}&referrer={invite.uri}";
		download = {
			buttons = {
				{
					image = "https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png";
					url = "https://play.google.com/store/apps/details?id=org.yaxim.androidclient";
				};
			};
		};
	};
	{
		name  = "Siskin IM";
		text  = [[A lightweight and powerful XMPP client for iPhone and iPad. It provides an easy way to talk and share moments with your friends.]];
		image = "assets/logos/siskin-im.png";
		link  = "https://apps.apple.com/us/app/siskin-im/id1153516838";
		platforms = { "iOS" };
		supports_preauth_uri = true;
		download = {
			buttons = {
				{
					image = "https://linkmaker.itunes.apple.com/en-us/badge-lrg.svg?releaseDate=2017-05-31&kind=iossoftware&bubble=ios_apps";
					url = "https://apps.apple.com/us/app/siskin-im/id1153516838";
					target = "_blank";
				};
			};
		};
	};
	{
		name  = "Beagle IM";
		text  = [[Beagle IM by Tigase, Inc. is a lightweight and powerful XMPP client for macOS.]];
		image = "assets/logos/beagle-im.png";
		link  = "https://apps.apple.com/us/app/beagle-im/id1445349494";
		platforms = { "macOS" };
		download = {
			buttons = {
				{
					text = "Download from Mac App Store";
					url = "https://apps.apple.com/us/app/beagle-im/id1445349494";
					target = "_blank";
				};
			};
		};
	};
	{
		name  = "Dino";
		text  = [[A modern open-source chat client for the desktop. It focuses on providing a clean and reliable Jabber/XMPP experience while having your privacy in mind.]];
		image = "assets/logos/dino.svg";
		link  = "https://dino.im/";
		platforms = { "Linux" };
		download = {
			text = "Click the button to open the Dino website where you can download and install it on your PC.";
			buttons = {
				{ text = "Download Dino for Linux", url = "https://dino.im/#download", target="_blank" };
			};
		};
	};
	{
		name  = "Gajim";
		text  = [[A fully-featured desktop chat client for Windows and Linux.]];
		image = "assets/logos/gajim.svg";
		link  = "https://gajim.org/";
		platforms = { "Windows", "Linux" };
		download = {
			buttons = {
				{ 
					text = "Download Gajim";
					url = "https://gajim.org/download/";
					target = "_blank";
				};
			};
		};
	};
});

local base_url = module.http_url and module:http_url();
local function relurl(s)
	if s:match("^%w+://") then
		return s;
	end
	return base_url.."/"..s;
end

local site_apps = module:shared("apps");

for _, app_info in ipairs(app_config) do
	local app_id = app_info.id or app_info.name:gsub("%W+", "-"):lower();
	app_info.id = app_id;
	app_info.image = relurl(app_info.image);
	site_apps[app_id] = app_info;
	table.insert(site_apps, app_info);
end

local mime_map = {
	png = "image/png";
	svg = "image/svg+xml";
};

module:provides("http", {
	route = {
		["GET /assets/*"] = http_files and http_files.serve({
			path = module:get_directory().."/assets";
			mime_map = mime_map;
		});
	};
});
