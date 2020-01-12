--[[-------------------------------------------------------------------------
Allows you to select a member to add to your group
---------------------------------------------------------------------------]]

surface.CreateFont( "batm_addmember_small", {
	font = "Coolvetica",
	extended = false,
	size = 45,
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
	scene.maxpage = math.ceil(player.GetCount() / 10)

	scene.SetUpButton(ent)
end

--This is used so that when the user changes page we can clear the buttons and re-create them
function scene.SetUpButton(ent)
	ent:ClearButtons()

	--Offline user button
	ent:AddButton(ScrW/2 - 100, 585, 200, 50,
		function() --On pressed
			ent:SetScene("transfer_offline")
		end
	)

	--Previous buttons
	ent:AddButton(ScrW/2 - 350, 585, 150, 50, 
		function() --On Pressed
			if scene.page > 1 then
				scene.page = scene.page - 1
				scene.SetUpButton(ent) --setup buttons
			end
		end
	)

	--Next buttons
	ent:AddButton(ScrW/2 + 350 - 150, 585, 150, 50,
		function() --On Pressed
			if scene.page < scene.maxpage  then
				scene.page = scene.page + 1
				scene.SetUpButton(ent) --setup buttons
			end
		end
	)

	--back button
	ent:AddButton(35, 135, 64, 64, 
		function() --On pressed
			ent:SetScene("members")
		end
	)

	--Now add the buttons for the acctualy rows
	local yOffset = 135
	local players = player.GetAll()
	--Show previous history
	for i = 1 , 10 do
		local index = ((scene.page -1) * 10) + i

		--Skip if no history exists
		if players[index] == nil then continue end
 
		--Add the button
		ent:AddButton(ScrW/2 - 350, yOffset, 700, 40, function()
			local ply = players[index]
			--Attempt to add this member
			
			ent:SetScene("loading")
			timer.Simple(1, function()
				BATM.AddUser(ent, ply)
			end)
		end)

		--add to offset
		yOffset = yOffset + 45
	end 
end

local back = Material("bluesatm/back.png", "noclamp smooth")

--Draw code
function scene.Draw(ent, ScrW, ScrH)

	local account = BATM.GetActiveAccount()
	if account == nil then return end --This should not happen but just incase

	scene.maxpage = math.ceil(player.GetCount() / 10)
	if scene.page > scene.maxpage then scene.page = scene.maxpage end --Dont allow pages that dont exist

	--Draw the background
	BATM.Scenes["background"].Draw(ent, ScrW, ScrH)

	--Draw back button
	surface.SetDrawColor(Color(255,255,255,100))
	surface.SetMaterial(back)
	surface.DrawTexturedRect(35, 135, 64, 64)

	draw.SimpleText(BATM.Lang["Select a user to add."],"batm_addmember_small", ScrW/2, 585 + 25, Color(255,255,255,255),1, 1)

	local yOffset = 135
	local players = player.GetAll()
	--Show previous history
	for i = 1 , 10 do
		local index = ((scene.page -1) * 10) + i

		--Skip if no history exists
		if players[index] == nil then continue end

		--draw a transaction
		local color = Color(52, 73, 94)
		if i%2 == 0 then
			color = Color(52 * 1.1, 73 * 1.1, 94 * 1.1)
		end
		draw.RoundedBox(0,ScrW/2 - 350, yOffset, 700, 40, color)

		draw.SimpleText(players[index]:Name(), "batm_transfer_large",ScrW/2 - 350 + 10, yOffset + 20, Color(255,255,255, 230), 0, 1)
		draw.SimpleText("#"..(players[index]:SteamID64() or "????????????????"), "batm_transfer_small",ScrW/2 + 350 - 10, yOffset + 20, Color(255,255,255, 100), 2, 1)

		--add to offset
		yOffset = yOffset + 45
	end 

	--Draw next and previous buttons
	if scene.page > 1 then 
		draw.RoundedBox(0, ScrW/2 - 350, 585, 150, 50,Color(52, 73, 94))
		draw.SimpleText(BATM.Lang["Previous"], "batm_transfer_med",ScrW/2 - 350 + 75, 585 + 25, Color(255,255,255,220), 1, 1)
	else
		draw.RoundedBox(0, ScrW/2 - 350, 585, 150, 50,Color(52, 73, 94, 80))
		draw.SimpleText(BATM.Lang["Previous"], "batm_history_med",ScrW/2 - 350 + 75, 585 + 25, Color(255,255,255,30), 1, 1)
	end

	if scene.page < scene.maxpage then 
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
BATM.RegisterScene(scene, "addmember")
