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

local function tree_callback(tree, pathname, reason)
	print(tree, pathname, reason)
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

win.channel_tree = fltk.tree(10, 10, 140, 460)
win.channel_tree:showroot(false)
win.channel_tree:callback(tree_callback)
win.channel_tree:done()

win.buffer_display = fltk.text_display(160, 10, 470, 420)

win.buffer_input = fltk.input(160, 440, 470, 30)

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
