--@name ATM
--@client
--@include casino/moneydb/sh_constants.lua
--@include libs/fh_debouncer.lua
dofile('casino/moneydb/sh_constants.lua')
dofile('libs/fh_debouncer.lua')

local ready = false

local STATE_NOTICE = 0 -- plain text; can be dismissed
local STATE_MODAL = 1 -- plain text; cannot be dismissed
local STATE_MENU = 2 -- main menu
local STATE_BALANCE = 3 -- get balance
local STATE_GETMONEY = 4 -- get free money
local STATE_DARKRP = 5 -- "THIS ISN'T DARKRP!"

local state = STATE_MODAL
local activeStr = "PLEASE WAIT...\n\nCONNECTING TO\nSERVER..."
local buttons = nil

local stateButtons = {
	[STATE_NOTICE] = {
		{x=0, y=256, w=192, h=64, text="DONE", state=STATE_MENU}
	},
	[STATE_MENU] = {
		{x=0, y=256, w=192, h=64, text="BALANCE", state=STATE_BALANCE},
		{x=0, y=352, w=192, h=64, text="DEPOSIT", state=STATE_DARKRP},
		{x=0, y=448, w=192, h=64, text="WITHDRAW", state=STATE_DARKRP},
		{x=320, y=256, w=192, h=64, text="TOP UP", state=STATE_GETMONEY},
	}
}
stateButtons[STATE_BALANCE] = stateButtons[STATE_NOTICE]
stateButtons[STATE_GETMONEY] = stateButtons[STATE_NOTICE]

local function drawButtons(tbl)
	for _, button in pairs(buttons) do
		render.setRGBA(10, 29, 51, 255)
		render.drawRectFast(button.x, button.y, button.w, button.h)
		render.setRGBA(255, 255, 255, 255)
		render.drawRectOutline(button.x, button.y, button.w, button.h, 4)
		render.setRGBA(255, 255, 127, 255)
		render.drawSimpleText(button.ix, button.iy, button.text, button.ah, button.av)
	end
end

local stateDraw = {
	[STATE_NOTICE] = function()
		render.drawText(40, 40, activeStr)
		drawButtons(buttons)
	end,
	[STATE_MODAL] = function()
		render.drawText(40, 40, activeStr)
	end,
	[STATE_MENU] = function()
		render.drawText(40, 40, "LOOK AT AN OPTION\nAND THEN PRESS E")
		drawButtons(buttons)
	end
}
stateDraw[STATE_BALANCE] = stateDraw[STATE_NOTICE]
stateDraw[STATE_GETMONEY] = stateDraw[STATE_NOTICE]

local stateInit

local function changeState(newState, ...)
	state = newState
	buttons = stateButtons[state]
	for _, button in pairs(buttons or {}) do
		button.ix = button.ix or button.x+button.w/2
		button.iy = button.iy or button.y+button.h/2
		button.ah = button.ah or 1
		button.av = button.av or 1
		button.text = button.text or "Button"
	end
	local init = stateInit[state]
	if init then
		init(...)
	end
end

----BEGIN THE ACTUALLY IMPORTANT BLOCK-----
stateInit = {
	[STATE_BALANCE] = function()
		activeStr = "PLEASE WAIT..."
		changeState(STATE_MODAL)
		net.start('balance')
		net.send()
	end,
	[STATE_GETMONEY] = function()
		activeStr = "PLEASE WAIT..."
		changeState(STATE_MODAL)
		net.start('getmoney')
		net.send()
	end,
	[STATE_DARKRP] = function()
		activeStr = "THIS ISN'T DARKRP!"
		changeState(STATE_NOTICE)
	end
}
net.receive('balance', function()
	local bal = net.readInt(MDB_MONEY_WIDTH)
	activeStr = "YOUR BALANCE IS:\n\n$"..string.comma(bal)
	changeState(STATE_NOTICE)
end)
net.receive('getmoney', function()
	local bal = net.readInt(MDB_MONEY_WIDTH)
	activeStr = "CONGRATULATIONS!\nYOUR NEW BALANCE IS:\n\n$"..string.comma(bal)
	changeState(STATE_NOTICE)
end)

net.receive('ready', function()
	sready = net.readBool()
	if sready and not ready then
		changeState(STATE_MENU)
	else
		activeStr = "PLEASE WAIT...\n\nCONNECTING TO\nMONEYDB..."
		changeState(STATE_MODAL)
	end
	ready = sready
end)
net.receive('error', function()
	activeStr = "ERROR:\n"..net.readString()
	changeState(STATE_NOTICE)
end)
----END THE ACTUALLY IMPORTANT BLOCK-----

local bgclr = Color(20, 58, 102)
local font = render.createFont('Courier New', 40, 400, nil, false)
local cx, cy
hook.add('render', '', function()
	cx, cy = render.cursorPos()
	
	render.setBackgroundColor(bgclr)
	render.setRGBA(255, 255, 127, 255)
	render.setFont(font)
	stateDraw[state]()
	-- [[
	local cx, cy = render.cursorPos()
	if cx then
		render.setRGBA(0, 0, 0, 255)
		render.drawRect(cx-2, cy-2, 4, 4)
		render.setRGBA(255, 255, 255, 255)
		render.drawRect(cx-1, cy-1, 2, 2)
	end
	--]]
end)

local player = player()
-- for some reason, the KeyPress hook was getting run 5 times!!!
local used = false
hook.add('KeyPress', '', function(ply, btn)
	if ply ~= player or btn ~= IN_KEY.USE or used then
		return
	end
	used = true
	if not cx or not buttons then
		return
	end
	for _, button in pairs(buttons) do
		if
			cx > button.x and
			cx <= button.x+button.w and
			cy > button.y and
			cy <= button.y+button.h
		then
			return changeState(button.state)
		end
	end
end)
hook.add('KeyRelease', '', function(ply, btn)
	if ply ~= player or btn ~= IN_KEY.USE then
		return
	end
	used = false
end)

-- PlayerInitialized is not called when you restart clientside
net.start('init')
net.send()
