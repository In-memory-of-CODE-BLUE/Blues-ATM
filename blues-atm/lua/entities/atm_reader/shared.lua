ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Card Reader"
ENT.Author = "<CODE BLUE>"
ENT.Contact = "Via Steam"
ENT.Spawnable = true
ENT.Category = "Blue's ATM"
ENT.AdminSpawnable = true 

--Vars for the screen
function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "ReaderOwner")
	self:NetworkVar("Int", 0, "ItemPrice")
	self:NetworkVar("String", 1, "ItemTitle")
	self:NetworkVar("String", 2, "ItemDescription")
end