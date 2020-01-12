--[[-------------------------------------------------------------------------
Allows the user to select between there personal account and there 
---------------------------------------------------------------------------]]
surface.CreateFont( "batm_accountselect_button", {
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

surface.CreateFont( "batm_accountselect_button_small", {
	font = "Coolvetica",
	extended = false,
	size = 55,
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

surface.CreateFont( "batm_accountselect_button_smallest", {
	font = "Coolvetica",
	extended = false,
	size = 40,
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

surface.CreateFont( "batm_accountselect_title", {
	font = "Coolvetica",
	extended = false,
	size = 100,
	weight = 500,
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

local arrow = Material("bluesatm/arrow.png", "noclamp smooth")

local scene = {}

scene.personalAccountHovered = false
scene.personalgroupAccountHovered = false

scene.pageoffset = 0

--Called when the scene is loaded
function scene.Load(ent)

	scene.pageoffset = 0

	scene.SetUpButtons(ent)

end

function scene.SetUpButtons(ent)
	local account = BATM.PersonalAccount

	ent:ClearButtons()

	--Personal account
	ent:AddButton(65, 285, 378, 345, 
		--Pressed
		function(ent)
			ent:SetScene("loading")
			timer.Simple(1, function() --Little load delay, not to much that its annoying but enough to make it look cool
				net.Start("blueatm")
				net.WriteUInt(BATM_NET_COMMANDS.selectAccount,8)
				net.WriteEntity(ent)
				net.WriteString("personal")
				net.SendToServer()

				BATM.SelectedAccount = "personal"
			end)
		end,
		--Mouse enter
		function(ent)
			scene.personalAccountHovered = true
		end,
		--Mouse Exit
		function(ent)
			scene.personalAccountHovered = false
		end
	)

	--Increate group scroll
	ent:AddButton(847, 400, 112, 106, 
		--Pressed
		function(ent)
			scene.pageoffset = scene.pageoffset - 1
			scene.SetUpButtons(ent)
		end
	)

	--Decrement group scroll
	ent:AddButton(847, 523, 112, 106, 
		--Pressed
		function(ent)
			scene.pageoffset = scene.pageoffset + 1
			scene.SetUpButtons(ent)
		end
	)

 	--Personal group
	ent:AddButton(458, 285, 504, 100, 
		--Pressed
		function(ent)
			ent:SetScene("loading")
			timer.Simple(1, function() --Little load delay, not to much that its annoying but enough to make it look cool
				net.Start("blueatm")
				net.WriteUInt(BATM_NET_COMMANDS.selectAccount,8)
				net.WriteEntity(ent)
				net.WriteString("personalgroup")
				net.SendToServer()

				BATM.SelectedAccount = "personalgroup"
			end)
		end,
		--Mouse enter
		function(ent)
			scene.personalgroupAccountHovered = true
		end,
		--Mouse Exit
		function(ent)
			scene.personalgroupAccountHovered = false
		end
	)

	--add the buttons to select a group account
		--Draw the first free groups
	if account ~= nil then

		local yOffset = 400 + 40 + 7

		if 4 + scene.pageoffset > table.Count(account.groupAccounts) then
			scene.pageoffset = 0 --Reset it
		end

		for i = 1, 4 do
			local index = i + (scene.pageoffset)

			if account.groupAccounts[index] == nil then 
				continue 
			end

			ent:AddButton(456, yOffset, 377, 40,
				function()
					ent:SetScene("loading")
					timer.Simple(1, function() --Little load delay, not to much that its annoying but enough to make it look cool
						net.Start("blueatm")
						net.WriteUInt(BATM_NET_COMMANDS.selectAccount,8)
						net.WriteEntity(ent)
						net.WriteString("group")
						net.WriteString(account.groupAccounts[index].id)
						net.SendToServer()

						BATM.SelectedAccount = "group"
					end)
				end
			)
			yOffset = yOffset +47
		end
	end
end

--Draw code
function scene.Draw(ent, ScrW, ScrH)
 
	local account = BATM.PersonalAccount

	--Draw the background
	BATM.Scenes["background"].Draw(ent, ScrW, ScrH)

	--Draw title
	draw.SimpleText(BATM.Lang["Select an account."], "batm_accountselect_title", ScrW/2, 140, Color(255,255,255,255), 1)

	--Draw personal account button
	if scene.personalAccountHovered then
		draw.RoundedBox(0,65,285,378, 345, Color(45 * 1.2, 204 * 1.2, 112 * 1.2))
	else
		draw.RoundedBox(0,65,285,378, 345, Color(45, 204, 112))
	end
	draw.SimpleText(BATM.Lang["Personal"], "batm_accountselect_button",65 + (378/2), 285 + (345/2) - 30, Color(255,255,255,255), 1, 1)
	draw.SimpleText(BATM.Lang["Account"], "batm_accountselect_button",65 + (378/2), 285 + (345/2) + 30, Color(255,255,255,255), 1, 1)

	--Draw group button
	draw.RoundedBox(0, 458, 285, 504, 100, Color(154, 89, 181))
	draw.SimpleText(BATM.Lang["My Group Account"], "batm_accountselect_button_small",458 + (504/2), 285 + (100/2), Color(255,255,255,255), 1, 1)

	--Draw group selection
	draw.RoundedBox(0, 456, 400, 377, 40, Color(50, 151, 219))
	draw.SimpleText(BATM.Lang["Other Group Accounts"], "batm_accountselect_button_smallest",456 + (377/2), 400 + (40/2), Color(255,255,255,255), 1, 1)

	--Draw the first free groups
	if account ~= nil then

		local yOffset = 400 + 40 + 7

		if 4 + scene.pageoffset > table.Count(account.groupAccounts) then
			scene.pageoffset = 0 --Reset it
		end

		for i = 1, 4 do
			local index = i + (scene.pageoffset)

			if account.groupAccounts[index] == nil then 
				continue 
			end

			local color = Color(52, 73, 94)
			if i%2 == 0 then
				color = Color(52 * 1.1, 73 * 1.1, 94 * 1.1)
			end
			draw.RoundedBox(0, 456, yOffset, 377, 40, color)
			draw.SimpleText(account.groupAccounts[index].name, "batm_accountselect_button_smallest",456 + (377/2), yOffset + (40/2), Color(255,255,255,255), 1, 1)	
			yOffset = yOffset +47
		end
	end


	--Draw group arrow (up)
	draw.RoundedBox(0, 847, 400, 112, 106, Color(231, 126, 34))
	surface.SetDrawColor(Color(255,255,255,255))
	surface.SetMaterial(arrow)
	surface.DrawTexturedRectRotated(847 + (112/2),400 + (106/2), 68, 50, 0)

	--Draw group arrow (down)
	draw.RoundedBox(0, 847, 523, 112, 106, Color(231, 126, 34))
	surface.SetDrawColor(Color(255,255,255,255))
	surface.SetMaterial(arrow)
	surface.DrawTexturedRectRotated(847 + (112/2), 523 + (106/2), 68, 50, 180)

 	--Draw the cursor position
  	BATM.Scenes["cursor"].Draw(ent, ScrW, ScrH)

end

--Think code (dt = FrameTime())
function scene.Think(ent, dt)

end

--Called when a the scene is unloaded
function scene.Unload(ent, newSceneName)

end

--Register the scene
BATM.RegisterScene(scene, "accountselection")

