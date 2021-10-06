--@name moneydb
--@server
--@include casino/moneydb/sh_constants.lua
--@include casino/moneydb/cl_init.lua
--@clientmain casino/moneydb/cl_init.lua
require('casino/moneydb/sh_constants.lua')
local moneydb = {}
local owner = owner()

local netqueue = {}
local function queueNet(ent, ruid)
	local nuid = #netqueue+1
	assert(nuid < 256, "overflowed netqueue")
	netqueue[nuid] = {ent, ruid}
	return nuid
end

net.receive(MDB_KEY, function(_, ply)
	if ply ~= owner then
		return
	end
	local nuid = net.readUInt(8)
	local payload = netqueue[nuid]
	assert(payload, "unknown nuid")
	netqueue[nuid] = nil
	local ent, ruid = unpack(payload)
	local status = net.readUInt(8)
	if status == MDB_RESPONSE_BALANCE then
		local balance = net.readInt(MDB_MONEY_WIDTH)
		hook.runRemote(ent, ruid, MDB_RESPONSE_SUCCESS, balance)
	else
		hook.runRemote(ent, ruid, status)
	end
end)

local whitelistEnt, whitelistPly = {}, {[owner]=true}
local meta = {__mode = 'k'}
setmetatable(whitelistEnt, meta)
setmetatable(whitelistPly, meta)
hook.add('remote', '', function(ent, sender, ruid, cmd, target, a, b)
	if not whitelistEnt[ent] and not whitelistPly[sender] then
		hook.runRemote(ent, ruid, MDB_RESPONSE_FAILURE)
		return
	end
	target = type(target) == 'Player' and target:getSteamID() or target
	a = type(a) == 'Player' and a:getSteamID() or a
	if cmd == MDB_ACTION_AUTH_ENT then
		if sender ~= owner then
			hook.runRemote(ent, ruid, MDB_RESPONSE_FAILURE)
			return
		end
		whitelistEnt[a] = true
		hook.runRemote(ent, ruid, MDB_RESPONSE_SUCCESS)
		return
	elseif cmd == MDB_ACTION_DEAUTH_ENT then
		if sender ~= owner then
			hook.runRemote(ent, ruid, MDB_RESPONSE_FAILURE)
			return
		end
		whitelistEnt[a] = nil
		hook.runRemote(ent, ruid, MDB_RESPONSE_SUCCESS)
		return
	elseif cmd == MDB_ACTION_AUTH_PLY then
		if sender ~= owner then
			hook.runRemote(ent, ruid, MDB_RESPONSE_FAILURE)
			return
		end
		whitelistPly[a] = true
		hook.runRemote(ent, ruid, MDB_RESPONSE_SUCCESS)
		return
	elseif cmd == MDB_ACTION_DEAUTH_PLY then
		if sender ~= owner then
			hook.runRemote(ent, ruid, MDB_RESPONSE_FAILURE)
			return
		end
		whitelistPly[a] = nil
		hook.runRemote(ent, ruid, MDB_RESPONSE_SUCCESS)
		return
	end
	local nuid = queueNet(ent, ruid)
	net.start(MDB_KEY)
		net.writeUInt(nuid, 8)
		net.writeUInt(cmd, 8)
		net.writeString(target)
		if
			cmd == MDB_ACTION_INCREASE or
			cmd == MDB_ACTION_DECREASE or
			cmd == MDB_ACTION_SET
		then
			net.writeInt(a, MDB_MONEY_WIDTH)
		elseif cmd == MDB_ACTION_TRANSFER then
			net.writeString(a)
			net.writeInt(b, MDB_MONEY_WIDTH)
		end
	net.send(owner)
end)
