--@name moneydb DEMO
--@shared
--@include casino/moneydb/sv_lib.lua
if SERVER then
	dofile('casino/moneydb/sv_lib.lua')
	moneydb.init()
	local fetching = {}
	net.receive('getBalance', function(_, ply)
		if fetching[ply] then
			return
		end
		fetching[ply] = true
		moneydb.getBalance(ply, function(success, balance)
			net.start('getBalance')
				net.writeInt(balance, 64)
			net.send(ply)
			fetching[ply] = false
		end)
	end)
	return
end
net.receive('getBalance', function()
	balance = net.readInt(64)
end)
hook.add('render', '', function()
	render.setFont('DermaLarge')
	render.drawText(10, 10, (balance and "Your balance is: "..balance or "Press E to get balance"))
end)
local usable = {[chip()] = true}
for _, ent in pairs(chip():getLinkedComponents()) do
	usable[ent] = true
end
hook.add('starfallused', '', function(user, ent)
	if user == player() and usable[ent] then
		net.start('getBalance')
		net.send()
	end
end)
