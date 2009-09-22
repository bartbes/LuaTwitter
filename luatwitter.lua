--- LuaTwitter Minefield 1.0.0
local socket = require("socket")
local mime = require("mime")
local url = require("socket.url")
local json = require("json")
local print = print

module("twitter")

local request = [[
POST %s HTTP/1.0
Host: twitter.com
Authorization: Basic %s
Content-type: application/x-www-form-urlencoded
Content-length: %d

%s
]]

function updatestatus(message, user, pass)
	local auth = mime.b64(user .. ":" .. pass)
	local postdata = "status=" .. url.escape(message)
	local data = request:format("/statuses/update.json", auth, #postdata, postdata)
	local sock = socket.tcp()
	sock:settimeout(15)
	sock:connect("twitter.com", 80)
	sock:send(data)
	local response = sock:receive("*a")
	sock:close()
	response = response:match(".-\r\n\r\n(.*)")
	response = json.decode(response)
	print("Tweeted: " .. response.text)
end
