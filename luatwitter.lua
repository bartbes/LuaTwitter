--- LuaTwitter Minefield 1.0.0
local socket = require("socket")
local mime = require("mime")
local url = require("socket.url")
local json = require("json")

module("twitter")

local post_authorized_headers = [[
POST %s HTTP/1.0
Host: twitter.com
Authorization: Basic %s
Content-type: application/x-www-form-urlencoded
Content-length: %d

%s
]]

local post_unauthorized_headers = [[
POST %s HTTP/1.0
Host: twitter.com
Content-type: application/x-www-form-urlencoded
Content-length: %d

%s
]]

local get_authorized_headers = [[
GET %s HTTP/1.0
Host: twitter.com
Authorization: Basic %s

]]

local get_unauthorized_headers = [[
GET %s HTTP/1.0
Host: twitter.com

]]

local get_unauthorized_headers_s = [[
GET %s HTTP/1.0
Host: search.twitter.com

]]

--- (internal) Does requests for a function.
-- Prevents a lot of code duplication
-- @param data The data to send to twitter.
-- @return boolean Success or not.
-- @return unsigned If fail, an error message. If success, the response from twitter.
local function dorequest(data)
	local sock = socket.tcp()
	sock:settimeout(15)
	local host = data:match("Host: ([a-z%.]+)")
	if not sock:connect(host, 80) then
		return false, "Could not connect"
	end
	if not sock:send(data) then
		return false, "Could not send data"
	end
	local response = sock:receive("*a")
	if not response then
		return false, "Could not receive data"
	end
	sock:close()
	return true, response
end

--- Updates a user's status on Twitter.
-- If pass is omitted it uses user as the auth string.
-- @param message The message to tweet.
-- @param user The user to tweet as -OR- the mime64 encoded auth string.
-- @param pass The password.
-- @return boolean Success or not.
-- @return unsigned If fail, an error message. If success, the response from twitter.
function updateStatus(message, user, pass)
    if not message then return false, "No message passed" end
    if not user then return false, "No authentication passed" end
    local auth = pass and mime.b64(user .. ":" .. pass) or user
	local postdata = "status=" .. url.escape(message)
	local data = post_authorized_headers:format("/statuses/update.json", auth, #postdata, postdata)
	local success, response = dorequest(data)
	if not success then return false, response end
	response = response:match(".-\r\n\r\n(.*)")
	response = json.decode(response)
	return true, response
end

--- Fetches a status by id.
-- If pass is omitted it uses user as the auth string.
-- If user is omitted it doesn't authenticate, this prevents you
-- from reading hidden tweets.
-- @param id The status id
-- @param user Your used id or an auth string
-- @param pass Your password
-- @return boolean Success or not.
-- @return unsigned If fail, an error message. If success, the response from twitter.
function fetchStatus(id, user, pass)
	if not id then return false, "No message id passed" end
	local data
	if not user then
		data = get_unauthorized_headers:format("/statuses/show/" .. id .. ".json")
	else
		local auth = pass and mime.b64(user .. ":" .. pass) or user
		data = get_authorized_headers:format("/statuses/show/" .. id .. ".json", auth)
	end
	local success, response = dorequest(data)
	if not success then return false, response end
	response = response:match(".-\r\n\r\n(.*)")
	response = json.decode(response)
	return true, response
end

--- Fetches current trends.
-- @param cat The category of trends. This can be current, daily, weekly, or empty (to get the current trends).
-- @return boolean Success or not
-- @return unsigned If fail, an error message. If success, the response from twitter.
function fetchTrends(cat)
	local cat = cat or ""
	if cat:len() > 0 then cat = "/"..cat end
	local data = get_unauthorized_headers_s:format("/trends" .. cat .. ".json")
    local success, response = dorequest(data)
    if not success then return false, response end
    response = response:match(".-\r\n\r\n(.*)")
    response = json.decode(response)
    return true, response
end

--- Gets the last 20 posts on the public timeline.
-- @return boolean Success or not
-- @return unsigned If fail, an error message. If success, the response from twitter
function publicTimeline()
	local data = get_unauthorized_headers:format("/statuses/public_timeline.json")
	local success, response = dorequest(data)
	if not success then return false, response end
	response = response:match(".-\r\n\r\n(.*)")
	response = json.decode(response)
	return true, response
end


--- Gets the friends timeline, your messages and your friends'
-- The last 4 parameters are optional, and can be used to limit the output
-- @param user Your username
-- @param pass Your password
-- @param since_id Only messages after this id
-- @param max_id Only messages until this id
-- @param count Return the last count messages
-- @param page Return page pages
-- @return boolean Success or not.
-- @return unsigned If fail, an error message. If success, the response from twitter.
function friendsTimeline(user, pass, since_id, max_id, count, page)
	if not user then return false, "No authentication data passed" end
	local auth = pass and mime.b64(user .. ":" .. pass) or user
	local getdata = ""
	if since_id then
		if getdata:len() > 0 then getdata = getdata .. "&" end
		getdata = getdata .. "since_id=" .. since_id
	end
	if max_id then
		if getdata:len() > 0 then getdata = getdata .. "&" end
		getdata = getdata .. "max_id=" .. max_id
	end
	if count then
		if getdata:len() > 0 then getdata = getdata .. "&" end
		getdata = getdata .. "count=" .. count
	end
	if page then
		if getdata:len() > 0 then getdata = getdata .. "&" end
		getdata = getdata .. "page=" .. page
	end
	if getdata:len() > 0 then getdata = "?" .. getdata end
	local data = get_authorized_headers:format("/statuses/friends_timeline.json" .. getdata, auth)
	local success, response = dorequest(data)
	if not success then return false, response end
	response = response:match(".-\r\n\r\n(.*)")
	response = json.decode(response)
	return true, response
end

--- Gets the last tweets mentioning you
-- The last 4 parameters are optional, and can be used to limit the output
-- @param user Your username
-- @param pass Your password
-- @param since_id Only messages after this id
-- @param max_id Only messages until this id
-- @param count Return the last count messages
-- @param page Return page pages
-- @return boolean Success or not.
-- @return unsigned If fail, an error message. If success, the response from twitter.
function fetchMentions(user, pass, since_id, max_id, count, page)
	if not user then return false, "No authentication data passed" end
	local auth = pass and mime.b64(user .. ":" .. pass) or user
	local getdata = ""
	if since_id then
		if getdata:len() > 0 then getdata = getdata .. "&" end
		getdata = getdata .. "since_id=" .. since_id
	end
	if max_id then
		if getdata:len() > 0 then getdata = getdata .. "&" end
		getdata = getdata .. "max_id=" .. max_id
	end
	if count then
		if getdata:len() > 0 then getdata = getdata .. "&" end
		getdata = getdata .. "count=" .. count
	end
	if page then
		if getdata:len() > 0 then getdata = getdata .. "&" end
		getdata = getdata .. "page=" .. page
	end
	if getdata:len() > 0 then getdata = "?" .. getdata end
	local data = get_authorized_headers:format("/statuses/mentions.json" .. getdata, auth)
	local success, response = dorequest(data)
	if not success then return false, response end
	response = response:match(".-\r\n\r\n(.*)")
	response = json.decode(response)
	return true, response
end

--- Gets user information
-- @param id A screen name or user id
-- @return boolean Success or not
-- @return unsigned If fail, an error message. If success, the response from twitter
function showUser(id)
	if not id then
		return false, "No search information provided"
	end
	local data = get_unauthorized_headers:format("/users/show/" .. id .. ".json")
	local success, response = dorequest(data)
	if not success then return false, response end
	response = response:match(".-\r\n\r\n(.*)")
	response = json.decode(response)
	return true, response
end

--- Gets the followers from a user
-- @param id A screen name or user id
-- @return boolean Success or not
-- @return unsigned If fail, an error message. If success, the response from twitter
function getFollowers(id)
    if not id then
		return false, "No search information provided"
	end
	local data = get_unauthorized_headers:format("/statuses/followers/" .. id .. ".json")
	local success, response = dorequest(data)
	if not success then return false, response end
	response = response:match(".-\r\n\r\n(.*)")
	response = json.decode(response)
	return true, response
end
