module:set_global();

local loggingmanager = require "core.loggingmanager";
local format = require "util.format".format;
local pposix = require "util.pposix";
local rb = require "util.ringbuffer";

local default_timestamp = "%b %d %H:%M:%S ";
local max_chunk_size = module:get_option_number("log_ringbuffer_chunk_size", 16384);

local os_date = os.date;

local default_filename_template = "ringbuffer-logs-{pid}-{count}.log";
local render_filename = require "util.interpolation".new("%b{}", function (s) return s; end, {
	yyyymmdd = function (t)
		return os_date("%Y%m%d", t);
	end;
	hhmmss = function (t)
		return os_date("%H%M%S", t);
	end;
});

local dump_count = 0;

local function dump_buffer(buffer, filename)
	dump_count = dump_count + 1;
	local f, err = io.open(filename, "a+");
	if not f then
		module:log("error", "Unable to open output file: %s", err);
		return;
	end
	local bytes_remaining = buffer:length();
	f:write(("-- Dumping %d bytes at %s --\n"):format(bytes_remaining, os_date(default_timestamp)));
	while bytes_remaining > 0 do
		local chunk_size = math.min(bytes_remaining, max_chunk_size);
		local chunk = buffer:read(chunk_size);
		if not chunk then
			f:write("-- Dump aborted due to error --\n\n");
			f:close();
			return;
		end
		f:write(chunk);
		bytes_remaining = bytes_remaining - chunk_size;
	end
	f:write("-- End of dump --\n\n");
	f:close();
end

local function get_filename(filename_template)
	filename_template = filename_template or default_filename_template;
	return render_filename(filename_template, {
		paths = prosody.paths;
		pid = pposix.getpid();
		count = dump_count;
		time = os.time();
	});
end

local function ringbuffer_log_sink_maker(sink_config)
	local buffer = rb.new(sink_config.size or 100*1024);

	local timestamps = sink_config.timestamps;

	if timestamps == true or timestamps == nil then
		timestamps = default_timestamp; -- Default format
	elseif timestamps then
		timestamps = timestamps .. " ";
	end

	local function dump()
		dump_buffer(buffer, get_filename(sink_config.filename));
	end

	if sink_config.signal then
		require "util.signal".signal(sink_config.signal, dump);
	elseif sink_config.event then
		module:hook_global(sink_config.global_event, dump);
	end

	return function (name, level, message, ...)
		buffer:write(format("%s%s\t%s\t%s\n", timestamps and os_date(timestamps) or "", name, level, format(message, ...)));
	end;
end

loggingmanager.register_sink_type("ringbuffer", ringbuffer_log_sink_maker);
