#!/usr/bin/lua
--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2017-11-01
-- Time: 17:24
-- To change this template use File | Settings | File Templates.
--
local redis = require("resty.redis")
local json = require("json.json")

local redis_ip = "172.28.250.2"
local redis_port = 6379
local proxy_a = "172.28.250.2:8083"
local proxy_b = "172.28.247.111:8083"

--创建实例
local red = redis:new()
red:set_timeout(1000)

local function close_redis(red)
    if not red then
        return
    end
    --释放连接
    local pool_max_idle_time = 10000 --毫秒
    local pool_size = 100 --连接池大小
    local ok, err = red:set_keepalive(pool_max_idle_time, pool_size)
    if not ok then
        ngx.log("set keepalive error: ", err)
    end
end

--建立连接
local ok, err = red:connect(redis_ip, redis_port)
if not ok then
    ngx.exec("@defaultProxy")
    --ngx.log("connect redis error: ", err)
    return close_redis(red)
end

--获取数据,解码数据
local resp, err = red:get("msg")
if resp == ngx.null then
    ngx.exec("@defaultProxy")
    return close_redis(red)
else
    respStr = json.decode(resp)
    grayTag = respStr.grayTag
    sysAddr = respStr.sysAddr
    --ngx.say(grayTag ,'--', sysAddr)
end

--获取测试headers
--[[
ngx.say(ngx.req.get_headers()["cookie"], '<br/>')
for k,v in pairs(ngx.req.get_headers()) do
    ngx.say(k..":"..v, '<br/>')
end
]]

--获取cookie
local cookieName = ngx.var.cookie_releaseTag

--根据cookieName, grayTag, sysAddr值进行分发规则处理
if not grayTag then
    ngx.exec("@defaultProxy")
elseif not sysAddr then
    ngx.exec("@defaultProxy")
end

if grayTag == ngx.null then
    ngx.exec("@defaultProxy")
elseif sysAddr == ngx.null then
    ngx.exec("@defaultProxy")
end

if cookieName == 'gray' then
    if grayTag == "gray" then
        if sysAddr == proxy_a then
            ngx.exec("@proxy_a")
        elseif sysAddr == proxy_b then
            ngx.exec("@proxy_b")
        else
            ngx.exec("@defaultProxy")
        end
    else
        ngx.exec("@defaultProxy")
    end
else
    ngx.exec("@defaultProxy")
end

-- redis连接处理
close_redis(red)