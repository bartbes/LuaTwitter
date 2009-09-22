--- LuaTwitter Minefield 1.0.0
local socket = require("socket")
local mime = require("mime")
local url = require("socket.url")
local json = require("json")
local print = print

module("twitter")

local tweetheaders = [[
POST %s HTTP/1.0
Host: twitter.com
Authorization: Basic %s
Content-type: application/x-www-form-urlencoded
Content-length: %d

%s
]]

--- Updates a user's status on Twitter.
-- @param message The message to tweet.
-- @param user The user to tweet as -OR- the mime64 encoded auth string.
-- @param pass If specified it will use user:pass authentication.
function updatestatus(message, user, pass)
    if not message then return false end
    local auth
    if not pass then
        auth = user
    else
	    auth = mime.b64(user .. ":" .. pass)
    end
	local postdata = "status=" .. url.escape(message)
	local data = tweetheaders:format("/statuses/update.json", auth, #postdata, postdata)
	local sock = socket.tcp()
	sock:settimeout(15)
	sock:connect("twitter.com", 80)
	sock:send(data)
	local response = sock:receive("*a")
	sock:close()
	response = response:match(".-\r\n\r\n(.*)")
	response = json.decode(response)
	--print("Tweeted: " .. response.text)
	return true, response
end
