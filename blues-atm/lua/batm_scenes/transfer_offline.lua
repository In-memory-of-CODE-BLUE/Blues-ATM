--[[-------------------------------------------------------------------------
Enter the steamid 64 of the user you are transfering too
---------------------------------------------------------------------------]]

surface.CreateFont( "batm_tranfer_amount_title", {
	font = "Coolvetica",
	extended = false,
	size = 70,
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

surface.CreateFont( "batm_tranfer_amount_text", {
	font = "Coolvetica",
	extended = false,
	size = 65,
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

scene.enteredAmount = 0

local ScrW = 1024
local ScrH = 676

--The player we are targeting
scene.targetPlayer = nil
scene.targetPlayerName = "ERROR"

--Called when the scene is loaded
function scene.Load(ent)
	scene.enteredAmount = "" --Reset it
 
	--done button
	ent:AddButton(ScrW/2 - 300, ScrH / 2 + 110, 600, 90, 
		function() --On pressed
			BATM.Scenes["transfer_amount"].targetPlayer = scene.enteredAmount
			BATM.Scenes["transfer_amount"].targetPlayerName = scene.enteredAmount
			ent:SetScene("transfer_amount")
		end
	)

	--back button
	ent:AddButton(35, 135, 64, 64, 
		function() --On pressed
			ent:SetScene("transfer")
		end
	)
end

--Called when a user presses a button on the
function scene.OnKeypadPressed(ent, button)
	--Now lets make sure its not zero
	if isnumber(button) then
		--Append it
		local stringAmount = scene.enteredAmount
		if string.len(stringAmount) > 20 then return end --Prevent overflow
		stringAmount = stringAmount..button

		scene.enteredAmount = stringAmount

		return
	end

	if button == "clear" then
		if scene.enteredAmount ~= "" then
			local stringAmount = scene.enteredAmount
			stringAmount = string.sub(stringAmount, 1, string.len(stringAmount) - 1)
			if stringAmount == nil then
				stringAmount = ""
			end
			scene.enteredAmount = stringAmount
			return
		end
	end 

	if button == "enter" then
		BATM.Scenes["transfer_amount"].targetPlayer = scene.enteredAmount
		BATM.Scenes["transfer_amount"].targetPlayerName = scene.enteredAmount
		ent:SetScene("transfer_amount")
	end
end

local back = Material("bluesatm/back.png", "noclamp smooth")

--Draw code
function scene.Draw(ent, ScrW, ScrH)

	--Draw the background
	BATM.Scenes["background"].Draw(ent, ScrW, ScrH)

	--Draw back button
	surface.SetDrawColor(Color(255,255,255,100))
	surface.SetMaterial(back)
	surface.DrawTexturedRect(35, 135, 64, 64)

	--Draw title
	draw.SimpleText(BATM.Lang["Enter Users "], "batm_tranfer_amount_title", ScrW/2, 155, Color(233,233,233,255), 1)
	draw.SimpleText(BATM.Lang["SteamID64"], "batm_tranfer_amount_title", ScrW/2, 155 + 65, Color(233,233,233,255), 1)
	--Deposite box
	draw.RoundedBox(0, ScrW/2 - 300, ScrH / 2, 600, 90, Color(255,255,255,255))
	if scene.enteredAmount == "" then
		draw.SimpleText(BATM.Lang["Enter SteamID64"], "batm_tranfer_amount_text", ScrW/2, (ScrH/2) + 45, Color(194,194,194,255), 1, 1)
	else
		draw.SimpleText(scene.enteredAmount, "batm_tranfer_amount_text", ScrW/2, (ScrH/2) + 45, Color(194,194,194,255), 1, 1)
	end

	--Draw done button
	draw.RoundedBox(0, ScrW/2 - 300, ScrH / 2 + 110, 600, 90, Color(231, 126, 34,255))
	draw.SimpleText(BATM.Lang["Done"], "batm_tranfer_amount_text", ScrW/2, (ScrH/2) + 110 + 45, Color(255,255,255,255), 1, 1)

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
BATM.RegisterScene(scene, "transfer_offline")
