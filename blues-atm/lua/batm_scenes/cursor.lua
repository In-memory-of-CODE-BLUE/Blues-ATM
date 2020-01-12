--[[-------------------------------------------------------------------------
Draws the cursor
---------------------------------------------------------------------------]]

local scene = {}
local cursor = Material("bluesatm/cursor.png","noclamp smooth")

--Called when the scene is loaded
function scene.Load(ent)
 
end
  
--Draw code
function scene.Draw(ent, ScrW, ScrH) 
	surface.SetMaterial(cursor)
	surface.SetDrawColor(Color(40, 40, 40, 150))
	surface.DrawTexturedRect(ent.cursor.x + 8, ent.cursor.y + 8, 64, 64)
	surface.SetDrawColor(Color(200, 200, 200))
	surface.DrawTexturedRect(ent.cursor.x, ent.cursor.y, 64, 64)
end

--Think code (dt = FrameTime())
function scene.Think(ent, dt)

end

--Called when a the scene is unloaded
function scene.Unload(ent, newSceneName)

end

--Register the scene
BATM.RegisterScene(scene, "cursor")

