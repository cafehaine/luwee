local m = {}

local socket = require("socket")
local ssl = require("ssl")

local decode = require("luwee.decode")

local connection = nil

local callback_names = {"buffer_added"}
local callbacks = {}

function m.register_callback(name, callback)
	for i=1, #callback_names do
		if callback_names[i] == name then
			local list = callbacks[name]
			if not list then
				list = {}
				callbacks[name] = list
			end
			list[#list+1] = callback
			return
		end
	end
	error(("Invalid callback name %q"):format(name))
end

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
	conn:send("(luwee_init) hdata buffer:gui_buffers(*) number,full_name,name,short_name,type,nicklist\nsync\n")
	m.check_input()
	connection = conn
end

local function handle_message(message)
	if message.id == "luwee_init" then
		for _,v in ipairs(message.objects[1]) do
			for _,callback in ipairs(callbacks["buffer_added"]) do
				callback(v)
			end
		end
	else
		print("TODO lel")
	end
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
	message = decode.message(answer)
	handle_message(message)
end

return m
