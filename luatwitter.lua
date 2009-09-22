--- LuaTwitter Minefield 1.0.0
local socket = require("socket")
local mime = require("mime")
local url = require("socket.url")
local json = require("json")

module("twitter")

local tweetheaders = [[
POST %s HTTP/1.0
Host: twitter.com
Authorization: Basic %s
Content-type: application/x-www-form-urlencoded
Content-length: %d

%s
]]

--- Does requests for a function [INTERNAL]
-- Prevents a lot of code duplication
-- @param data The data to send to twitter
local function dorequest(data)
	local sock = socket.tcp()
	sock:settimeout(15)
	if not sock:connect("twitter.com", 80) then
		return false, "Could not connect"
	end
	if not sock:send(data) then
		return false, "Could not send data"
	end
	local response = sock:receive("*a")
	if not response then
		return falce, "Could not receive data"
	end
	sock:close()
	return true, response
end

--- Updates a user's status on Twitter.
-- @param message The message to tweet.
-- @param user The user to tweet as -OR- the mime64 encoded auth string.
-- @param pass If specified it will use user:pass authentication.
function updatestatus(message, user, pass)
    if not message then return false, "No message passed" end
    if not user then return false, "No authentication passed" end
    local auth = pass and mime.b64(user .. ":" .. pass) or user
	local postdata = "status=" .. url.escape(message)
	local data = tweetheaders:format("/statuses/update.json", auth, #postdata, postdata)
	local success, response = dorequest(data)
	if not success then return false, response end
	response = response:match(".-\r\n\r\n(.*)")
	response = json.decode(response)
	return true, response
end
