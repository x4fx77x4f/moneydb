--@name moneydb control panel
--@server
--@include casino/moneydb/cl_cfg.lua
--@clientmain casino/moneydb/cl_cfg.lua
--@include casino/moneydb/sv_lib.lua
net.receive('', function(_, ply)
	if ply ~= owner() then
		return
	end
	local 
end)
