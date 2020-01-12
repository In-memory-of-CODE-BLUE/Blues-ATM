--[[-------------------------------------------------------------------------
This scene should be set before anything that requires waiting on networking
---------------------------------------------------------------------------]]


surface.CreateFont( "batm_loading_text", {
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

local loading = Material("bluesatm/loading.png", "noclamp smooth")

--Called when the scene is loaded
function scene.Load(ent)

end 

--Draw code
function scene.Draw(ent, ScrW, ScrH)
 
	--Draw the background
	BATM.Scenes["background"].Draw(ent, ScrW, ScrH) 

	--Draw background
	--draw.RoundedBox(0, 0, 100, ScrW, ScrH - 100, Color(231, 126, 34,255))

	--Draw logo
	surface.SetDrawColor(Color(255,255,255,50))
	surface.SetMaterial(loading)
	surface.DrawTexturedRectRotated(ScrW/2, ScrH/2, 256, 256, CurTime() * -100)

	--Draw text
	draw.SimpleText(BATM.Lang["Loading..."], "batm_done_text", ScrW/2, ScrH - 150, Color(255,255,255,100), 1)

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
BATM.RegisterScene(scene, "loading")