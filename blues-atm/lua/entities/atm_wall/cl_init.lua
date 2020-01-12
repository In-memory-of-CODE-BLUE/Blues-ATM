include("shared.lua")

--The X resolution of the screen
local screenX = 1024
local screenY = 676

BATM_CACHED_ATMS = BATM_CACHED_ATMS or {}

--Lerps between colors instead of single values
local function LerpColor(t, col1, col2)
	local newCol = Color(0,0,0,0)

	newCol.r = Lerp(t, col1.r, col2.r)
	newCol.g = Lerp(t, col1.g, col2.g)
	newCol.b = Lerp(t, col1.b, col2.b)
	newCol.a = Lerp(t, col1.a, col2.a)

	return newCol
end

--Formats a number into a string with commas
local function comma_value(amount)
 	local formatted = amount
 	while true do   
    	formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    	if (k==0) then
    		break 
    	end
  	end
	return formatted
end
 
--Set up the entity and its render targts and materials
function ENT:Initialize()
	
	self.screenMaterial = CreateMaterial("blueatm_machinescreenmat_"..self:EntIndex(), "UnlitGeneric", {})
	self.renderTarget = GetRenderTarget("blueatm_machinescreenmat_"..self:EntIndex(), 1024, 1024, false)
	self.color = Color(math.random(0, 255), math.random(0, 255), math.random(0, 255))

	--Set up back panel
	self.csModel = ClientsideModel("models/bluesatm/atm_wall_back.mdl")
	self.csModel:SetPos(self:GetPos())
	self.csModel:SetAngles(self:GetAngles())
	self.csModel:SetParent(self)
	self.csModel:SetNoDraw(true)

	self.ScreenZoom = 1
	self.ScreenRotation = 0
	self.textRotation = 0

	--The position of the cursor
	self.cursor = {x= 0, y = 0}

	self.screenMaterial:SetTexture('$basetexture', self.renderTarget)

	self.currentSceneName = nil

	--The buttons on the screen
	self.buttons = {}

	--Prevent double presses
	self.lastPressedTime = CurTime()

	self:SetScene("home")

	BATM_CACHED_ATMS[self:EntIndex()] = self
end

local lastButton = 0

--Clears all the buttons on the screen
function ENT:ClearButtons()
	self.buttons = {}
end

function ENT:AddButton(x, y, width, height, onClick, onMouseEnter, onMouseExit)
	table.insert(self.buttons, {hovered = false, x = x, y = y, w = width, h = height, onClick = onClick, onMouseEnter = onMouseEnter, onMouseExit = onMouseExit})
end

--When called, it will try to press a button where ever the cursor is, if not button exists then it does nothing
function ENT:PressButton()

	--First, do we have any buttons?
	if table.Count(self.buttons) > 0 then
		--This will contain the acctual button
		local button = nil
		--Now we need to find the button that we are on
		for k ,v in pairs(self.buttons) do
			--We are in the top left, now lets check to make sure that we are in the bottom right
			if self.cursor.x >= v.x and self.cursor.y >= v.y then
				if self.cursor.x <= v.x + v.w and self.cursor.y <= v.y + v.h then
					--Found a button!
					button = v
					break
				end
			end
		end

		--a button was found
		if button ~= nil then
			button.onClick(self) 
			return
		end 
	end 

	--If we made it this far it means they were not looking at a button on the screen
	--so instead lets check if there looking at a keypad button
	if self.selectedButton ~= nil then
		if self.currentSceneName ~= nil and BATM.Scenes[self.currentSceneName] ~= nil then
			if BATM.Scenes[self.currentSceneName].OnKeypadPressed ~= nil then
				BATM.Scenes[self.currentSceneName].OnKeypadPressed(self, self.selectedButton)
			end
		end
	end
end

--Recalculates the position the cursor should be at on the screen
--Also updates buttons to call onMouseEnter and onMouseExit
function ENT:UpdateCursorPosition()
	--To far
	if self:GetPos():Distance(LocalPlayer():GetPos()) > 100 then return end

	--Not us
	if LocalPlayer():GetEyeTrace().Entity ~= self then return end

	--Create ray
	local rayOrigin = LocalPlayer():EyePos()
	local rayDirection = LocalPlayer():EyeAngles():Forward()
	local planePosition = self:GetPos() + (self:GetAngles():Forward() * -3)
	local planeAngle = self:GetAngles()
	planeAngle:RotateAroundAxis(planeAngle:Up(),180)

	local planeNormal = planeAngle:Forward() 


	local ang = Angle(0, 0, 0)
	ang:RotateAroundAxis(self:GetAngles():Right(), -15.3)
	planeNormal:Rotate(ang)
 
	local hitPos = util.IntersectRayWithPlane(rayOrigin, rayDirection, planePosition, planeNormal)

	if hitPos == nil then return end

	--render.DrawWireframeSphere(hitPos,1,25,25,Color(255,0,0, 50),false)

	hitPos = self:WorldToLocal(hitPos)

	local screenTopLeft = Vector(13.716227, 11.510023, 61.104160)
	local screenBottomRight = Vector(9.706230, -11.731017, 46.445992)

	local totalDifference = screenTopLeft - screenBottomRight

	local xCursorScale = (screenTopLeft.y - hitPos.y) / totalDifference.y
	local yCursorScale = (screenTopLeft.z - hitPos.z) / totalDifference.z
	
	--Translate the scales into acctualy screen chords
	local xScreenChord = math.Clamp(xCursorScale * screenX, 0, screenX)
	local yScreenChord = math.Clamp(yCursorScale * screenY, 0, screenY)

	--Now updaet the entities cursor position
	self.cursor.x = xScreenChord
	self.cursor.y = yScreenChord

	--Now check which buttons are entered and which ones are not
	for k ,v in pairs(self.buttons) do
		local mouseInRange = false

		--We are in the top left, now lets check to make sure that we are in the bottom right
		if self.cursor.x >= v.x and self.cursor.y >= v.y then
			if self.cursor.x <= v.x + v.w and self.cursor.y <= v.y + v.h then
				mouseInRange = true
				if v.hovered == false then
					self.buttons[k].hovered = true
					if v.onMouseEnter then
						v.onMouseEnter(self)
					end
				end
			end
		end

		--Check hover status
		if not mouseInRange and v.hovered then
			self.buttons[k].hovered = false
			if v.onMouseExit then
				v.onMouseExit(self)
			end
		end
	end

	--Now check which keypad button they are looking at
	local rayOrigin = LocalPlayer():EyePos()
	local rayDirection = LocalPlayer():EyeAngles():Forward()
	local planePosition = self:GetPos() + (self:GetAngles():Up() * 41.2)
	local planeAngle = self:GetAngles()
	planeAngle:RotateAroundAxis(planeAngle:Up(),180)

	local planeNormal = planeAngle:Forward() 
	local ang = Angle(0, 0, 0)
	ang:RotateAroundAxis(self:GetAngles():Right(), -80)
	planeNormal:Rotate(ang)
 
	local hitPos = util.IntersectRayWithPlane(rayOrigin, rayDirection, planePosition, planeNormal)

	if hitPos == nil then return end
	hitPos = self:WorldToLocal(hitPos)

	local selectedButton = nil
	--Check if its in the zone of a keypad
	for k ,v in pairs(self.KeypadButtons) do
		if hitPos:WithinAABox(v.v2,v.v1) then
			self.selectedButton = k
			selectedButton = k
			break
		end
	end

	if selectedButton == nil then
		self.selectedButton = nil
	end
end

--Allows you to change a scene (A scene is a table, that has a Think, Draw and a Unload which get called respectivly)
function ENT:SetScene(sceneName)
	--Clear any previous buttons
	self:ClearButtons()

	local scene = BATM.Scenes[sceneName]

	--Prevent potential error
	if scene == nil then print("Failed to load ss not found") return end

	--Unload the old scene
	if BATM.Scenes[self.currentSceneName] ~= nil then 
		--Clear button
		BATM.Scenes[self.currentSceneName].Unload(self, sceneName) --Pass the sceneName that we are changing to
	end

	--Call on load on the new scene
	scene.Load(self)

	self.currentSceneName = sceneName
end

--Draw the model and call the screen rendering functions.
function ENT:RenderScreen()
	if self:GetPos():Distance(LocalPlayer():GetPos()) < 300 and not screenDisabled and BATM.Scenes[self.currentSceneName] ~= nil then
		--Draw the screen
		render.PushRenderTarget(self.renderTarget)
			render.Clear(0,0,0,0,true,true) 
			cam.Start2D()
					BATM.Scenes[self.currentSceneName].Draw(self, screenX, screenY) --Draw the scene
			cam.End2D()
		render.PopRenderTarget()
 
		--Update material texture
		self.csModel:SetSubMaterial(3, "!blueatm_machinescreenmat_"..self:EntIndex())
	end

end

--Handle scene thinks
function ENT:Think()
	if BATM.Scenes[self.currentSceneName] ~= nil then
		BATM.Scenes[self.currentSceneName].Think(self, FrameTime()) 
	end

	self.csModel:SetPos(self:GetPos()) 
	self.csModel:SetAngles(self:GetAngles())

	if self:GetPos():Distance(LocalPlayer():GetPos()) < 150 and not screenDisabled then
		--Updates the cursor position
		self:UpdateCursorPosition()
	end
end

local buttonCooldown = CurTime()

hook.Add( "KeyPress", "batm:client_use", function( ply, key )
	if key == IN_USE and CurTime() - buttonCooldown > 0.1 then
		if LocalPlayer():GetEyeTrace().Entity ~= nil and IsValid(LocalPlayer():GetEyeTrace().Entity) and LocalPlayer():GetEyeTrace().Entity:GetClass() == "atm_wall" then
			LocalPlayer():GetEyeTrace().Entity:PressButton()
			buttonCooldown = CurTime()
		end
	end
end )

--[[-------------------------------------------------------------------------
Rendering
---------------------------------------------------------------------------]]
local DynamicLight = DynamicLight
local render = render

hook.Add("PreDrawTranslucentRenderables" , "batm:drawAtms", function(depth, skybox)
	if skybox then return end

	for k, s in pairs(BATM_CACHED_ATMS) do
		if not IsValid(s) then continue end

		if BATM.ScreenDisabled == false then
			s:RenderScreen()
		end
 
		--Figure out if this should be rendered?
		local screenpos = s:GetPos():ToScreen()
		if screenpos.visible == false then
			continue --Its behind the player
		end
		s.csModel:DrawModel()
		--Is something blocking out direction view to it?
		render.ClearStencil()
		render.SetStencilEnable( true )
			render.SetStencilWriteMask( 255 )
			render.SetStencilTestMask( 255 )
			render.SetStencilReferenceValue( 57 )
	        render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_ALWAYS )
			render.SetStencilPassOperation( STENCILOPERATION_REPLACE )

			local angle = s:GetAngles()
			angle:RotateAroundAxis(angle:Right(), -90)

			cam.Start3D2D(s:GetPos() - (s:GetAngles():Up() * -61) + (s:GetAngles():Forward() * -1.3), angle, 0.5)
			draw.NoTexture()
				draw.RoundedBox(0,-64 / 2,-64 / 2,75.5,65,Color(255,255,255,1))
			cam.End3D2D()
			
			render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
			render.SuppressEngineLighting(true)
			--render.DepthRange(0, 0.9999)
			
			render.OverrideDepthEnable(true, false)
			cam.IgnoreZ(true)
			s.csModel:DrawModel()
			cam.IgnoreZ(false)
			--s.csModel:DrawModel()
			render.OverrideDepthEnable(false, false)
			render.SuppressEngineLighting(false)
			
			render.OverrideDepthEnable(false, true)
			if BATM.LightsDisabled == false then
				s.dlight = DynamicLight(s:EntIndex())
				if ( s.dlight ) then
					s.dlight.pos = s:GetPos() + (s:GetAngles():Forward() * -14) + (s:GetAngles():Up() * 62)
					s.dlight.r = 255
					s.dlight.g = 255
					s.dlight.b = 255
					s.dlight.brightness = 5
					s.dlight.Decay = 0
					s.dlight.Size = 70 
					s.dlight.DieTime = CurTime() + 0.5
				end
			end
		render.SetStencilEnable( false )
		
		--render.DepthRange(0, 1)
		
	
		--s:DrawModel()
	end
end)



--[[-------------------------------------------------------------------------
Commands
---------------------------------------------------------------------------]]
concommand.Add("batm_enable_screens", function() 
	BATM.ScreenDisabled = false
end)

concommand.Add("batm_disable_screens", function() 
	BATM.ScreenDisabled = true
end)

concommand.Add("batm_enable_lights", function() 
	BATM.LightsDisabled = false
end)

concommand.Add("batm_disable_lights", function() 
	BATM.LightsDisabled = true
end)

--[[-------------------------------------------------------------------------
Networking
---------------------------------------------------------------------------]]
net.Receive("batm:updatescene", function()
	local e = net.ReadEntity()
	local sceneName = net.ReadString()

	--Uh oh
	if e == nil and not e:IsValid() then return end

	--Update the scene
	if e.SetScene then
		e:SetScene(sceneName) --Sometimes errors, maybe outside player PVC?
	end
end)
