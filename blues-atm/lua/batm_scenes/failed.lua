--[[-------------------------------------------------------------------------
Draws the failed screen
---------------------------------------------------------------------------]]


surface.CreateFont( "batm_done_text", {
	font = "Coolvetica",
	extended = false,
	size = 75,
	weight = 300,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

local scene = {}

local failed = Material("bluesatm/failed.png", "noclamp smooth")

--Called when the scene is loaded
function scene.Load(ent)
	timer.Simple(2.5, function()
		if BATM.SelectedAccount == "personal" then
			ent:SetScene("personalaccount")
		else
			ent:SetScene("groupaccount")
		end
	end)

end

--Draw code
function scene.Draw(ent, ScrW, ScrH)

	--Draw the background
	BATM.Scenes["background"].Draw(ent, ScrW, ScrH)
 
	--Draw background
	draw.RoundedBox(0, 0, 100, ScrW, ScrH - 100, Color(232, 76, 61, 255))

	--Draw logo
	surface.SetDrawColor(Color(0,0,0,255))
	surface.SetMaterial(failed)
	surface.DrawTexturedRectRotated(ScrW/2, ScrH/2, 256, 256, 0)

	--Draw text
	draw.SimpleText(BATM.Lang["Request failed, check chat."], "batm_done_text", ScrW/2, ScrH - 150, Color(0,0,0,255), 1)

	--Draw the cursor
	BATM.Scenes["cursor"].Draw(ent, ScrW, ScrH)

end

--Think code (dt = FrameTime())
function scene.Think(ent, dt)

end

--Called when the scene is unloaded
function scene.Unload(ent, newSceneName)

end

--Register the scene
BATM.RegisterScene(scene, "failed")
