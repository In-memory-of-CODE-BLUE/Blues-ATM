include("shared.lua")

surface.CreateFont( "batm_reader_med", {
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

surface.CreateFont( "batm_reader_med2", {
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


surface.CreateFont( "batm_reader_small", {
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



surface.CreateFont( "batm_reader_smallest", {
	font = "Coolvetica",
	extended = false,
	size = 42,
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

surface.CreateFont( "batm_reader_smallester", {
	font = "Coolvetica",
	extended = false,
	size = 38,
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

surface.CreateFont( "batm_reader_smallesterer", {
	font = "Coolvetica",
	extended = false,
	size = 25,
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


--The X resolution of the screen
local ScrW = 512
local ScrH = 469

--Set up the entity and its render targts and materials
function ENT:Initialize()
	self.screenMaterial = CreateMaterial("blueatm_cardreaderscreenmat_"..self:EntIndex(), "UnlitGeneric", {})
	self.renderTarget = GetRenderTarget("blueatm_cardreaderscreenmat_"..self:EntIndex(), 512, 512, false)

	self.screenMaterial:SetTexture('$basetexture', self.renderTarget)
end


local logo = Material("bluesatm/logo.png", "noclamp smooth")
local scroll = Material("bluesatm/color_strip.vmt")
local failed = Material("bluesatm/failed.png", "noclamp smooth")

--CBLib.Helper.WrapText(Str,font,width)
--Draw the model and call the screen rendering functions.
function ENT:RenderScreen()
	if self:GetPos():Distance(LocalPlayer():GetPos()) < 300 and BATM.ScreenDisabled == false then
		--Draw the screen
		render.PushRenderTarget(self.renderTarget)
			render.Clear(0,0,0,0,true,true) 
			cam.Start2D()
					
			draw.RoundedBox(0, 0, 0, ScrW, ScrH, Color(52, 73, 94))--Color(45, 62, 80))

			if self:GetItemPrice() == -1 then
			    --Draw background
				draw.SimpleText(BATM.Lang["Press 'E' to set up!"], "batm_reader_med2", ScrW/2, ScrH/2 , Color(255,255,255), 1, 1)
			else

				draw.SimpleText(BATM.Lang["$"]..CBLib.Helper.CommaFormatNumber(self:GetItemPrice()), "batm_reader_med", ScrW/2, 45 , Color(255,255,255), 1, 1)
				draw.SimpleText(self:GetItemTitle(), "batm_reader_small", ScrW/2, 110 , Color(255,255,255), 1, 1)

				draw.RoundedBox(0, 25, 150, ScrW - 50, ScrH - 175, Color(45, 62, 80))

				--200 character count limit
				local description = self:GetItemDescription()

				local lines = CBLib.Helper.WrapText(description,"batm_reader_smallest",ScrW - 25 - 50)

				local yOffset = 0

				for k ,v in pairs(lines) do
					draw.SimpleText(v,"batm_reader_smallest",30 + ((ScrW-58)/2),155 + yOffset, Color(255,255,255), 1)
					yOffset = yOffset + 30
				end
			end

			cam.End2D()
		render.PopRenderTarget()

		--Update material texture

		self.screenMaterial:SetTexture('$basetexture', self.renderTarget)
		self:SetSubMaterial(4, "!blueatm_cardreaderscreenmat_"..self:EntIndex())
	end

end

function ENT:Draw()
	self:RenderScreen()
	self:DrawModel()
end

--Handle scene thinks
function ENT:Think()

end

local frameReference = nil

--For owners to set up the machine
function ENT:ShowSetupWindow()
	if frameReference ~= nil then return end

	local frame = vgui.Create("DFrame")
	frame:SetSize(300, 440)
	frame:SetTitle("")
	frame:Center()
	frame:ShowCloseButton(false)
	frame:SetVisible(true)
	frame:MakePopup()
	frame.Close = function(s)
		frameReference = nil
		s:Remove()
	end

	frameReference = frame

	frame.Paint = function(s , w , h)
		draw.RoundedBox(0, 0, 0, ScrW, ScrH, Color(45, 62, 80))
		draw.RoundedBox(0, 0, 50, ScrW, ScrH, Color(52, 73, 94))

		surface.SetDrawColor(Color(255,255,255))
		surface.SetMaterial(logo)
		surface.DrawTexturedRect(-4, 5, 1024 / 4.5, 199 / 4.5)
	end

	--Close button
	local close = vgui.Create("DButton", frame)
	close:SetPos(300 - 40, 7)
	close:SetSize(32, 32)
	close:SetText("")
	close.DoClick = function()
		frame:Close()
	end
	close.Paint = function(s , w , h)
		surface.SetDrawColor(Color(255,255,255,100))
		surface.SetMaterial(failed)
		surface.DrawTexturedRect(0,0,w,h)
	end

	local inputPrice = vgui.Create("DTextEntry", frame)
	inputPrice:SetPos(20, 70)
	inputPrice:SetSize(300 - 40, 40)
	inputPrice:SetFont("batm_reader_small")

	inputPrice.Paint = function(s, w, h)
		draw.RoundedBox(0,0,0,w,h,Color(255,255,255,255))
		s:DrawTextEntryText(Color(120,120,120,200), Color(0,0,0,255), Color(120,120,120,255))

		if s:GetText() == "" then
			draw.SimpleText(BATM.Lang["Enter Price"],"batm_reader_small",5, 0, Color(120,120,120,200))
		end
	end

	local inputTitle = vgui.Create("DTextEntry", frame)
	inputTitle:SetPos(20, 70 + 50)
	inputTitle:SetSize(300 - 40, 40)
	inputTitle:SetFont("batm_reader_small")

	inputTitle.Paint = function(s, w, h)
		draw.RoundedBox(0,0,0,w,h,Color(255,255,255,255))
		s:DrawTextEntryText(Color(120,120,120,200), Color(0,0,0,255), Color(120,120,120,255))

		if s:GetText() == "" then
			draw.SimpleText(BATM.Lang["Enter Title"],"batm_reader_small",5, 0, Color(120,120,120,200))
		end
	end

	local inputDesc = vgui.Create("DTextEntry", frame)
	inputDesc:SetPos(20, 70 + 50 + 50)
	inputDesc:SetSize(300 - 40, 200)
	inputDesc:SetFont("batm_reader_smallesterer")
	inputDesc:SetMultiline(true)

	inputDesc.Paint = function(s, w, h)
		draw.RoundedBox(0,0,0,w,h,Color(255,255,255,255))
		s:DrawTextEntryText(Color(120,120,120,200), Color(0,0,0,255), Color(120,120,120,255))

		if s:GetText() == "" then
			draw.SimpleText(BATM.Lang["Enter Description"],"batm_reader_smallester",5, 0, Color(120,120,120,200))
		end
	end

	local submit = vgui.Create("DButton", frame)
	submit:SetPos(20, 70 + 50 + 50 + 200 + 10)
	submit:SetSize(300 - 40, 40)
	submit:SetFont("batm_reader_smallest")
	submit:SetTextColor(Color(255,255,255,255))
	submit:SetText(BATM.Lang["Submit"])
	submit.Paint = function(s , w , h)
		draw.RoundedBox(0,0,0,w,h,Color(49, 209, 60))
	end
	submit.DoClick = function(s)
		local amount = tonumber(inputPrice:GetText())
		local title = inputTitle:GetText()
		local desc = inputDesc:GetText()

		net.Start("batm_reader_edit")
			net.WriteDouble(amount or 0)
			net.WriteString(title)
			net.WriteString(desc)
			net.WriteEntity(self)
		net.SendToServer()

		frame:Close()
	end
end
 
--For customers to purchase shit
function ENT:ShowPurchaseWindow()
	if frameReference ~= nil then return end

	local frame = vgui.Create("DFrame")
	frame:SetSize(300, 200) 
	frame:SetTitle("")
	frame:Center()
	frame:ShowCloseButton(false)
	frame:SetVisible(true)
	frame:MakePopup()
	frame.Close = function(s)
		frameReference = nil
		s:Remove()
	end

	frameReference = frame

	frame.Paint = function(s , w , h)
		draw.RoundedBox(0, 0, 0, ScrW, ScrH, Color(45, 62, 80))
		draw.RoundedBox(0, 0, 50, ScrW, ScrH, Color(52, 73, 94))

		surface.SetDrawColor(Color(255,255,255))
		surface.SetMaterial(logo)
		surface.DrawTexturedRect(-4, 5, 1024 / 4.5, 199 / 4.5)

		draw.SimpleText(BATM.Lang["$"]..CBLib.Helper.CommaFormatNumber(self:GetItemPrice()),"batm_reader_small",w/2, 60, Color(255,255,255,255), 1)
		draw.SimpleText(BATM.Lang["Seller : "]..self:GetReaderOwner():Name(),"batm_reader_smallesterer",w/2, 105, Color(255,255,255,255), 1)
	end

	--Close button
	local close = vgui.Create("DButton", frame)
	close:SetPos(300 - 40, 7)
	close:SetSize(32, 32)
	close:SetText("")
	close.DoClick = function()
		frame:Close()
	end
	close.Paint = function(s , w , h)
		surface.SetDrawColor(Color(255,255,255,100))
		surface.SetMaterial(failed)
		surface.DrawTexturedRect(0,0,w,h)
	end

	local purchase = vgui.Create("DButton", frame)
	purchase:SetPos(20, 140)
	purchase:SetSize(300 - 40, 40)
	purchase:SetFont("batm_reader_smallest")
	purchase:SetTextColor(Color(255,255,255,255))
	purchase:SetText(BATM.Lang["Purchase"])
	purchase.Paint = function(s , w , h)
		draw.RoundedBox(0,0,0,w,h,Color(49, 209, 60))
	end
	purchase.DoClick = function(s) 
		net.Start("batm_reader_purchase")
			net.WriteEntity(self)
		net.SendToServer()

		frame:Close()
	end
end

--Call the correct function
net.Receive("batm_reader_purchase", function()
	local ent = net.ReadEntity()
	if ent ~= nil then
		if ent:GetItemPrice() == -1 then
			LocalPlayer():ChatPrint(BATM.Lang["[ATM] The owner has not yet set up this device"])
		else
			ent:ShowPurchaseWindow()
		end
	end
end)

--Call the correctl function
net.Receive("batm_reader_edit", function()
	local ent = net.ReadEntity()
	if ent ~= nil then
		ent:ShowSetupWindow()
	end
end)

