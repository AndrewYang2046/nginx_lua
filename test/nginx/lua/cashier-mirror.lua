#!/usr/bin/lua
--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2018-09-10
-- Time: 18:04
-- To change this template use File | Settings | File Templates.
--

--代理地址及key值定义
local CashierProxy_Mirror_key = "NGINX_1B1_COPY_REDIS_KEY"

--redis地址、端口
local redis_ip = "172.28.250.2"
local redis_port = 6379

--导入模块
local redis = require("resty.redis")
local json = require("json.json")

--创建实例
local red = redis:new()
red:set_timeout(500000)  --毫秒

--建立连接
local ok, err = red:connect(redis_ip, redis_port)
if not ok then
    ngx.exec("@CashierProxy")
end

--获取数据
local resp, err = red:get(CashierProxy_Mirror_key)
if resp == ngx.null then
    ngx.exec("@CashierProxy")
else
    respStr = json.decode(resp)
    respStatus = respStr.status
    --ngx.say(respStatus)
end

--连接池
local max_idle_timeout = 1000000 --最大空闲超时时间
local pool_size = 100  --连接池大小
local ok, err = red:set_keepalive(max_idle_timeout, pool_size)
if not ok then
    ngx.log(ngx.ERR, "set keepalive error: ", err)
    return
end

--判断是否进入mirror
if respStatus == '0' then
    ngx.exec("@CashierProxyMirror")
else
    ngx.exec("@CashierProxy")
end



