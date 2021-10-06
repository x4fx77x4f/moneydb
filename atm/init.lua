--@name ATM
--@server
--@include casino/moneydb/sv_lib.lua
--@include casino/atm/cl_main.lua
--@clientmain casino/atm/cl_main.lua
dofile('casino/moneydb/sv_lib.lua')

local ready = false
local function scan()
	moneydb.init()
	if moneydb.host then
		ready = true
		timer.remove('ready')
	end
	net.start('ready')
		net.writeBool(ready)
	net.send()
end
timer.create('ready', 2, 0, scan)
scan()
net.receive('init', function(_, ply)
	net.start('ready')
		net.writeBool(ready)
	net.send(ply)
end)
hook.add('StarfallError', 'ready', function(ent, ply, err)
	if ent ~= moneydb.host then
		return
	end
	ready = false
	net.start('ready')
		net.writeBool(false)
	net.send()
	timer.create('ready', 2, 0, scan)
end)

local ratelimit = {}
local function errorClient(ply, msg)
	net.start('error')
		net.writeString(msg)
	net.send(ply)
end

net.receive('balance', function(_, ply)
	if ratelimit[ply] then
		return errorClient(ply, "RATELIMIT\nEXCEEDED")
	end
	ratelimit[ply] = true
	moneydb.getBalance(ply, function(success, balance)
		if not success then
			ratelimit[ply] = false
			return errorClient(ply, "FAILED TO GET\nBALANCE")
		end
		net.start('balance')
			net.writeInt(balance, MDB_MONEY_WIDTH)
		net.send(ply)
		ratelimit[ply] = false
	end)
end)
local topup = 1000
net.receive('getmoney', function(_, ply)
	if ratelimit[ply] then
		return errorClient(ply, "RATELIMIT\nEXCEEDED")
	end
	ratelimit[ply] = true
	moneydb.getBalance(ply, function(success, balance)
		if not success then
			ratelimit[ply] = false
			return errorClient(ply, "FAILED TO GET\nBALANCE")
		end
		if balance >= 100 then
			ratelimit[ply] = false
			return errorClient(ply, "YOU ARE NOT ELIGIBLE\nTO TOP UP")
		end
		moneydb.increaseBalance(ply, topup, function(success)
			if not success then
				ratelimit[ply] = false
				return errorClient(ply, "FAILED TO CHANGE\nBALANCE")
			end
			net.start('getmoney')
				net.writeInt(balance+topup, MDB_MONEY_WIDTH)
			net.send(ply)
			ratelimit[ply] = false
		end)
	end)
end)
