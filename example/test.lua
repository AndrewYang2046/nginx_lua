--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2017-11-02
-- Time: 15:48
-- To change this template use File | Settings | File Templates.
--
local redis_ip = '172.28.250.2'
local redis_port = 6379
local redisLib = require "resty.redis"
local cookieLib = require "resty.cookie"
local json = require("json")

--redis实例化
local redis = redisLib:new()
if not redis then
    ngx.log(ngx.ERR, err)
    ngx.exec("@defaultProxy")
end

--cookie实例化
local cookie, err = cookieLib:new()
if not cookie then
    ngx.log(ngx.ERR, err)
    ngx.exec("@defaultProxy")
end

--[[
-- set cookie(模拟测试)
local ok, err = cookie:set({
    key = "releaseTag", value = "gray",
})
if not ok then
    ngx.log(ngx.ERR, err)
    ngx.exec("@defaultProxy")
end
]]

-- get cookie
local cookie_tag, err = cookie:get("releaseTag")
if not cookie_tag then
    ngx.log(ngx.ERR, err)
    ngx.exec("@defaultProxy")
end

if cookie_tag ~= 'gray' then
    ngx.log(ngx.ERR, err)
    ngx.exec("@defaultProxy")
end

--连接redis
redis:set_timeout(1000)
local ok, err = redis:connect(redis_ip, redis_port)
if not ok then
    ngx.log("failed to connect:", err)
    ngx.exec("@defaultProxy")
end

--获取数据
-- eg: {'tag1':'2','tag2':'1','tag3':'0'}
local msg, err = redis:get(msg)
if not msg then
    ngx.log("failed to get uid: ", err)
    ngx.exec("@defaultPorxy")
end

if msg == ngx.null then
    ngx.log("data not found.")
    ngx.exec("@defaultProxy")
end

-- put it into the connection pool of size 100,
-- with 10 seconds max idle time
local ok, err = redis:set_keepalive(10000, 100)
if not ok then
    ngx.say("failed to set keepalive: ", err)
    return
end

proxyConfigData = json.decode(msg)
tag = proxyConfigData.tag

-- 解析规则处理
-- 根据规则里配置的类型和用户标签做匹配, 分流到相应的服务器上
-- 这里是可以按照用户标签维度支持比较灵活的配置分流规则, 如果业务逻辑简单的话也可以简化
proxy = "@defaultProxy"
for k_tag, v_tag in pairs(tagsData) do
        if k_tag == tag then
                for k_proxy, v_proxy in pairs(proxyConfigData.proxy) do
                        if v_tag == k_proxy then
                                proxy = v_proxy
                                break
                        end
                end
        end
end

ngx.exec(proxy)