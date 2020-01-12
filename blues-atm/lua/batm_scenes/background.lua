--[[-------------------------------------------------------------------------
Draws the bluie background, and the title bar and time.
---------------------------------------------------------------------------]]

surface.CreateFont( "batm_date", {
	font = "Roboto Lt", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 35,
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

surface.CreateFont( "batm_time", {
	font = "Roboto Lt", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 35,
	weight = 50,
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

surface.CreateFont( "batm_large", {
	font = "Coolvetica", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
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

local logo = Material("bluesatm/logo.png", "noclamp smooth")

--Lerps a color
local function LerpColor(t, col1, col2)
	local newCol = Color(0,0,0,0)

	newCol.r = Lerp(t, col1.r, col2.r)
	newCol.g = Lerp(t, col1.g, col2.g)
	newCol.b = Lerp(t, col1.b, col2.b)
	newCol.a = Lerp(t, col1.a, col2.a)

	return newCol
end


local scene = {}

--Called when the scene is loaded
function scene.Load(ent)
 
end

--Add st, nd, rd or th to the end of a number
local function OrdinalNumber(n)
  local ordinal, digit = {"st", "nd", "rd"}, string.sub(n, -1)
  if tonumber(digit) > 0 and tonumber(digit) <= 3 and string.sub(n,-2) ~= 11 and string.sub(n,-2) ~= 12 and string.sub(n,-2) ~= 13 then
    return n .. ordinal[tonumber(digit)]
  else
    return n .. "th"
  end
end

--Draw code
function scene.Draw(ent, ScrW, ScrH)
 
	--Draw background
	draw.RoundedBox(0, 0, 0, ScrW, ScrH, Color(45, 62, 80))
	draw.RoundedBox(0, 0, 0, ScrW, 100, Color(52, 73, 94))
	
	--Draw the logo
	surface.SetDrawColor(Color(200,200,200,255))
	surface.SetMaterial(logo)
	surface.DrawTexturedRect(-12, 12, 1024 / 2.5, 199 / 2.5)
 	
 	--Draw date a time
 	local date = os.date("%A, %B ")
 	local dayOfTheMonth = OrdinalNumber(tonumber(os.date("%d")))
 	date = date..dayOfTheMonth

 	local time = string.upper(os.date("%I:%M %p"))

 	draw.SimpleText(date,"batm_date",ScrW - 10, 30, Color(200,200,200,255),2, 1)
  	draw.SimpleText(time,"batm_time",ScrW - 10, 60, Color(200,200,200,255),2, 1)
end

--Think code (dt = FrameTime())
function scene.Think(ent, dt)

end

--Called when a the scene is unloaded
function scene.Unload(ent, newSceneName)

end

--Register the scene
BATM.RegisterScene(scene, "background")

