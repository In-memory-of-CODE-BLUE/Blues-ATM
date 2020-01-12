--[[-------------------------------------------------------------------------
Draws the last 20 transactions of an account
---------------------------------------------------------------------------]]

surface.CreateFont( "batm_history_large", {
	font = "Roboto",
	extended = false,
	size = 35,
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

surface.CreateFont( "batm_history_med", {
	font = "Coolvetica",
	extended = false,
	size = 32,
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


surface.CreateFont( "batm_history_small", {
	font = "Coolvetica",
	extended = false,
	size = 30,
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
scene.page = 1
local ScrW = 1024 
local ScrH = 676
--Called when the scene is loaded
function scene.Load(ent)
	scene.page = 1 --Reset page

	--Previous buttons
	ent:AddButton(ScrW/2 - 350, 585, 150, 50, 
		function() --On Pressed
			if scene.page == 2 then
				scene.page = 1
			end
		end
	)

	--Next buttons
	ent:AddButton(ScrW/2 + 350 - 150, 585, 150, 50,
		function() --On Pressed
			local account = BATM.GetActiveAccount()
			if account ~= nil and account.balanceHistory[11] ~= nil and scene.page == 1  then
				scene.page = 2
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

local back = Material("bluesatm/back.png", "noclamp smooth")

--Draw code
function scene.Draw(ent, ScrW, ScrH)

	local account = BATM.GetActiveAccount()
	if account == nil then return end --This should not happen but just incase

	--Draw the background
	BATM.Scenes["background"].Draw(ent, ScrW, ScrH)

	--Draw back button
	surface.SetDrawColor(Color(255,255,255,100))
	surface.SetMaterial(back)
	surface.DrawTexturedRect(35, 135, 64, 64)

	local yOffset = 135

	--Show previous history
	for i = 1 , 10 do
		local index = i
		if scene.page == 2 then
			index = i + 10
		end

		--Skip if no history exists
		if account.balanceHistory[index] == nil then continue end

		--draw a transaction
		local color = Color(52, 73, 94)
		if i%2 == 0 then
			color = Color(52 * 1.1, 73 * 1.1, 94 * 1.1)
		end
		draw.RoundedBox(0,ScrW/2 - 350, yOffset, 700, 40, color)
		local text = ""

		if account.balanceHistory[index].amount < 0 then
			text = "-"..BATM.Lang["$"]
			color = Color(246 * 1.2, 41 * 1.2, 80 * 1.2)
		else 
			color = Color(100,200,120)
			text = "+"..BATM.Lang["$"]
		end

		text = text..CBLib.Helper.CommaFormatNumber(math.abs(account.balanceHistory[index].amount))
		draw.SimpleText(text, "batm_history_large",ScrW/2 - 350 + 10, yOffset + 20, color, 0, 1)
		draw.SimpleText(account.balanceHistory[index].description, "batm_history_small",ScrW/2 + 350 - 10, yOffset + 20, Color(255,255,255, 100), 2, 1)
		--add to offset
		yOffset = yOffset + 45
	end

	--Draw next and previous buttons
	if scene.page == 2 then 
		draw.RoundedBox(0, ScrW/2 - 350, 585, 150, 50,Color(52, 73, 94))
		draw.SimpleText(BATM.Lang["Previous"], "batm_history_med",ScrW/2 - 350 + 75, 585 + 25, Color(255,255,255,220), 1, 1)
	else
		draw.RoundedBox(0, ScrW/2 - 350, 585, 150, 50,Color(52, 73, 94, 80))
		draw.SimpleText(BATM.Lang["Previous"], "batm_history_med",ScrW/2 - 350 + 75, 585 + 25, Color(255,255,255,30), 1, 1)
	end

	if account.balanceHistory[11] ~= nil and scene.page == 1 then 
		draw.RoundedBox(0, ScrW/2 + 350 - 150, 585, 150, 50,Color(52, 73, 94))
		draw.SimpleText(BATM.Lang["Next"], "batm_history_med",ScrW/2 + 350 - 75, 585 + 25, Color(255,255,255,220), 1, 1)
	else
		draw.RoundedBox(0, ScrW/2 + 350 - 150, 585, 150, 50,Color(52, 73, 94, 80))
		draw.SimpleText(BATM.Lang["Next"], "batm_history_med",ScrW/2 + 350 - 75, 585 + 25, Color(255,255,255,30), 1, 1)
	end


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
BATM.RegisterScene(scene, "history")
