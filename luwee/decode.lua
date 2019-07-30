local m = {}
local striter = require("striter")
local pprint = require("prettyprint").print

------------------
-- Object class --
------------------

local obj = {}
obj.__index = obj

function obj.new(type, data)
	local self = setmetatable({}, obj)
	self.__type = type
	for k,v in pairs(data) do
		self[k] = v
	end
	return self
end

--------------
-- Decoders --
--------------

-- All the types from the spec
-- https://weechat.org/files/doc/stable/weechat_relay_protocol.en.html#objects
local decoders = {
	tim = nil,
	htb = nil,
	hda = nil,
	arr = nil,
}

local function read_object(iter)
	local type = iter:next()..iter:next()..iter:next()
	local decoder = decoders[type]
	if not decoder then
		error(("Unknown type %q"):format(type))
	end
	return decoder(iter)
end

function decoders.lon(iter)
	--TODO handle signed values
	local len = iter:next():byte()
	local output = 0
	for i=1, len do
		output = output * 256 + iter:next():byte()
	end
	return obj.new("lon", {value = output})
end

function decoders.chr(iter)
	local value = iter:next()
	return obj.new("chr", {value = value})
end

function decoders.ptr(iter)
	local len = iter:next():byte()
	local bytes = {}
	for i=1, len do
		bytes[#bytes+1] = iter:next()
	end
	return obj.new("ptr", {value=table.concat(bytes)})
end

function decoders.tim(iter)
	local output = decoders.ptr(iter)
	output.__type = "tim"
	return output
end

function decoders.arr(iter)
	--TODO check decoder exists
	local type = iter:next()..iter:next()..iter:next()
	local count = decoders.int(iter).value
	local values = {}
	for i=1, count do
		values[i] = decoders[type](iter)
	end
	return obj.new("arr", {values = values})
end

function decoders.str(iter)
	local len_bytes = iter:next()..iter:next()..iter:next()..iter:next()
	if len_bytes == "\255\255\255\255" then
		-- null string
		return obj.new("str", {length=0})
	end
	local length = m.length(len_bytes)
	local output = {}
	for i=1, length do
		output[#output+1] = iter:next()
	end
	return obj.new("str", {length=length,content=table.concat(output)})
end

function decoders.buf(iter)
	local output = decoders.str(iter)
	output.__type = "buf"
	return output
end

function decoders.inf(iter)
	local name = decoders.str(iter).content
	local value = decoders.str(iter).content
	return obj.new("inf", {name = name, value = value})
end

function decoders.int(iter)
	--TODO Probably could do better
	local val_bytes = iter:next()..iter:next()..iter:next()..iter:next()
	local value = m.length(val_bytes)
	if value & 0x80000000 > 0 then
		-- signed integer
		value = - (0xffffffff - value + 1)
	end
	return obj.new("int", {value = value})
end

local function read_variable(iter)
	local name = decoders.str(iter).content
	local value = read_object(iter)
	return obj.new("variable", {name=name, value=value})
end

local function read_item(iter)
	local count = decoders.int(iter).value
	local variables = {}
	for i=1, count do
		variables[i] = read_variable(iter)
	end
	return obj.new("item", {count=count, variables=variables})
end

function decoders.inl(iter)
	local name = decoders.str(iter).content
	local count = decoders.int(iter).value
	local items = {}
	for i=1, count do
		items[i] = read_item(iter)
	end
	return obj.new("inl", {name = name, count = count, items = items})
end

----------------------
-- Public functions --
----------------------

function m.length(bytes)
	local output = 0
	for char in bytes:gmatch(".") do
		output = output * 256 + char:byte()
	end
	return output
end

function m.message(message)
	local iter = striter.new(message)
	local compression = iter:next()
	if compression ~= "\0" then
		error("Compression isn't handled.")
	end
	local id = decoders.str(iter)
	print("id:")
	pprint(id, true)
	local objects = {}
	while iter:peek() ~= nil do
		objects[#objects+1] = read_object(iter)
	end
	print("objects:")
	pprint(objects, true)
end

return m
