--[[-------------------------------------------------------------------------
Draws the deposit screen
---------------------------------------------------------------------------]]

surface.CreateFont( "batm_deposite_title", {
	font = "Coolvetica",
	extended = false,
	size = 100,
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

surface.CreateFont( "batm_deposite_text", {
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
--Called when the scene is loaded
function scene.Load(ent)
	scene.enteredAmount = 0 --Reset it

	--done button
	ent:AddButton(ScrW/2 - 300, ScrH / 2 + 110, 600, 90, 
		function() --On pressed
			if BATM.VerifyNumber(scene.enteredAmount) then
				ent:SetScene("loading")
				BATM.Deposit(ent, scene.enteredAmount or 0)
			end
		end
	)

	--back button
	ent:AddButton(35, 135, 64, 64, 
		function() --On pressed
			if BATM.SelectedAccount == "personal" then
				ent:SetScene("personalaccount")
			else
				ent:SetScene("groupaccount")
			end
		end
	)
end

--Called when a user presses a button on the
function scene.OnKeypadPressed(ent, button)
	--Now lets make sure its not zero
	if isnumber(button) then
		--Append it
		local stringAmount = tostring(scene.enteredAmount)
		if string.len(stringAmount) > 13 then return end --Prevent overflow
		stringAmount = stringAmount..button

		if tonumber(stringAmount) == 0 then return end

		scene.enteredAmount = tonumber(stringAmount)

		return
	end

	if button == "clear" then
		if scene.enteredAmount ~= 0 then
			local stringAmount = tostring(scene.enteredAmount)
			stringAmount = string.sub(stringAmount, 1, string.len(stringAmount) - 1)
			if tonumber(stringAmount) == nil or tonumber(stringAmount) < 0 then
				stringAmount = "0"
			end
			scene.enteredAmount = tonumber(stringAmount)
			return
		end
	end

	if button == "enter" then
		if BATM.VerifyNumber(scene.enteredAmount) then
			ent:SetScene("loading")
			BATM.Deposit(ent, scene.enteredAmount or 0)
		end
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
	draw.SimpleText(BATM.Lang["Deposit"], "batm_deposite_title", ScrW/2, 155, Color(233,233,233,255), 1)

	--Deposite box
	draw.RoundedBox(0, ScrW/2 - 300, ScrH / 2, 600, 90, Color(255,255,255,255))
	if scene.enteredAmount == 0 then
		draw.SimpleText(BATM.Lang["Enter Amount"], "batm_deposite_text", ScrW/2, (ScrH/2) + 45, Color(194,194,194,255), 1, 1)
	else
		draw.SimpleText(BATM.Lang["$"]..CBLib.Helper.CommaFormatNumber(scene.enteredAmount), "batm_deposite_text", ScrW/2, (ScrH/2) + 45, Color(194,194,194,255), 1, 1)
	end

	--Draw done button
	draw.RoundedBox(0, ScrW/2 - 300, ScrH / 2 + 110, 600, 90, Color(231, 126, 34,255))
	draw.SimpleText(BATM.Lang["Done"], "batm_deposite_text", ScrW/2, (ScrH/2) + 110 + 45, Color(255,255,255,255), 1, 1)

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
BATM.RegisterScene(scene, "deposit")
