--@server
--@include casino/moneydb/sh_constants.lua
dofile('casino/moneydb/sh_constants.lua')

moneydb = {}
function moneydb.init(ply)
	ply = ply or owner()
	for _, ent in pairs(find.byClass('starfall_processor')) do
		if ent:getOwner() == ply and ent:getChipName() == "moneydb" then
			moneydb.host = ent
			return ent
		end
	end
end
function moneydb.onInit(callback, ply)
	local function try()
		moneydb.init(ply)
		if moneydb.host then
			timer.remove(MDB_KEY)
			callback(true)
		end
	end
	timer.create(MDB_KEY, 2, 0, try)
	try()
end

moneydb.queue = {}
function moneydb.addToQueue(callback, ...)
	local ruid = #moneydb.queue+1
	moneydb.queue[ruid] = callback
	hook.runRemote(moneydb.host, ruid, ...)
	return ruid
end
hook.add('remote', MDB_KEY, function(ent, _, ruid, status, ...)
	if ent ~= moneydb.host then
		return
	end
	local func = moneydb.queue[ruid]
	assert(func, "unknown nuid")
	func(status == MDB_RESPONSE_SUCCESS, ...)
end)

function moneydb.increaseBalance(ply, amt, callback)
	ply = type(ply) == 'Player' and ply:getSteamID() or ply
	moneydb.addToQueue(callback, MDB_ACTION_INCREASE, ply, amt)
end
function moneydb.decreaseBalance(ply, amt, callback)
	ply = type(ply) == 'Player' and ply:getSteamID() or ply
	moneydb.addToQueue(callback, MDB_ACTION_DECREASE, ply, amt)
end
function moneydb.transferMoney(src, dest, amt, callback)
	ply = type(ply) == 'Player' and ply:getSteamID() or ply
	moneydb.addToQueue(callback, MDB_ACTION_TRANSFER, src, dest, amt)
end
function moneydb.getBalance(ply, callback)
	ply = type(ply) == 'Player' and ply:getSteamID() or ply
	moneydb.addToQueue(callback, MDB_ACTION_GET, ply)
end
function moneydb.setBalance(ply, amt, callback)
	ply = type(ply) == 'Player' and ply:getSteamID() or ply
	moneydb.addToQueue(callback, MDB_ACTION_SET, ply, amt)
end
