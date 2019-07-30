local decode = require("luwee.decode")

local server_address =""
local server_port = 0
local server_password = ""

local args = {"password="..server_password, "compression=off"}

local socket = require("socket")
local ssl = require("ssl")

-- TLS/SSL client parameters (omitted)
local params = {
	mode = "client",
	protocol = "any",
}

local conn, err = socket.tcp()
if not conn then error(err) end
local success, err = conn:connect(server_address, server_port)
if not success then error(err) end

-- TLS/SSL initialization
conn = ssl.wrap(conn, params)
if not conn then error(err) end
conn:dohandshake()
for i,cert in ipairs(conn:getpeerchain()) do
--	print("sha1:", cert:digest())
--	print("issuer:", cert:issuer())
end

conn:send("init "..table.concat(args,",").."\n")
-- no return data ?

--conn:send("info version\n")
--local len = decode.length(conn:receive(4)) - 4
--local answer = conn:receive(len)
--decode.message(answer)

--conn:send("ping 17\n")
--local len = decode.length(conn:receive(4)) - 4
--local answer = conn:receive(len)
--decode.message(answer)

--conn:send("infolist buffer\n")
--local len = decode.length(conn:receive(4)) - 4
--local answer = conn:receive(len)
--decode.message(answer)

conn:send("test\n")
local len = decode.length(conn:receive(4)) - 4
local answer = conn:receive(len)
decode.message(answer)

--conn:send("nicklist\n")
--local len = decode.length(conn:receive(4)) - 4
--local answer = conn:receive(len)
--decode.message(answer)
conn:send("quit\n")
conn:close()
