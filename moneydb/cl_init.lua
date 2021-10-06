--@name moneydb
--@client
--@include casino/moneydb/sh_constants.lua
if player() ~= owner() then
	return
end
dofile('casino/moneydb/sh_constants.lua')

local path = 'moneydb.dat'
local db = {}
local function loadDb()
	local raw = file.read(path)
	db = {}
	if not raw then
		return false
	end
	--raw = fastlz.decompress(raw)
	for sid, amt in string.gmatch(raw, '(STEAM_%d:%d:%d+)=(%d+)\n') do
		db[sid] = tonumber(amt)
	end
	return true
end
local function writeDb()
	local raw = {}
	local i = 1
	for sid, amt in pairs(db) do
		raw[i] = sid.."="..amt
		i = i+1
	end
	raw[i] = ""
	raw = table.concat(raw, "\n")
	--raw = fastlz.compress(raw)
	return file.write(path, raw) or false
end

loadDb()
net.receive(MDB_KEY, function()
	local uid = net.readUInt(8)
	local action = net.readUInt(8)
	local target = net.readString()
	db[target] = db[target] or 0
	local dosave = true
	local retval = MDB_RESPONSE_SUCCESS
	local retbal
	if action == MDB_ACTION_INCREASE then
		local amt = net.readInt(MDB_MONEY_WIDTH)
		db[target] = db[target]+amt
	elseif action == MDB_ACTION_DECREASE then
		local amt = net.readInt(MDB_MONEY_WIDTH)
		db[target] = db[target]-amt
	elseif action == MDB_ACTION_TRANSFER then
		local dest = net.readString()
		local amt = net.readInt(MDB_MONEY_WIDTH)
		db[target] = db[target]-amt
		db[dest] = (db[dest] or 0)+amt
	elseif action == MDB_ACTION_GET then
		retval = MDB_RESPONSE_BALANCE
		retbal = db[target]
		dosave = false
	elseif action == MDB_ACTION_SET then
		local amt = net.readInt(MDB_MONEY_WIDTH)
		db[target] = amt
	elseif action == MDB_ACTION_DUMP then
		print("-----BEGIN MONEYDB DUMP-----")
		for sid, amt in pairs(db) do
			print(string.format("%s = %s", sid, string.comma(amt)))
		end
		print("-----END MONEYDB DUMP-----")
		dosave = false
	else
		retval = MDB_RESPONSE_FAILURE
		dosave = false
	end
	if dosave then
		writeDb()
	end
	--print(uid, retval, retbal)
	net.start(MDB_KEY)
		net.writeUInt(uid, 8)
		net.writeUInt(retval, 8)
		if retbal then
			net.writeInt(retbal, MDB_MONEY_WIDTH)
		end
	net.send()
end)
