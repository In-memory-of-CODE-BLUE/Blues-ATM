AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

util.AddNetworkString("batm:updatescene")

function ENT:Initialize()
	self:SetModel("models/bluesatm/atm_wall_front.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake() 
	end

	self.currentUser = nil
	self.timeSinceLastInteraction = 0

	self.currentScene = "home"
end

--When called will attach a user to the machine
function ENT:AttachUser(user)
	--First try to remove the old user if they are still here
	self:DetatchUser(false) --dont network and its going to be updated right away

	--Now attach them
	self.currentUser = user
	self.timeSinceLastInteraction = CurTime()

	user.batmLastMachineUsed = self
	user.batmLastTimeIntereacted = CurTime()
end
 
--When called it removes the user from the machine
function ENT:DetatchUser()
	if self.currentUser ~= nil then
		if not self.currentUser:IsValid() then
			self.currentUser = nil
		else
			self.currentUser.batmLastMachineUsed = nil
			self.currentUser = nil
		end

		--Now that there attached, lets thell them to go to the home scene
		net.Start("batm:updatescene")
			net.WriteEntity(self)
			net.WriteString("home")
		net.Send(player.GetAll())
	end 
end

--Checks if user time is expired.
function ENT:Think()
	if self.currentUser ~= nil then
		if not self.currentUser:IsValid() then
			self:DetatchUser(true) --Kick them, they took to long!
			return
		end

		if (self.timeSinceLastInteraction + 30) - CurTime() <= 0 then
			self.currentUser:ChatPrint(BATM.Lang["[ATM] You're sesion has ended as you took too long to interact!"])
			self:DetatchUser(true) --Kick them, they took to long!
			return
		end

		if self.currentUser:GetPos():Distance(self:GetPos()) > 200 then
			self.currentUser:ChatPrint(BATM.Lang["[ATM] You're sesion has ended as you are to far away from the machine!"])
			self:DetatchUser(true) --Kick them, there too far away
		end
	end
end

function ENT:OnRemove()
	self:DetatchUser(false) --No need, we're being fired boss
end

--Returns weather or not the player is allowed to use the machine
function ENT:IsPlayerAuthenticated(ply)

	--Are they using anouther machine?
	if ply.batmLastMachineUsed ~= nil and ply.batmLastMachineUsed ~= self then
		return false, "anouthermachineactive"
	end

	--Is someone else using this machine?
	if self.currentUser ~= nil and self.currentUser ~= ply then
		return false, "someonealreadyusing"
	end

	--We are already using this machine, so we can continue to use it
	if self.currentUser == ply then
		return true, "theyareusing"
	end

	if self.currentUser == nil then
		return false, "nouser"
	end

	return false, "error" --Uh oh, better return false just incase something slips through
end

--Called when someone presses e
function ENT:Use(act, ply)
	--If we got triggered by something that isnt a player, dont do anything
	if not ply:IsPlayer() then return end

	local authenticated, reason = self:IsPlayerAuthenticated(ply)

	--Are they authenticated?
	if authenticated then
		--Update it so that they dont get kicked
		self.timeSinceLastInteraction = CurTime()
	else
		--If the reason we failed is becuase there not set up, then set them up
		if reason == "nouser" then
			self:AttachUser(ply)

			

			--If we are looking at a button, called button pressed
			self:SetScene("accountselection", ply)

			--TODO update scenes for other users
		elseif reason == "someonealreadyusing" then
			ply:ChatPrint(BATM.Lang["[ATM] Someone is already using this ATM"])
		elseif reason == "anouthermachineactive" then
			ply:ChatPrint(BATM.Lang["[ATM] You are already using anouther ATM!"])
		end
	end

end

--Scenes have no effect on the server other than the scene name
--This functions udpates that and mirrors the scene to the client.
function ENT:SetScene(sceneName, player)
	--Network it to the clients
	net.Start("batm:updatescene")
		net.WriteEntity(self)
		net.WriteString(sceneName)
	net.Send(player)

	self:OnSceneChanged(self.currentSceneName or "home", sceneName)

	self.currentScene = sceneName
end

--Called when ever a scene is changed
function ENT:OnSceneChanged(from, to)

end

--Attempts to charge the player to play, returns false if failed, true if succesfull
function ENT:BuyIn(ply)
	return true
end

hook.Add("PlayerIntitialSpawn", "batm:setupPlayer", function(ply)
	ply.batmLastMachineUsed = nil --The last machine the player used
	ply.batmLastTimeIntereacted = 0 --The time since they last used a machine
end)