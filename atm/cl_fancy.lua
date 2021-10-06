--@name ATM
--@client
--@include casino/atm/cl_main.lua

--local sw, sh = 257.34176010943, 512
local m1a, m1b, m1c, m1d = {50, 100, 50, 0, 0}, {207.341760109, 100, 50, 0.5, 0}, {207.341760109, 257.341760109, 20, 0.5, 0.5}, {50, 257.341760109, 20, 0, 0.5}
local m1origin = Vector(unpack(m1a))
local m1normal = Vector(0, -0.18729369010395, -0.98230396194215)
--[[
m1a = Vector(unpack(m1a))
m1b = Vector(unpack(m1b))
m1c = Vector(unpack(m1c))
m1d = Vector(unpack(m1d))
-- (bottom left - top left):cross(top right - top left)
local a = m1d-m1a
--a:normalize()
local b = m1b-m1a
--b:normalize()
local n = a:cross(b)
n:normalize()
print(string.format("Vector(%s, %s, %s)", unpack(n)))
--]]

local hook_add = hook.add
function hook.add(hookname, name, func)
	return hook_add(hookname == 'render' and 'render2' or hookname, name, func)
end

local render_cursorPos = render.cursorPos
local player = player()
function render.cursorPos()
	local x, y = render_cursorPos()
	if not x then
		return
	end
	local rayStart = Vector(x, y, 0)
	-- The first version works perfectly... at an angle of 0, -90, 0 *only*.
	-- Thanks to Derpius again for helping out with this at 2 AM.
	--local rayDelta = player:getAimVector():getRotated(render.getScreenEntity():getAngles())
	--local rayDelta = player:getAimVector():getRotated(render.getScreenEntity():getRight():getAngle())
	local rayDelta = render.getScreenEntity():worldToLocalAngles(player:getAimVector():getAngle()):getForward()
	rayDelta.y = -rayDelta.y
	rayDelta.z = -rayDelta.z
	local p = trace.intersectRayWithPlane(rayStart, rayDelta*500, m1origin, m1normal)
	--[[
	render.selectRenderTarget()
		render.setRGBA(255, 95, 95, 191)
		render.draw3DSphere(rayStart, 5, 8, 16)
		render.setRGBA(95, 255, 95, 191)
		render.draw3DSphere(rayStart+rayDelta*10, 5, 8, 16)
		if hitpos then
			render.setRGBA(95, 95, 255, 191)
			render.draw3DSphere(hitpos, 5, 8, 16)
		end
		render.setRGBA(255, 255, 95, 191)
		render.draw3DSphere(Vector(unpack(m1a))+m1normal*15, 5, 8, 16)
	render.selectRenderTarget('guest')
	--]]
	if not p then
		return
	end
	-- The following is Derpius' code, used with permission.
	-- I am shameful, but very, very thankful!
	-- Much time was spent looking at colored spheres and
	-- hitting our heads against the wall.
	local v1 = Vector(unpack(m1a))
	if p.x < v1.x then
		return
	end
	local v2 = Vector(unpack(m1b))
	local v3 = Vector(unpack(m1d))
	local z = v1:getDistance(p)
	local cosT = (p-v1):getNormalized():dot((v3-v1):getNormalized())
	local u, v = z*math.sin(math.acos(cosT))/v1:getDistance(v2), z*cosT/v1:getDistance(v3)
	if u < 0 or u > 1 or v < 0 or v > 1 then
		return
	end
	return u*512, v*512
end

local render_setBackgroundColor = render.setBackgroundColor
local vbgclr = Color(0, 0, 0, 255)
function render.setBackgroundColor(clr)
	vbgclr = clr
end

local bgclr = Color(127, 127, 127, 255)
render.createRenderTarget('guest')

local m2a, m2b, m2c, m2d = Vector(0, 0, 0), Vector(257.34176010943, 0, 0), Vector(257.34176010943, 96, 0), Vector(0, 96, 0) -- top bezel
local m3a, m3b, m3c, m3d = Vector(32, 96, 51), Vector(225.341760109, 96, 51), Vector(225.341760109, 261.341760109, 21), Vector(32, 261.341760109, 21) -- part behind screen
local m4a, m4b, m4c, m4d = Vector(32, 261.341760109, 21), Vector(225.341760109, 261.341760109, 21), Vector(225.341760109, 384, 21), Vector(32, 384, 21) -- part below m3
local m5a, m5b, m5c, m5d = Vector(32, 96, 0), Vector(225.341760109, 96, 0), Vector(225.341760109, 96, 51), Vector(32, 96, 51) -- connects top of m3 to bezel
local m6a, m6b, m6c, m6d = Vector(0, 96, 0), Vector(32, 96, 0), Vector(32, 384, 0), Vector(0, 384, 0) -- left bezel
local m7a, m7b, m7c, m7d = Vector(225.341760109, 96, 0), Vector(257.34176010943, 96, 0), Vector(257.34176010943, 384, 0), Vector(225.341760109, 384, 0) -- left bezel
local m8a, m8b, m8c, m8d = Vector(0, 384, 0), Vector(257.34176010943, 384, 0), Vector(257.34176010943, 512, 0), Vector(0, 512, 0) -- bottom bezel
local m9a, m9b, m9c, m9d = Vector(32, 384, 21), Vector(225.341760109, 384, 21), Vector(225.341760109, 384, 0), Vector(32, 384, 0) -- connects bottom of m4 to bezel

local logofont = render.createFont('Roboto', 70, 800, true)

hook_add('render', '', function()
	if render.isInRenderView() then
		return
	end
	
	render_setBackgroundColor(bgclr)
	render.selectRenderTarget('guest')
		render.clear(vbgclr, true)
		hook.run('render2')
	render.selectRenderTarget()
	
	render.enableDepth(true)
	-- [[
	render.setMaterial()
	render.setRGBA(150, 150, 150, 255)
	render.draw3DQuad(m2a, m2b, m2c, m2d)
	render.draw3DQuad(m6a, m6b, m6c, m6d)
	render.draw3DQuad(m7a, m7b, m7c, m7d)
	render.draw3DQuad(m8a, m8b, m8c, m8d)
	render.setRGBA(95, 95, 95, 255)
	render.draw3DQuad(m3a, m3b, m3c, m3d)
	render.draw3DQuad(m4a, m4b, m4c, m4d)
	render.setRGBA(63, 63, 63, 255)
	render.draw3DQuad(m5a, m5b, m5c, m5d)
	render.draw3DQuad(m9a, m9b, m9c, m9d)
	--]]
	render.setRenderTargetTexture('guest')
	render.setRGBA(255, 255, 255, 255)
	render.draw3DQuadUV(m1a, m1b, m1c, m1d)
	render.enableDepth(false)
	render.setRGBA(127, 31, 31, 255)
	render.setFont(logofont)
	render.drawSimpleText(128.670880055, 48, "ATM", 1, 1)
end)

dofile('casino/atm/cl_main.lua')
