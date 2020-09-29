module:depends("muc");

local jid_resource = require "util.jid".resource;

local prefixes = module:get_option("muc_inject_mentions_prefixes", nil)
local suffixes = module:get_option("muc_inject_mentions_suffixes", nil)
local enabled_rooms = module:get_option("muc_inject_mentions_enabled_rooms", nil)
local disabled_rooms = module:get_option("muc_inject_mentions_disabled_rooms", nil)
local mention_delimiters = module:get_option_set("muc_inject_mentions_mention_delimiters",  {" ", "", "\n"})
local append_mentions = module:get_option("muc_inject_mentions_append_mentions", false)


local reference_xmlns = "urn:xmpp:reference:0"


local function get_client_mentions(stanza)
    local has_mentions = false
    local client_mentions = {}

    for element in stanza:childtags("reference", reference_xmlns) do
        if element.attr.type == "mention" then
            local key = tonumber(element.attr.begin) + 1 -- count starts at 0
            client_mentions[key] = {bare_jid=element.attr.uri, first=element.attr.begin, last=element.attr["end"]}
            has_mentions = true
        end
    end

    return has_mentions, client_mentions
end

local function is_room_eligible(jid)
    if not enabled_rooms and not disabled_rooms then
        return true;
    end

    if enabled_rooms and not disabled_rooms then
        for _, _jid in ipairs(enabled_rooms) do
            if _jid == jid then
                return true
            end
        end
        return false
    end

    if disabled_rooms and not enabled_rooms then
        for _, _jid in ipairs(disabled_rooms) do
            if _jid == jid then
                return false
            end
        end
        return true
    end

    return true
end

local function has_nick_prefix(body, first)
    -- There are no configured prefixes
    if not prefixes or #prefixes < 1 then return false end

    -- Preffix must have a space before it,
    -- be the first character of the body
    -- or be the first character after a new line
    if not mention_delimiters:contains(body:sub(first - 2, first - 2)) then
        return false
    end

    local preffix = body:sub(first - 1, first - 1)
    for _, _preffix in ipairs(prefixes) do
        if preffix == _preffix then
            return true
        end
    end

    return false
end

local function has_nick_suffix(body, last)
    -- There are no configured suffixes
    if not suffixes or #suffixes < 1 then return false end

    -- Suffix must have a space after it,
    -- be the last character of the body
    -- or be the last character before a new line
    if not mention_delimiters:contains(body:sub(last + 2, last + 2)) then
        return false
    end

    local suffix = body:sub(last+1, last+1)
    for _, _suffix in ipairs(suffixes) do
        if suffix == _suffix then
            return true
        end
    end

    return false
end

local function search_mentions(room, body, client_mentions)
    local mentions = {}

    for _, occupant in pairs(room._occupants) do
        local nick = jid_resource(occupant.nick);
        -- Check for multiple mentions to the same nickname in a message
        -- Hey @nick remember to... Ah, also @nick please let me know if...
        local matches = {}
        local _first
        local _last = 0
        while true do
            -- Use plain search as nick could contain
            -- characters used in Lua patterns
            _first, _last = body:find(nick, _last + 1, true)
            if _first == nil then break end
            table.insert(matches, {first=_first, last=_last})
        end

        -- Filter out intentional mentions from unintentional ones
        for _, match in ipairs(matches) do
            local bare_jid = occupant.bare_jid
            local first, last = match.first, match.last
            -- Only append new mentions in case the client already sent some
            if not client_mentions[first] then
                -- Body only contains nickname or is between spaces, new lines or at the end/start of the body
                if mention_delimiters:contains(body:sub(first - 1, first - 1)) and
                    mention_delimiters:contains(body:sub(last + 1, last + 1))
                then
                    mentions[first] = {bare_jid=bare_jid, first=first, last=last}
                else
                    -- Check if occupant is mentioned using affixes
                    local has_preffix = has_nick_prefix(body, first)
                    local has_suffix = has_nick_suffix(body, last)

                    -- @nickname: ...
                    if has_preffix and has_suffix then
                        mentions[first] = {bare_jid=bare_jid, first=first, last=last}

                    -- @nickname ...
                    elseif has_preffix and not has_suffix then
                        if mention_delimiters:contains(body:sub(last + 1, last + 1)) then
                            mentions[first] = {bare_jid=bare_jid, first=first, last=last}
                        end

                    -- nickname: ...
                    elseif not has_preffix and has_suffix then
                        if mention_delimiters:contains(body:sub(first - 1, first - 1)) then
                            mentions[first] = {bare_jid=bare_jid, first=first, last=last}
                        end
                    end
                end
            end
        end
    end

    return mentions
end

local function muc_inject_mentions(event)
    local room, stanza = event.room, event.stanza;
    local body = stanza:get_child("body")

    if not body then return; end

    -- Inject mentions only if the room is configured for them
    if not is_room_eligible(room.jid) then return; end

    -- Only act on messages that do not include mentions
    -- unless configuration states otherwise.
    local has_mentions, client_mentions = get_client_mentions(stanza)
    if has_mentions and not append_mentions then return; end

    local mentions = search_mentions(room, body:get_text(), client_mentions)
    for _, mention in pairs(mentions) do
        -- https://xmpp.org/extensions/xep-0372.html#usecase_mention
        stanza:tag(
            "reference", {
                xmlns=reference_xmlns,
                begin=tostring(mention.first - 1), -- count starts at 0
                ["end"]=tostring(mention.last - 1),
                type="mention",
                uri="xmpp:" .. mention.bare_jid,
            }
        ):up()
    end
end

module:hook("muc-occupant-groupchat", muc_inject_mentions)