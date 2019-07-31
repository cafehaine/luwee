local fltk = require("moonfltk")
local timer = require("moonfltk.timer")
local luwee = require("luwee")

function timer_callback(tid)
	luwee.check_input()
	timer.start(tid)
end

timer.init()
tid = timer.create(0.5, timer_callback)
timer.start(tid)

local windows = {}

local current_buffer = nil

local function set_current_buffer(full_name)
	if full_name == nil then return end
	windows.main.buffer_label:label(full_name)
	current_buffer = full_name
end

local function add_buffer(buffer)
	if current_buffer == nil then
		set_current_buffer(buffer.full_name)
	end
	windows.main.channel_browser:add(buffer.full_name)
end

luwee.register_callback("buffer_added", add_buffer)

local function browser_callback(browser)
	set_current_buffer(browser:text(browser:value()))
end

local function input_callback(input)
	if current_buffer ~= nil then
		luwee.send(current_buffer, input:value())
	end
	input:value("")
end

local function done_setup(button)
	local win = windows.setup
	local addr = win.addr_input:value()
	if addr == nil or addr == "" then
		fltk.message("Please enter an address.")
		return
	end
	local success, err = pcall(luwee.connect, addr, win.port_input:value(), win.ssl_button:value(), win.pass_input:value())
	if not success then
		fltk.alert(err)
	else
		win._:hide()
	end
end

-----------------
-- Main window --
-----------------

windows.main = {}
local win = windows.main
win._ = fltk.double_window(640, 480, "Luwee demo")

win.channel_browser = fltk.select_browser(10, 10, 140, 460)
win.channel_browser:callback(browser_callback)
win.channel_browser:done()

win.buffer_label = fltk.box(160, 10, 470, 30, "NO BUFFER SELECTED")

win.buffer_display = fltk.text_display(160, 40, 470, 390)

win.buffer_input = fltk.input(160, 440, 470, 30)
win.buffer_input:when(fltk.WHEN_ENTER_KEY)
win.buffer_input:callback(input_callback)

win._:done()

------------------
-- Setup window --
------------------

windows.setup = {}
local win = windows.setup
win._ = fltk.double_window(400, 210, "Relay settings - Luwee demo")
win.addr_input = fltk.input(100,10,290,30, "Address")
win.port_input = fltk.int_input(100,50,290,30, "Port")
win.port_input:value(9000)
win.ssl_button = fltk.check_button(100,90,290,30, "SSL")
win.pass_input = fltk.secret_input(100,130,290,30, "Password")
local setup_ok_button = fltk.return_button(10, 170, 380, 30, "OK")
setup_ok_button:callback(done_setup)
win._:done()
win._:set_modal()

---------------
-- Main code --
---------------

windows.main._:show(arg[0], ar, arg)
windows.setup._:show(arg[0], ar, arg)
return fltk.run()
