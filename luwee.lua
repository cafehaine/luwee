local m = {}

local socket = require("socket")
local ssl = require("ssl")

local decode = require("luwee.decode")

local connection = nil

function m.connect(server_address, server_port, server_ssl, server_password)
	if not server_ssl then
		error("Only ssl is suported for now.")
	end
	local conn, err = socket.tcp()
	if not conn then error(err) end
	conn:settimeout(10)
	local success, err = conn:connect(server_address, server_port)
	if not success then error(err) end
	local conn, err = ssl.wrap(conn, {mode="client", protocol="any"})
	if not conn then error(err) end
	--TODO find a way to ask the user if they trust the certificate
	conn:dohandshake()
	conn:send(("init password=%s,compression=off\n"):format(server_password))
	conn:settimeout(nil)
	conn:send("hdata buffer:gui_buffers(*) short_name,name,number\nsync\n")
	m.check_input()
	connection = conn
end

function m.check_input()
	if connection == nil then return end
	connection:settimeout(0.1)
	local len_bytes, err = connection:receive(4)
	if not len_bytes and err == "closed" then
		error("connection closed")
	elseif not len_bytes then
		return -- timeout
	end
	local len = decode.length(len_bytes) - 4
	connection:settimeout(nil)
	local answer = connection:receive(len)
	decode.message(answer)
end

return m
