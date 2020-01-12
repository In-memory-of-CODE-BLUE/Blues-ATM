--[[-------------------------------------------------------------------------
Draws the home screen, with aniamted lights, logo and some infomation for personal groups accounts
---------------------------------------------------------------------------]]
surface.CreateFont( "batm_small", {
	font = "Roboto", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 45,
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

surface.CreateFont( "batm_accountselect_title_personalaccount", {
	font = "Coolvetica",
	extended = false,
	size = 75,
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

surface.CreateFont( "batm_personalaccount_button", {
	font = "Coolvetica",
	extended = false,
	size = 65,
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


local scene = {}
local ScrW = 1024 
local ScrH = 676
--Called when the scene is loaded
function scene.Load(ent)
	--deposit
	ent:AddButton(ScrW * 0.14,285,ScrW * 0.35, ScrH * 0.15, 
		function() --On pressed
			ent:SetScene("deposit")
		end
	)

	--history
	ent:AddButton(ScrW - ScrW * 0.35 - ScrW * 0.14,285,ScrW * 0.35, ScrH * 0.15, 
		function() --On pressed
			ent:SetScene("history")
		end
	)

	--Withdraw button
	ent:AddButton(ScrW * 0.14, ScrW * 0.4,ScrW * 0.35, ScrH * 0.15, 
		function() --On pressed
			ent:SetScene("withdraw")
		end
	)

	--Members button
	ent:AddButton(ScrW - ScrW * 0.35 - ScrW * 0.14,ScrW * 0.4,ScrW * 0.35, ScrH * 0.15, 
		function() --On pressed
			ent:SetScene("members")
		end
	)

	--back button
	ent:AddButton(35, 135, 64, 64, 
		function() --On pressed
			ent:SetScene("accountselection")
		end
	)	
end 

--Called when a user presses a button on the
function scene.OnKeypadPressed(ent, button)

end 

local back = Material("bluesatm/back.png", "noclamp smooth")
local arrow = Material("bluesatm/arrow.png", "noclamp smooth")
local deposit = Material("bluesatm/deposit.png", "noclamp smooth")
local withdraw = Material("bluesatm/withdraw.png", "noclamp smooth")
local history = Material("bluesatm/history.png", "noclamp smooth")
local group = Material("bluesatm/group.png", "noclamp smooth")

--Draw code
function scene.Draw(ent, ScrW, ScrH)
 
	local account = BATM.GetActiveAccount()

	if account == false or not account.IsGroup then return end --Dont draw, big boi error

	--Draw the background
	BATM.Scenes["background"].Draw(ent, ScrW, ScrH)

	--Draw back button
	surface.SetDrawColor(Color(255,255,255,100))
	surface.SetMaterial(back)
	surface.DrawTexturedRect(35, 135, 64, 64)

	--Draw title
	draw.SimpleText(BATM.Lang["What would you like to do?"], "batm_accountselect_title_personalaccount", ScrW/2, 140, Color(255,255,255,255), 1)

	--Draw personal account button
	draw.RoundedBox(0,ScrW * 0.14,285,ScrW * 0.35, ScrH * 0.15, Color(231, 126, 34))
	draw.SimpleText(BATM.Lang["Deposit"], "batm_personalaccount_button",ScrW * 0.15, 285 + (ScrH * 0.15 / 2), Color(255,255,255,255), 0, 1)
	surface.SetDrawColor(255, 255, 255, 200)
	surface.SetMaterial(deposit) 
	surface.DrawTexturedRect( ScrW * 0.14 + ScrW * 0.275, 285 + 22, 56, 44 )

	draw.RoundedBox(0,ScrW - ScrW * 0.35 - ScrW * 0.14,285,ScrW * 0.35, ScrH * 0.15, Color(50, 151, 219))
	draw.SimpleText(BATM.Lang["History"], "batm_personalaccount_button",ScrW - ScrW * 0.35 - ScrW * 0.14 + ScrW * 0.01, 285 + (ScrH * 0.15 / 2), Color(255,255,255,255), 0, 1)
	surface.SetDrawColor(255, 255, 255, 200)
	surface.SetMaterial(history) 
	surface.DrawTexturedRect(ScrW - ScrW * 0.35 - ScrW * 0.14 + ScrW * 0.275, 285 + 22, 56, 44 )


	draw.RoundedBox(0,ScrW * 0.14, ScrW * 0.4,ScrW * 0.35, ScrH * 0.15, Color(45, 204, 112))
	draw.SimpleText(BATM.Lang["Withdraw"], "batm_personalaccount_button",ScrW * 0.15, ScrW * 0.4 + (ScrH * 0.15 / 2), Color(255,255,255,255), 0, 1)
	surface.SetDrawColor(255, 255, 255, 200)
	surface.SetMaterial(withdraw) 
	surface.DrawTexturedRect( ScrW * 0.14 + ScrW * 0.275, ScrW * 0.4 + 22, 56, 44 )

	draw.RoundedBox(0,ScrW - ScrW * 0.35 - ScrW * 0.14,ScrW * 0.4,ScrW * 0.35, ScrH * 0.15, Color(232, 76, 61))
	draw.SimpleText(BATM.Lang["Members"], "batm_personalaccount_button",ScrW - ScrW * 0.35 - ScrW * 0.14 + ScrW * 0.01, ScrW * 0.4 + (ScrH * 0.15 / 2), Color(255,255,255,255), 0, 1)
	surface.SetDrawColor(255, 255, 255, 200)
	surface.SetMaterial(group) 
	surface.DrawTexturedRect( ScrW - ScrW * 0.35 - ScrW * 0.14 + ScrW * 0.275, ScrW * 0.4 + 22, 56, 44 )

	draw.SimpleText(BATM.Lang["$"]..CBLib.Helper.CommaFormatNumber(account.balance), "batm_personalaccount_button", ScrW / 2, ScrH * 0.88, Color(255,255,255,255), 1, 1)

	BATM.Scenes["cursor"].Draw(ent, ScrW, ScrH)

end 

--Think code (dt = FrameTime())
function scene.Think(ent, dt)

end

--Called when a the scene is unloaded
function scene.Unload(ent, newSceneName)

end

--Register the scene
BATM.RegisterScene(scene, "groupaccount")