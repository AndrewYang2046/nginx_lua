--
-- Created by IntelliJ IDEA.
-- User: yang.hong
-- Date: 2018-07-05
-- Time: 11:05
-- To change this template use File | Settings | File Templates.
--

local redis_ip = '172.28.250.9'
local redis_port = 7379

--导入模块
local redis = require("resty.redis")

--连接redis
local red = redis:new()
local function redis_connect()
    red:set_timeout(1000)
    local ok, err = red:connect(redis_ip, redis_port)
    if not ok then
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
end

local function redis_close(red)
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

--检测是否被forbidden
local function check1()
    local time = os.time()
    local res, err = red:get("block:"..ngx.var.remote_addr)
    if not res then
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    if type(res) == "string" then
        if tonumber(res) >= tonumber(time) then
            ngx.exit(ngx.HTTP_FORBIDDEN)
        end
    end
end

--检测是否超过访问频率
local function check2()
    local time = os.time()
    local res, err = red:get("user："..ngx.var.remote_addr..':'..time)
    if not res then
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    if type(res) == "string" then
        if tonumber(res) >= 10 then
            red:del("block:"..self.ip)
            red:set("block:"..self.ip, tonumber(time)+5*60)
            ngx.exit(ngx.HTTP_FORBIDDEN)
        end
    end
end

--访问时间自增长
local function add()
    local time = os.time()
    ok, err = red:incr("user:"..ngx.var.remote_addr..":"..time)
    if not ok then
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
end

