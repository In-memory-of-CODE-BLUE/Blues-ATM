--[[-------------------------------------------------------------------------
Draws all the members, and if your the account owner then you can kick or add new members
---------------------------------------------------------------------------]]

surface.CreateFont( "batm_transfer_large", {
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

surface.CreateFont( "batm_transfer_med", {
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


surface.CreateFont( "batm_transfer_small", {
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

scene.selectedIndex = -1 --Selected index, -1 means none

--Called when the scene is loaded
function scene.Load(ent)

	scene.selectedIndex = -1 --Reset selected user
	scene.page = 1 --Reset page
	scene.maxpage = 1

	scene.SetUpButton(ent)
end


--This is used so that when the user changes page we can clear the buttons and re-create them
function scene.SetUpButton(ent)
	local account = BATM.GroupAccount

	if account == nil then return end --This should not happen but just incase
	if account.IsGroup == false then return end --Should not happen either

	scene.maxpage = math.ceil(table.Count(account.owners) / 10)

	ent:ClearButtons()

	--Kick user button
	ent:AddButton(ScrW/2 - 185, 585, 180, 50,
		function() --On pressed
			if scene.selectedIndex ~= -1 then
				ent:SetScene("loading")
				timer.Simple(1, function()
					local account = BATM.GetActiveAccount()
					local id = account.owners[scene.selectedIndex]
					BATM.KickUser(ent, id)
				end)
			end
		end
	)

	--Add user button
	ent:AddButton(ScrW/2 + 8, 585, 180, 50,
		function() --On pressed
			ent:SetScene("addmember")
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
			local account = BATM.GetActiveAccount()
			if scene.page < scene.maxpage  then
				scene.page = scene.page + 1
				scene.SetUpButton(ent)
			end
		end
	)

	--back button
	ent:AddButton(35, 135, 64, 64, 
		function() --On pressed
			ent:SetScene("groupaccount")
		end
	)

	--Now add the buttons for the acctualy rows
	local yOffset = 135
	local players = account.owners 
	--Show previous history

	for i = 1 , 10 do
		local index = ((scene.page - 1) * 10) + i

		--Skip if no history exists
		if players[index] == nil then continue end

		--Add the button
		ent:AddButton(ScrW/2 - 350, yOffset, 700, 40, function()
			scene.selectedIndex = index
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

	scene.maxpage = math.ceil(table.Count(account.owners) / 10)

	if scene.page > scene.maxpage then scene.page = scene.maxpage end --Dont allow pages that dont exist

	--Draw the background
	BATM.Scenes["background"].Draw(ent, ScrW, ScrH)

	--Draw back button
	surface.SetDrawColor(Color(255,255,255,100))
	surface.SetMaterial(back)
	surface.DrawTexturedRect(35, 135, 64, 64)

	local yOffset = 135
	local players = account.owners
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

		if scene.selectedIndex == index then
			color = Color(43, 152, 35)
		end

		draw.RoundedBox(0,ScrW/2 - 350, yOffset, 700, 40, color)

		draw.SimpleText(account.ownerNames[tostring(players[index])], "batm_transfer_large",ScrW/2 - 350 + 10, yOffset + 20, Color(255,255,255, 230), 0, 1)
		draw.SimpleText(players[index] or "????????????????", "batm_transfer_small",ScrW/2 + 350 - 10, yOffset + 20, Color(255,255,255, 100), 2, 1)

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

	--Kick user button
	if BATM.SelectedAccount == "personalgroup" and scene.selectedIndex ~= -1 then
		draw.RoundedBox(0, ScrW/2 - 185, 585, 180, 50,Color(170, 70, 40, 255))
		draw.SimpleText(BATM.Lang["Kick User"], "batm_history_med",ScrW/2 - 95, 585 + 25, Color(255,255,255,220), 1, 1)
	elseif BATM.SelectedAccount == "personalgroup" then
		draw.RoundedBox(0, ScrW/2 - 185, 585, 180, 50,Color(52, 73, 94, 80))
		draw.SimpleText(BATM.Lang["Kick User"], "batm_history_med",ScrW/2 - 95, 585 + 25, Color(255,255,255,30), 1, 1)
	end

	--Add User button
	if BATM.SelectedAccount == "personalgroup" then
		draw.RoundedBox(0, ScrW/2 + 8, 585, 180, 50,Color(52, 73, 94))
		draw.SimpleText(BATM.Lang["Add User"], "batm_history_med",ScrW/2 + 98, 585 + 25, Color(255,255,255,220), 1, 1)
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
BATM.RegisterScene(scene, "members")
