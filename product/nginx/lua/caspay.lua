#!/usr/bin/lua
--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2017-11-01
-- Time: 17:24
-- online-agent: caspay.sandpay.com.cn

--代理地址及key值定义
local CasPayProxy_a = "172.17.2.5:8082"
local CasPayProxy_b = "172.17.2.7:8082"
local CasPayProxy_a_key = "SAND_GRAY_CHANNEL_TOPIC_AGENT-CLIENT01"
local CasPayProxy_b_key = "SAND_GRAY_CHANNEL_TOPIC_AGENT-CLIENT02"

--redis地址、端口
local redis_ip = "172.17.0.11"
local redis_port = 6380

--导入模块
local redis = require("resty.redis")
local json = require("json.json")

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
    ngx.exec("@CasPayProxy")
    return close_redis(red)
end

--获取数据
local resp_a, err = red:get(CasPayProxy_a_key)
if resp_a == ngx.null then
    ngx.exec("@CasPayProxy")
    return close_redis(red)
else
    respStrA = json.decode(resp_a)
    grayTagA = respStrA.grayTag
    sysAddrA = respStrA.sysAddr
    --ngx.say(grayTag ,'--', sysAddr)
end

local resp_b, err = red:get(CasPayProxy_b_key)
if resp_b == ngx.null then
    ngx.exec("@CasPayProxy")
    return close_redis(red)
else
    respStrB = json.decode(resp_b)
    grayTagB = respStrB.grayTag
    sysAddrB = respStrB.sysAddr
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
if grayTagA ~= 'gray' and grayTagB ~= 'gray' then
    ngx.exec('@CasPayProxy')
end

if grayTagA == 'gray' and grayTagB == 'gray' and cookieName ~= 'gray' then
    ngx.log('not found:', cookieName)
    return
end

if grayTagA == 'gray' then
    if cookieName == 'gray' then
        if sysAddrA == CasPayProxy_a then
            ngx.exec('@CasPayProxy_a')
        end
    else
        ngx.exec('@CasPayProxy_b')
    end
end

if grayTagB == 'gray' then
    if cookieName == 'gray' then
        if sysAddrB == CasPayProxy_b then
            ngx.exec('@CasPayProxy_b')
        end
    else
        ngx.exec('@CasPayProxy_a')
    end
end

-- redis连接处理
close_redis(red)