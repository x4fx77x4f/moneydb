--@name Video Poker
--@include casino/poker/cl_init.lua
--@clientmain casino/poker/cl_init.lua
--@include casino/moneydb/sv_lib.lua
--@include casino/poker/sh_cards.lua
--@include casino/poker/sh_errors.lua
--@include casino/poker/sh_payout.lua

-- If true, only one player can use the machine at a time, and all
-- players will be able to see what that player is doing.
local GLOBAL_STATE = true

dofile('casino/moneydb/sv_lib.lua')
local ready = false
moneydb.onInit(function()
	ready = true
	net.start('ready')
		net.writeBool(true)
		net.writeBool(GLOBAL_STATE)
	net.send()
end)
net.receive('ready', function(_, ply)
	net.start('ready')
		net.writeBool(ready)
		net.writeBool(GLOBAL_STATE)
	net.send(ply)
end)

dofile('casino/poker/sh_cards.lua')
dofile('casino/poker/sh_errors.lua')
dofile('casino/poker/sh_payout.lua')

local function randomHand(arr)
	arr = arr or {}
	for i=1, 5 do
		if not arr[i] then
			local card
			while true do
				card = select(2, table.random(cards))
				local pass = true
				for j=1, 5 do
					if arr[j] == card then
						pass = false
						break
					end
				end
				if pass then
					break
				end
			end
			arr[i] = card
		end
	end
	return arr
end

local sessions = {}
local activePlayer
timer.create('gc', 5, 0, function()
	local now = timer.systime()
	for ply, session in pairs(sessions) do
		if ply:isValid() then
			if now >= session.expires then
				sessions[ply] = nil
				net.start('error')
					if GLOBAL_STATE then
						net.writeEntity(ply)
					end
					net.writeInt(ERROR_SESSION_TIMEOUT, errorWidth)
				if GLOBAL_STATE then
					net.send()
				else
					net.send(ply)
				end
			end
		else
			sessions[ply] = nil
		end
	end
end)
local sessionLifetime = 30

local minBet = 1
local maxBet = 100
net.receive('draw', function(_, ply)
	if GLOBAL_STATE then
		if activePlayer and ply ~= activePlayer then
			net.start('error')
				net.writeEntity(activePlayer)
				net.writeUInt(ERROR_UNAUTHORIZED, errorWidth)
			net.send(ply)
			return
		end
		activePlayer = ply
	end
	local bet = net.readInt(MDB_MONEY_WIDTH)
	if bet < minBet then
		net.start('error')
			if GLOBAL_STATE then
				net.writeEntity(ply)
			end
			net.writeInt(ERROR_BET_TOO_LOW, errorWidth)
		if GLOBAL_STATE then
			net.send()
		else
			net.send(ply)
		end
		return
	end
	if bet > maxBet then
		net.start('error')
			if GLOBAL_STATE then
				net.writeEntity(ply)
			end
			net.writeInt(ERROR_BET_TOO_HIGH, errorWidth)
		if GLOBAL_STATE then
			net.send()
		else
			net.send(ply)
		end
		return
	end
	moneydb.getBalance(ply, function(success, balance)
		if not success then
			net.start('error')
				if GLOBAL_STATE then
					net.writeEntity(ply)
				end
				net.writeInt(ERROR_TRANSACTION_FAILED, errorWidth)
			if GLOBAL_STATE then
				net.send()
			else
				net.send(ply)
			end
			return
		end
		if balance < bet then
			net.start('error')
				if GLOBAL_STATE then
					net.writeEntity(ply)
				end
				net.writeInt(ERROR_INSUFFICIENT_FUNDS, errorWidth)
			if GLOBAL_STATE then
				net.send()
			else
				net.send(ply)
			end
			return
		end
		moneydb.transferMoney(ply, owner(), bet, function(success)
			if not success then
				net.start('error')
					if GLOBAL_STATE then
						net.writeEntity(ply)
					end
					net.writeInt(ERROR_TRANSACTION_FAILED, errorWidth)
				if GLOBAL_STATE then
					net.send()
				else
					net.send(ply)
				end
				return
			end
			local session = sessions[ply] or {}
			sessions[ply] = session
			session.expires = timer.systime()+sessionLifetime
			session.bet = bet
			local cards = randomHand()
			session.hand = cards
			net.start('draw')
				if GLOBAL_STATE then
					net.writeEntity(ply)
				end
				for i=1, 5 do
					net.writeUInt(cards[i], 8)
				end
			if GLOBAL_STATE then
				net.send()
			else
				net.send(ply)
			end
		end)
	end)
end)

net.receive('exchange', function(_, ply)
	if GLOBAL_STATE then
		if activePlayer and ply ~= activePlayer then
			net.start('error')
				net.writeEntity(activePlayer)
				net.writeUInt(ERROR_UNAUTHORIZED, errorWidth)
			net.send(ply)
			return
		end
		activePlayer = ply
	end
	local session = sessions[ply]
	if not session then
		net.start('error')
			if GLOBAL_STATE then
				net.writeEntity(ply)
			end
			net.writeInt(ERROR_NO_SESSION, errorWidth)
		if GLOBAL_STATE then
			net.send()
		else
			net.send(ply)
		end
		return
	end
	local hand = session.hand
	local held = {}
	for i=1, 5 do
		local cardHeld = net.readBool()
		if cardHeld then
			held[i] = true
		else
			hand[i] = nil
		end
	end
	randomHand(hand)
	for i, ci in pairs(hand) do
		hand[i] = cards[ci]
	end
	local winningHand = calculateHand(hand)
	local winningID, winningMult = unpack(winningHand and payoutsLookup[winningHand] or {})
	local winnings = winningMult and math.ceil(session.bet*winningMult)
	sessions[ply] = nil
	activePlayer = nil
	-- EWW DUPLICATED CODE!!!!
	if winnings then
		moneydb.transferMoney(owner(), ply, winnings, function(success)
			if not success then
				net.start('error')
					if GLOBAL_STATE then
						net.writeEntity(ply)
					end
					net.writeInt(ERROR_TRANSACTION_FAILED, errorWidth)
				if GLOBAL_STATE then
					net.send()
				else
					net.send(ply)
				end
				return
			end
			net.start('exchange')
				if GLOBAL_STATE then
					net.writeEntity(ply)
				end
				for i=1, 5 do
					net.writeBool(held[i] or false)
				end
				net.writeUInt(winningID, payoutWidth)
				net.writeUInt(winnings, MDB_MONEY_WIDTH)
				for i=1, 5 do
					net.writeUInt(hand[i].index, 8)
				end
			if GLOBAL_STATE then
				net.send()
			else
				net.send(ply)
			end
		end)
		return
	end
	net.start('exchange')
		if GLOBAL_STATE then
			net.writeEntity(ply)
		end
		net.writeUInt(0, payoutWidth)
		net.writeUInt(0, MDB_MONEY_WIDTH)
		for i=1, 5 do
			net.writeUInt(hand[i].index, 8)
		end
	if GLOBAL_STATE then
		net.send()
	else
		net.send(ply)
	end
end)

net.receive('forfeit', function(_, ply)
	if GLOBAL_STATE then
		if activePlayer and ply ~= activePlayer then
			net.start('error')
				net.writeEntity(activePlayer)
				net.writeUInt(ERROR_UNAUTHORIZED, errorWidth)
			net.send(ply)
			return
		end
		activePlayer = ply
	end
	sessions[ply] = nil
	activePlayer = nil
	net.start('forfeit')
		if GLOBAL_STATE then
			net.writeEntity(ply)
		end
	if GLOBAL_STATE then
		net.send()
	else
		net.send(ply)
	end
end)
