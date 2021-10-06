--@name Video Poker
--@include casino/moneydb/sh_constants.lua
--@include casino/poker/sh_cards.lua
--@include casino/poker/sh_errors.lua
--@include casino/poker/sh_payout.lua
dofile('casino/moneydb/sh_constants.lua')
dofile('casino/poker/sh_cards.lua')
dofile('casino/poker/sh_errors.lua')
dofile('casino/poker/sh_payout.lua')

local buttons
local bet = 50
local draw, drawTime, hold, exchanged = {}
local winningHandStr, winningsStr, winningBoring
local GLOBAL_STATE, activePlayer

local activeError, activeErrorTime
net.receive('error', function()
	if GLOBAL_STATE == nil then
		return
	elseif GLOBAL_STATE then
		activePlayer = net.readEntity()
	end
	local errorCode = net.readUInt(errorWidth)
	activeError = errorLabels[errorCode]
	activeErrorTime = timer.systime()
	if
		errorCode == ERROR_NO_SESSION or
		errorCode == ERROR_SESSION_TIMEOUT
	then
		draw, drawTime, hold, exchanged = {}
		buttons[1].disabled = false
		buttons[3].disabled = true
		buttons[5].disabled = true
	elseif not drawTime then
		buttons[1].disabled = false
	end
end)

net.receive('draw', function()
	if GLOBAL_STATE == nil then
		return
	elseif GLOBAL_STATE then
		activePlayer = net.readEntity()
	end
	drawTime = timer.systime()
	draw, hold = {}, {}
	for i=1, 5 do
		draw[i] = cards[net.readUInt(8)]
	end
	activeError = nil
	buttons[1].disabled = true
	buttons[3].disabled = false
	buttons[5].disabled = false
	exchanged = false
end)

net.receive('exchange', function()
	if GLOBAL_STATE == nil then
		return
	elseif GLOBAL_STATE then
		activePlayer = net.readEntity()
	end
	activeError = nil
	drawTime = timer.systime()
	for i=1, 5 do
		hold[i] = net.readBool()
	end
	local winningID = net.readInt(payoutWidth)
	local winnings = net.readInt(MDB_MONEY_WIDTH)
	if winningID == 0 then
		winningHandStr, winningsStr, winningBoring = payouts[winningID][1], string.comma(winnings), true
	else
		winningHandStr, winningsStr, winningBoring = payouts[winningID][1], string.comma(winnings), false
	end
	for i=1, 5 do
		draw[i] = cards[net.readUInt(8)]
	end
	activePlayer = nil
	buttons[1].disabled = false
	buttons[3].disabled = true
	buttons[5].disabled = false
	exchanged = true
end)

net.receive('forfeit', function()
	if GLOBAL_STATE == nil then
		return
	elseif GLOBAL_STATE then
		activePlayer = net.readEntity()
	end
	activePlayer = nil
	activeError = nil
	buttons[1].disabled = false
	buttons[3].disabled = true
	buttons[5].disabled = true
end)

local cy = 300
local uifont = render.createFont('Roboto', 30)
local btnfont = render.createFont('Roboto', 20)
local cardfont = render.createFont('Roboto', 60, 800)

buttons = {
	{label="Draw", func=function()
		activeError, activeErrorTime = "Waiting for server"
		winningHandStr, winningsStr = nil
		draw, hold = {}
		net.start('draw')
			net.writeInt(bet, MDB_MONEY_WIDTH)
		net.send()
		buttons[1].disabled = true
		buttons[3].disabled = true
		buttons[5].disabled = true
	end},
	{label="", disabled=true},
	{label="Exchange", disabled=true, func=function()
		activeError, activeErrorTime = "Waiting for server"
		net.start('exchange')
			for i=1, 5 do
				local held = hold[i] or false
				if not held then
					draw[i] = nil
				end
				net.writeBool(held)
			end
		net.send()
		buttons[1].disabled = false
		buttons[3].disabled = true
		buttons[5].disabled = true
	end},
	{label="", disabled=true},
	{label="Forfeit", disabled=true, func=function()
		activeError, activeErrorTime = "Waiting for server"
		winningHandStr, winningsStr = nil
		draw, hold = {}
		net.start('forfeit')
		net.send()
		buttons[1].disabled = true
		buttons[3].disabled = true
		buttons[5].disabled = true
	end}
}
local by = 512-32-12
local bh = 32
local by2 = by+bh
for i=1, 5 do
	local button = buttons[i]
	button.x = (i-1)*100+12
	button.y = by
	button.w = 88
	button.h = bh
	render.setFont(btnfont)
	local tw, th = render.getTextSize(button.label)
	button.ix = (button.w-tw)/2+button.x
	button.iy = (button.h-th)/2+button.y
end

render.createRenderTarget('payout')
local payoutfont = render.createFont('Roboto', 55, 800)
hook.add('renderoffscreen', 'initPayout', function()
	render.selectRenderTarget('payout')
	render.setRGBA(0, 0, 70, 255)
	render.drawRect(0, 0, 1024, 512)
	render.setRGBA(255, 255, 127, 255)
	render.drawRectOutline(0, 0, 1024, 512, 4)
	render.setFont(payoutfont)
	local handName = {}
	local handPayout = {}
	for i, hand in pairs(payouts) do
		handName[i] = hand[1]
		handPayout[i] = hand[2].."x"
	end
	handName = table.concat(handName, "\n")
	handPayout = table.concat(handPayout, "\n")
	render.drawText(16, 12, handName)
	render.drawText(1008, 12, handPayout, 2)
	hook.remove('renderoffscreen', 'initPayout')
end)

local bgclr = Color(0, 0, 140)
local curx, cury
hook.add('render', '', function()
	local now = timer.systime()
	render.setBackgroundColor(bgclr)
	
	render.setRenderTargetTexture('payout')
	render.drawTexturedRectUV(0, 0, 512, 256, 0, 0, 1, 0.5)
	
	for i=1, 5 do
		local card = draw[i]
		local cx = (i-1)*100+12
		if card and (exchanged and hold[i] or now >= i*0.25+drawTime) then
			if hold[i] and not winningHandStr then
				render.setFont(uifont)
				render.setRGBA(0, 0, 0, 255)
				render.drawSimpleText(cx+44+2, cy-23+2, "HELD", 1, 1)
				render.setRGBA(255, 255, 255, 255)
				render.drawSimpleText(cx+44, cy-23, "HELD", 1, 1)
			end
			render.setRGBA(255, 255, 255, 255)
			render.drawRoundedBox(8, cx, cy, 88, 132)
			render.setColor(suitColors[card.suit])
			render.setFont(cardfont)
			render.drawSimpleText(cx+8, cy+8, rankShortLabels[card.rank])
			render.drawSimpleText(cx+50, cy+70, suitLabels[card.suit])
		else
			render.setRGBA(255, 127, 127, 255)
			render.drawRoundedBox(8, cx, cy, 88, 132)
		end
	end
	
	local interactionDisabled = drawTime and timer.systime() < drawTime+1.5
	
	if winningHandStr and not interactionDisabled then
		render.setFont(uifont)
		local blue = winningBoring and 255 or math.abs(math.sin(now*5))*255
		render.setRGBA(0, 0, 0, 255)
		render.drawSimpleText(8+2, cy-23+2, winningHandStr, 0, 1)
		render.drawSimpleText(504+2, cy-23+2, winningsStr, 2, 1)
		render.setRGBA(255, 255, blue, 255)
		render.drawSimpleText(8, cy-23, winningHandStr, 0, 1)
		render.drawSimpleText(504, cy-23, winningsStr, 2, 1)
	end
	
	render.setFont(uifont)
	local betStr = "BET: "..bet
	render.setRGBA(0, 0, 0, 255)
	render.drawSimpleText(256+2, by-18+2, betStr, 1, 1)
	render.setRGBA(255, 255, 255, 255)
	render.drawSimpleText(256, by-18, betStr, 1, 1)
	
	render.setFont(btnfont)
	for _, button in pairs(buttons) do
		if button.disabled or interactionDisabled or activeError then
			render.setRGBA(95, 95, 95, 255)
		else
			render.setRGBA(191, 191, 191, 255)
		end
		render.drawRoundedBox(8, button.x, button.y, button.w, button.h)
		render.setRGBA(0, 0, 0, 255)
		render.drawSimpleText(button.ix, button.iy, button.label)
	end
	
	if activeError then
		render.setFont(uifont)
		local p = 8
		local w, h = render.getTextSize(activeError)
		w, h = w+p+p, h+p+p
		local x, y = (512-w)/2, (512-h)/2
		render.setRGBA(0, 0, 70, 255)
		render.drawRect(x, y, w, h)
		render.setRGBA(255, 255, 127, 255)
		render.drawRectOutline(x, y, w, h, 2)
		render.setRGBA(255, 255, 255, 255)
		render.drawText(x+p, y+p, activeError)
		if activeErrorTime and now >= activeErrorTime+2 then
			activeError = nil
		end
	end
	
	curx, cury = render.cursorPos()
	if curx then
		render.setRGBA(0, 0, 0, 255)
		render.drawRect(curx-2, cury-2, 4, 4)
		render.setRGBA(255, 255, 255, 255)
		render.drawRect(curx-1, cury-1, 2, 2)
	end
end)

local me = player()
local used = false
hook.add('KeyPress', '', function(ply, btn)
	if
		ply ~= me or
		btn ~= IN_KEY.USE or
		used or
		not curx or
		activeError or
		(drawTime and timer.systime() < drawTime+1.5) or
		(activePlayer ~= nil and ply ~= activePlayer) or
		not isFirstTimePredicted()
	then
		return
	end
	used = true
	if cury > cy and cury <= cy+132 then
		if not hold or not buttons[1].disabled then
			return
		end
		local curx = curx-8
		if curx%100.8 > 88 then
			return
		end
		local i = math.ceil(curx/100.8)
		hold[i] = not hold[i]
	elseif cury > by and cury <= by2 then
		local curx = curx-8
		if curx%100.8 > 88 then
			return
		end
		local i = math.ceil(curx/100.8)
		local button = buttons[i]
		if button then
			local func = button.func
			if func then
				func()
			end
		end
	end
end)
hook.add('KeyRelease', '', function(ply, btn)
	if
		ply ~= me or
		btn ~= IN_KEY.USE or
		(activePlayer ~= nil and ply ~= activePlayer) or
		not isFirstTimePredicted()
	then
		return
	end
	used = false
end)

activeError = "Waiting for server"
net.receive('ready', function()
	ready = net.readBool()
	GLOBAL_STATE = net.readBool() or false
	if ready then
		activeError = nil
	end
end)
net.start('ready')
net.send()
