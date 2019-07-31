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

local decoders = {}

local function get_decoder(type)
	local decoder = decoders[type]
	if not decoder then
		error(("Unknown type %q"):format(type))
	end
	return decoder
end

local function read_object(iter)
	local type = iter:next()..iter:next()..iter:next()
	return get_decoder(type)(iter)
end

local function read_hdata_value(iter, pointer_count, keys)
	data = {}
	data.__p_path={}
	for i=1, pointer_count do
		data.__p_path[#data.__p_path+1] = decoders.ptr(iter)
	end
	for _,ktp in ipairs(keys) do
		data[ktp.key] = get_decoder(ktp.type)(iter)
	end
	return data
end

function decoders.hda(iter)
	local h_path = decoders.str(iter)
	local pointer_count = 0
	if h_path ~= nil then
		pointer_count = 1
		for _ in h_path:gmatch("/") do
			pointer_count = pointer_count + 1
		end
	end
	local keys_raw = decoders.str(iter)
	local keys = {}
	if keys_raw ~= nil then
		for ktp in keys_raw:gmatch("[^,:]*:[^,:]*") do
			local key, type = ktp:match("(.*):(.*)")
			print(key,type)
			keys[#keys+1] = {key=key, type=type}
		end
	end
	local count = decoders.int(iter)
	local output = {__type="hda", h_path = h_path}
	for i=1, count do
		output[i] = read_hdata_value(iter, pointer_count, keys)
	end
	return output
end

function read_hashtb_element(iter, type_k, type_v)
	error("REDO THIS")
	local key = get_decoder(type_k)(iter)
	local value = get_decoder(type_v)(iter)
	return obj.new("hashtb_element", {key=key, value=value})
end

function decoders.htb(iter)
	error("REDO THIS")
	local type_keys = iter:next()..iter:next()..iter:next()
	local type_values = iter:next()..iter:next()..iter:next()
	local count = decoders.int(iter).value
	local elements = {}
	for i=1, count do
		elements[i] = read_hashtb_element(iter, type_keys, type_values)
	end
	return obj.new("htb", elements)
end

function decoders.lon(iter)
	local len = iter:next():byte()
	local output = {}
	for i=1, len do
		output[i] = iter:next()
	end
	local value = tonumber(table.concat(output))
	return value
end

function decoders.chr(iter)
	local value = iter:next()
	return value
end

function decoders.ptr(iter)
	local len = iter:next():byte()
	local bytes = {}
	for i=1, len do
		bytes[#bytes+1] = iter:next()
	end
	return table.concat(bytes)
end

function decoders.tim(iter)
	local output = decoders.ptr(iter)
	return output
end

function decoders.arr(iter)
	local type = iter:next()..iter:next()..iter:next()
	local count = decoders.int(iter)
	local values = {}
	for i=1, count do
		values[i] = get_decoder(type)(iter)
	end
	return values
end

function decoders.str(iter)
	local len_bytes = iter:next()..iter:next()..iter:next()..iter:next()
	if len_bytes == "\255\255\255\255" then
		-- null string
		return nil
	end
	local length = m.length(len_bytes)
	local output = {}
	for i=1, length do
		output[#output+1] = iter:next()
	end
	return table.concat(output)
end

function decoders.buf(iter)
	return decoders.str(iter)
end

function decoders.inf(iter)
	local name = decoders.str(iter)
	local value = decoders.str(iter)
	return {name = name, value = value}
end

function decoders.int(iter)
	--TODO Probably could do better
	local val_bytes = iter:next()..iter:next()..iter:next()..iter:next()
	local value = m.length(val_bytes)
	if value & 0x80000000 > 0 then
		-- signed integer
		value = - (0xffffffff - value + 1)
	end
	return value
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
	local name = decoders.str(iter)
	local count = decoders.int(iter)
	local items = {name=name, __type="inl"}
	for i=1, count do
		items[i] = read_item(iter)
	end
	return items
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
	print("id:", id)
	local objects = {}
	while iter:peek() ~= nil do
		objects[#objects+1] = read_object(iter)
	end
	print("objects:")
	pprint(objects, true)
	return {id=id, objects=objects}
end

return m
