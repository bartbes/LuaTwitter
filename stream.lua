#!/usr/bin/env lua
local json = require("json")
local socket = require("socket")
local mime = require("mime")
local tcp = socket.tcp()
local sf = string.format

if not arg[1] and not arg[2] then
    print("You need to specify a valid user name and password!")
    print("Example: "..arg[0].." thelinx secret")
    return
end

tcp:settimeout(15)
tcp:connect("stream.twitter.com", 80)
tcp:send(sf([[
GET /1/statuses/sample.json HTTP/1.0
Host: stream.twitter.com
Authorization: Basic %s

]], mime.b64(arg[1]..":"..arg[2])))

while true do
    local tw = tcp:receive("*l")
    if not tw then return end
    if tw:len() > 50 then
        local t = json.decode(tw)
        if t.user and t.text then
            print(sf("<%s> %s", t.user.screen_name, t.text))
        end
    end
end
