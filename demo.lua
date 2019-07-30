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

local main_window, setup_win, setup_addr_input, setup_port_input, setup_ssl_button, setup_pass_input

local function tree_callback(tree, pathname, reason)
	print(tree, pathname, reason)
end

local function done_setup(button)
	local addr = setup_addr_input:value()
	if addr == nil or addr == "" then
		fltk.message("Please enter an address.")
		return
	end
	setup_win:hide()
	luwee.connect(addr, setup_port_input:value(), setup_ssl_button:value(), setup_pass_input:value())
end

-----------------
-- Main window --
-----------------

main_window = fltk.double_window(640, 480, "Luwee demo")

main_channel_tree = fltk.tree(10, 10, 140, 460)
main_channel_tree:showroot(false)
main_channel_tree:callback(tree_callback)
main_channel_tree:done()

main_buffer_display = fltk.text_display(160, 10, 470, 420)

main_buffer_input = fltk.input(160, 440, 470, 30)

main_window:done()

------------------
-- Setup window --
------------------

setup_win = fltk.double_window(400, 210, "Relay settings - Luwee demo")
setup_addr_input = fltk.input(100,10,290,30, "Address")
setup_port_input = fltk.int_input(100,50,290,30, "Port")
setup_port_input:value(9000)
setup_ssl_button = fltk.check_button(100,90,290,30, "SSL")
setup_pass_input = fltk.secret_input(100,130,290,30, "Password")
local setup_ok_button = fltk.return_button(10, 170, 380, 30, "OK")
setup_ok_button:callback(done_setup)
setup_win:done()
setup_win:set_modal()

---------------
-- Main code --
---------------

main_window:show(arg[0], ar, arg)
setup_win:show(arg[0], ar, arg)
return fltk.run()
