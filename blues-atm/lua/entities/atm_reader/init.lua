AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

util.AddNetworkString("batm_reader_purchase")
util.AddNetworkString("batm_reader_edit")

--Account module
local Accounts = CBLib.LoadModule("batm/bm_accounts.lua", false)

--Used to set the owner, in-case its spawned from here
hook.Add("PlayerSpawnedSENT", "batm_set_owner", function(ply, ent)
	if ent:GetClass() == "atm_reader" then
		ent:UpdateOwner(ply)
	end
end)

--Darkrp
hook.Add("playerBoughtCustomEntity", "batm_set_owwner", function(ply, entT, ent, price)
	if ent:GetClass() == "atm_reader" then
		ent:UpdateOwner(ply)
	end
end)

function ENT:Initialize()
	self:SetModel("models/bluesatm/atm_reader.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType(SIMPLE_USE)
 
	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake() 
	end

	self:SetItemPrice(-1) --Means its not set up yet, so we can know weather or not to draw this infomation
end

function ENT:Think()

end

--sets or replaces the owner
function ENT:UpdateOwner(newOwner)
	self:SetReaderOwner(newOwner)
end

--Updates the info, and networks it to the client
function ENT:EditInfo(price, title, name)
	self:SetItemPrice(price)
	self:SetItemTitle(title)
	self:SetItemDescription(name)
end

--Called when someone presses e
function ENT:Use(act, ply)
	if self:GetReaderOwner() == ply then
		net.Start("batm_reader_edit")
		net.WriteEntity(self)
		net.Send(ply)
	else
		net.Start("batm_reader_purchase")
		net.WriteEntity(self)
		net.Send(ply)
	end
end

--Edit shit
net.Receive("batm_reader_edit", function(len, ply)
	local price = math.floor(net.ReadDouble())
	local title = net.ReadString()
	local desc = net.ReadString()
	local ent = net.ReadEntity()

	if ent == nil or ent:GetClass() ~= "atm_reader" then
		ply:ChatPrint(BATM.Lang["[ATM] An unknown error has occured."])
		return
	end

	title = title or ""

	if string.len(title) < 1 then
		ply:ChatPrint(BATM.Lang["[ATM] You must have a title"])
		return
	end

	if string.len(desc) < 1 then
		ply:ChatPrint(BATM.Lang["[ATM] You must have a description"])
		return
	end

	if not BATM.VerifyNumber(price) then
		ply:ChatPrint(BATM.Lang["[ATM] Invalid number..."])
		return
	end


	title = string.sub(title, 1, 20)
	desc = string.sub(desc, 1, 200)

	--Now check the owner
	if ent:GetReaderOwner() ~= ply then
		ply:ChatPrint(BATM.Lang["[ATM] Nice try buddy :)"])
		return
	end

	ent:EditInfo(price, title, desc)

	--Confirm no negative numbers
	if ent:GetItemPrice() < 1 then
		ent:EditInfo(-1, "", "")
		ply:ChatPrint(BATM.Lang["[ATM] Number to large"])
		return
	end

	ply:ChatPrint(BATM.Lang["[ATM] Info Updated"])
end)

--When the user tries to purchase it
net.Receive("batm_reader_purchase", function(len, ply)
	local ent = net.ReadEntity()

	if ent == nil or ent:GetClass() ~= "atm_reader" then
		ply:ChatPrint(BATM.Lang["[ATM] An unknown error has occured, open a support ticket please."])
		return
	end

	--First check if the entity is set up
	if ent:GetItemPrice() == -1 then
		ply:ChatPrint(BATM.Lang["[ATM] The owner has not yet set up this device"])
		return
	end

	if ent:GetReaderOwner() == nil or not ent:IsValid() then
		ply:ChatPrint(BATM.Lang["[ATM] An unknown error has occured, open a support ticket please."])
		return
	end

	--Now check if the user has enough money
	Accounts.GetCachedPersonalAccount(ply:SteamID64(), function(account, didExist)
		if didExist then
			--Now check they have enough
			if account.balance - ent:GetItemPrice() >= 0 then

				--Now try to add the money to the owner
				Accounts.GetCachedPersonalAccount(ent:GetReaderOwner():SteamID64(), function(account2, didExist)
					if didExist then
						account:AddBalance(ent:GetItemPrice() * -1, BATM.Lang["Purchase to "]..ent:GetReaderOwner():Name())
						account2:AddBalance(ent:GetItemPrice(), BATM.Lang["Purchase from "]..ply:Name())

						--Save them
						account:SaveAccount()
						account2:SaveAccount()

						BATM.NetworkAccount(ent:GetReaderOwner(), account2, false)
						BATM.NetworkAccount(ply, account, false)

						ply:ChatPrint(BATM.Lang["[ATM] Purchase Succesfull"])
						ent:GetReaderOwner():ChatPrint(BATM.Lang["[ATM] Purchase received from "]..ply:Name())
					else					
						ply:ChatPrint(BATM.Lang["[ATM] The owner of this device does not have a valid account, this can happen if they leave the server and their entity is still here."])
					end
				end)
			else
				ply:ChatPrint(BATM.Lang["[ATM] You don't have enougth money in your bank to do this."])
			end
		end
	end)
end)