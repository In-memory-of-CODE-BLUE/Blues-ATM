--[[-------------------------------------------------------------------------
This file handles most of the server side atm stuff, such as setting and getting bank values
Creating and destroying group accounts.
---------------------------------------------------------------------------]]
include("batm_config.lua")
AddCSLuaFile("batm_translation.lua")
include("batm_translation.lua")

util.AddNetworkString("blueatm")

BATM = BATM or {} 
 
local Accounts = CBLib.LoadModule("batm/bm_accounts.lua", false)
 
--Lets try connect to the sql database
local connected, failedReason = Accounts.SQL.Initialize()
if connected == false then
	MsgC(Color(255,100,100), "--------------------------------------BLUEATM ERROR--------------------------------------\n")
	print("BLUE ATM : Failed to connect to the sql database, a reason should be below. If you cannot fix this then please open a support ticket!")
	print("BlueATM will not function correctly without resolving this error.\n"..failedReason)
	error("SQL_CONNECT_ERROR")
end
 
--Try to load there account, if not create one. (Test) 
hook.Add("PlayerInitialSpawn" , "TestLoad", function(ply)
	--What we will do, is when the player spawns we will check which groups there part of
	--Then we will confirm each group still has that user as a memeber so you can kick offline memeber of the group
	Accounts.GetCachedPersonalAccount(ply:SteamID64(), function(account, didExist)
		if didExist then
			timer.Simple(0.1, function() --Due to bug we have to network it the next frame
				BATM.NetworkAccount(ply, account) --We network this instantly so that the user can see what groups there part of in the account selections creen
			end)
		end
	end)

	local timerName = "batm_interest_"..ply:SteamID64()
	timer.Create("batm_interest_"..ply:SteamID64(), 60 * BATM.Config.InterestInterval, 0, function()
		if BATM.Config.InterestRate <= 0 then
			return
		end

		if not ply:IsValid() then
			timer.Destroy(timerName)
			return
		end

		--Get there account, if it exists then add the interest to it.
		Accounts.SQL.LoadPersonalAccount(ply:SteamID64(), function(account)
			if account ~= false then --yay
				--Add the interested
				Accounts.GetCachedPersonalAccount(ply:SteamID64(), function(account, didExist)
					local interestAmount = math.floor((account:GetBalance() / 100.0) * BATM.Config.InterestRate)
					interestAmount = math.Clamp(interestAmount, 0, BATM.MaxInterest or interestAmount)
					
					if interestAmount > 0 then
						account:AddBalance(interestAmount, BATM.Config.InterestRate..BATM.Lang["% Interest"])
						account:SaveAccount() 
						BATM.NetworkAccount(ply, account, false)
						ply:ChatPrint(BATM.Lang["[ATM] You just got "]..BATM.Config.InterestRate..BATM.Lang["% interest! You will next get interest in 15 minutes!"])
					end
				end)
			end
		end)
	end)
end)      
  
--Check is a number is "valid"
function BATM.VerifyNumber(number)
	return number ~= nil and number > 0
end

--Networks an accoun to a single user
function BATM.NetworkAccount(user, account, shouldUpdateSelectedAccount)
	if shouldUpdateSelectedAccount == nil then
		shouldUpdateSelectedAccount = true
	end

	net.Start("blueatm")
	net.WriteUInt(BATM_NET_COMMANDS.receiveAccountInfo, 8)
	net.WriteTable(account)
	net.WriteBool(shouldUpdateSelectedAccount)
	net.Send(user)
end

--Networks a group account to all online players from that group
function BATM.NetworkGroupAccount(account)
	local owners = account.owners

	--Check members
	for k ,v in pairs(owners) do
		local ply = player.GetBySteamID64(v)
		if ply ~= false then
			BATM.NetworkAccount(ply, account)		
		end
	end

	--Check owner
	local ply = player.GetBySteamID64(account.ownerID)
	if ply ~= false then
		BATM.NetworkAccount(ply, account)		
	end

end

--[[-------------------------------------------------------------------------
Handle net messages
---------------------------------------------------------------------------]]
local networkEvents = {}
local function addNetworkEvent(typeID, func)
	networkEvents[typeID] = func
end 
net.Receive("blueatm", function(len, ply)
	if ply.batmcooldown == nil then
		ply.batmcooldown = CurTime()
	else
		if CurTime() - ply.batmcooldown < 0.1 then
			return
		else
			ply.batmcooldown = CurTime()
		end
	end

	local type = net.ReadUInt(8)
	local ent = net.ReadEntity()
	--Prevent false calls
	if type == 0 then return end
	if networkEvents[type] == nil then return end
	if not IsValid(ent) or ent:GetClass() ~= "atm_wall" then return end
	

	networkEvents[type](ent, ply)
end)

--[[-------------------------------------------------------------------------
Networking logic
---------------------------------------------------------------------------]]

--Load an account
addNetworkEvent(BATM_NET_COMMANDS.selectAccount, function(ent, ply)
	local type = net.ReadString()
	if type == nil then return end
	--Get that players personal account
	if type == "personal" then 
		Accounts.GetCachedPersonalAccount(ply:SteamID64(), function(account)
			BATM.NetworkAccount(ply, account)
			ent:SetScene("personalaccount", ply)
			ply.batmloadedaccountid = -1 --
		end)
	elseif type == "personalgroup" then --Personal group is the group account that is created by the player

		Accounts.GetCachedGroupAccount(ply:SteamID64(), true, function(account)
			account.ownerName = ply:Name()
			BATM.NetworkAccount(ply, account)
			account:SaveAccount()

			ent:SetScene("groupaccount", ply)
			ply.batmloadedaccountid = ply:SteamID64()
		end)
	elseif type == "group" then --This is a group account created by someone else
		local groupID = net.ReadString()
		Accounts.GetCachedGroupAccount(groupID, false, function(account)
			if account == false then
				ent:SetScene("failed", ply)
				timer.Simple(2, function()
					ent:SetScene("accountselection", ply)
				end)
				ply:ChatPrint(BATM.Lang["[ATM] Incorrect data..."])	
				return
			end

			if not table.HasValue(account.owners, ply:SteamID64()) then
				ent:SetScene("failed", ply)
				timer.Simple(2, function()
					ent:SetScene("accountselection", ply)
				end)
				ply:ChatPrint(BATM.Lang["[ATM] You are not a member of this group..."])	
				return 
			end

			--So there a member, lets network it
			BATM.NetworkAccount(ply, account)
			ent:SetScene("groupaccount", ply)
			ply.batmloadedaccountid = groupID
		end)
	end
end) 

--Deposite into an account
addNetworkEvent(BATM_NET_COMMANDS.deposit, function(ent, ply)
	local accountType = net.ReadString() 
	local amount = math.floor(net.ReadDouble())

	if not BATM.VerifyNumber(amount) then 
		ent:SetScene("failed", ply)
		timer.Simple(2, function()
			ent:SetScene("accountselection", ply)
		end)
		ply:ChatPrint(BATM.Lang["[ATM] Incorrect data..."])	
		return
	end

	--Check if they can afford it
	if not BATM.Config.CanAfford(ply, amount) then
		ent:SetScene("failed", ply)
		ply:ChatPrint(BATM.Lang["[ATM] You don't have that much money!"])	
		return			
	end

	if accountType == "personal" then 
		--If they can afford it then deposite it
		Accounts.GetCachedPersonalAccount(ply:SteamID64(), function(account)
			account:AddBalance(amount, BATM.Lang["Deposit from account owner"])

			if not BATM.Config.CanAfford(ply, amount) then
				ent:SetScene("failed", ply)
				ply:ChatPrint(BATM.Lang["[ATM] You don't have that much money!"])	
				return			
			end

			BATM.Config.TakeMoney(ply, amount)

			account:SaveAccount()
			BATM.NetworkAccount(ply, account)
			ent:SetScene("done", ply)
		end)
	else
		local groupID = ply.batmloadedaccountid
		--Try to load the account
		Accounts.GetCachedGroupAccount(groupID, false, function(account, valid)
			if account == false then 
				ent:SetScene("failed", ply)
				timer.Simple(2, function()
					ent:SetScene("accountselection", ply)
				end)
				ply:ChatPrint(BATM.Lang["[ATM] You don't have permission to do this..."])	
				return
			end



			--Check if they have perms
			if account.ownerID == ply:SteamID64() or table.HasValue(account.owners, ply:SteamID64()) then
				if not BATM.Config.CanAfford(ply, amount) then
					ent:SetScene("failed", ply)
					ply:ChatPrint(BATM.Lang["[ATM] You don't have that much money!"])	
					return			
				end

				BATM.Config.TakeMoney(ply, amount)

				account:AddBalance(amount, "Deposit from "..ply:Name())
				account:SaveAccount()
				BATM.NetworkGroupAccount(account)
				ent:SetScene("done", ply)				
			else
				ent:SetScene("failed", ply)
				timer.Simple(2, function()
					ent:SetScene("accountselection", ply)
				end)
				ply:ChatPrint(BATM.Lang["[ATM] You don't have permission to do this..."])	
				return				
			end
		end)
	end
end)
 
--Deposite into an account
addNetworkEvent(BATM_NET_COMMANDS.withdraw, function(ent, ply)
	local accountType = net.ReadString() 
	local amount = math.floor(net.ReadDouble())
	if not BATM.VerifyNumber(amount) then 
		ent:SetScene("failed", ply)
		timer.Simple(2, function()
			ent:SetScene("accountselection", ply)
		end)
		ply:ChatPrint(BATM.Lang["[ATM] Incorrect data..."])	
		return
	end

	if accountType == "personal" then 
		--First get there account
		Accounts.GetCachedPersonalAccount(ply:SteamID64(), function(account)
			--Check if they have enough
			if account.balance - amount >= 0 then
				account:AddBalance(-amount, "Withdrawal from account owner.")
				BATM.Config.AddMoney(ply, amount)
				account:SaveAccount()
				BATM.NetworkAccount(ply, account)
				ent:SetScene("done_withdraw", ply)
			else
				ent:SetScene("failed", ply)
				ply:ChatPrint(BATM.Lang["[ATM] You don't have that much money!"])
			end
		end)
	else
		local groupID = ply.batmloadedaccountid
		--Try to load the account
		Accounts.GetCachedGroupAccount(groupID, false, function(account, valid)
			if account == false then 
				ent:SetScene("failed", ply)
				timer.Simple(2, function()
					ent:SetScene("accountselection", ply)
				end)
				ply:ChatPrint(BATM.Lang["[ATM] You don't have permission to do this..."])	
				return 
			end

			--Check if they have perms
			if account.ownerID == ply:SteamID64() or table.HasValue(account.owners, ply:SteamID64()) then
				if account:GetBalance() - amount >= 0 then
					account:AddBalance(-amount, "Withdrawal from "..ply:Name())
					BATM.Config.AddMoney(ply, amount)
					account:SaveAccount()
					BATM.NetworkGroupAccount(account)
					ent:SetScene("done", ply)		
				else
					ent:SetScene("failed", ply)
					ply:ChatPrint(BATM.Lang["[ATM] You don't have that much money!"])	
					return	
				end		
			else
				ent:SetScene("failed", ply)
				timer.Simple(2, function()
					ent:SetScene("accountselection", ply)
				end)
				ply:ChatPrint(BATM.Lang["[ATM] You don't have permission to do this..."])	
				return				
			end
		end) 
	end
end)

--Handles transfering funds from one player to anouther
addNetworkEvent(BATM_NET_COMMANDS.transfer, function(ent, ply)
	if ply.batmtransfercooldown == nil then ply.batmtransfercooldown = 0 end

	local amount = math.floor(net.ReadDouble())
	local target = net.ReadString()

	--Force a cooldown so they cannot spam queries
	if ply.batmtransfercooldown > CurTime() then 
		ent:SetScene("failed", ply)
		ply:ChatPrint(BATM.Lang["[ATM] You're sending to many requests! Please wait..."])	return 
	end

	if BATM.VerifyNumber(amount) then 
		--First get there account
		Accounts.GetCachedPersonalAccount(ply:SteamID64(), function(account)
			if account:GetBalance() - amount >= 0 then
				Accounts.GetCachedPersonalAccount(target, function(targetAccount, didExist)
					if not IsValid(ply) then return end --Dont do anything as that player has left now
					if didExist and account:GetBalance() - amount >= 0 then
						--Take money
						account:AddBalance(-amount, "Transfer to '"..target.."'")
						account:SaveAccount()

						--Add money
						targetAccount:AddBalance(amount, "Transfer from '"..ply:SteamID64().."'")
						targetAccount:SaveAccount()	

						--Update display
						BATM.NetworkAccount(ply, account)
						ent:SetScene("done_transfer", ply) 

						ply.batmtransfercooldown = CurTime() + 1.5

						--If the player is online who he transfered to, then go ahead and network it to them too
						if player.GetBySteamID64(target) ~= false then
							BATM.NetworkAccount(player.GetBySteamID64(target) , targetAccount)
						end
					else
						ply.batmtransfercooldown = CurTime() + 3
						ent:SetScene("failed", ply)
						ply:ChatPrint(BATM.Lang["[ATM] That person does not have an account set up!"])		
					end
					
				end)
			else
				ent:SetScene("failed", ply)
				ply:ChatPrint(BATM.Lang["[ATM] You don't have that much money!"])					
			end
		end)
	end
end)

--Load an account
addNetworkEvent(BATM_NET_COMMANDS.kickUser, function(ent, ply)
	local target = net.ReadString()
	local groupID = ply.batmloadedaccountid
	Accounts.GetCachedGroupAccount(groupID, false, function(account)
		--Does the account exist
		if account == false then 
			ent:SetScene("failed", ply)
			ply:ChatPrint(BATM.Lang["[ATM] You don't have permission to do this..."])	
			return 
		end

		--Now check that there the owner
		if ply:SteamID64() ~= account.ownerID then
			ent:SetScene("failed", ply)
			ply:ChatPrint(BATM.Lang["[ATM] You don't have permission to do this..."])	
			return 
		end

		--Now try to remove the user
		account:RemoveOwner(target, function(worked, reason)
			if worked then
				account:SaveAccount()
				ent:SetScene("members", ply)

				--Network it
				BATM.NetworkGroupAccount(account)
			else
				ent:SetScene("failed", ply)
				ply:ChatPrint(BATM.Lang["[ATM] "]..reason)	
				return 				
			end
		end)

	end)
end) 

--Add a member to a group account
addNetworkEvent(BATM_NET_COMMANDS.addUser, function(ent, ply)
	local target = net.ReadString()
	local groupID = ply.batmloadedaccountid
	Accounts.GetCachedGroupAccount(groupID, false, function(account)
		--Does the account exist
		if account == false then 
			ent:SetScene("failed", ply)
			timer.Simple(2, function()
				ent:SetScene("accountselection", ply)
			end)
			ply:ChatPrint(BATM.Lang["[ATM] You don't have permission to do this..."])	
			return 
		end

		--Now check that there the owner
		if ply:SteamID64() ~= account.ownerID then
			ent:SetScene("failed", ply)
			timer.Simple(2, function()
				ent:SetScene("accountselection", ply)
			end)
			ply:ChatPrint(BATM.Lang["[ATM] You don't have permission to do this..."])	
			return 
		end

		local targetply = player.GetBySteamID64(target)

		if targetply == false then
			ent:SetScene("failed", ply)
			timer.Simple(2, function()
				ent:SetScene("accountselection", ply)
			end)
			ply:ChatPrint(BATM.Lang["[ATM] Invalid player..."])	
			return 		
		end

		--Now try to remove the user
		account:AddOwner(target, targetply:Name(), function(worked)
			if worked then
				account:SaveAccount()
				ent:SetScene("members", ply)

				--Network it
				BATM.NetworkGroupAccount(account)
			else
				ent:SetScene("failed", ply)
				timer.Simple(2, function()
					ent:SetScene("accountselection", ply)
				end)
				ply:ChatPrint(BATM.Lang["[ATM] Oh no! Something went wrong, please try again!"])	
				return 					
			end
		end)

	end)
end) 


local function SaveAtms()
	local data = {}
	for k ,v in pairs(ents.FindByClass("atm_wall")) do
		table.insert(data, {pos = v:GetPos(), ang = v:GetAngles()})
	end
	if not file.Exists("batm" , "DATA") then
		file.CreateDir("batm")
	end

	file.Write("batm/"..game.GetMap()..".txt", util.TableToJSON(data))
end

local function LoadAtms()
	if file.Exists("batm/"..game.GetMap()..".txt" , "DATA") then
		local data = file.Read("batm/"..game.GetMap()..".txt", "DATA")
		data = util.JSONToTable(data)
		for k, v in pairs(data) do
			local slot = ents.Create("atm_wall")
			slot:SetPos(v.pos)
			slot:SetAngles(v.ang)
			slot:Spawn()
			slot:GetPhysicsObject():EnableMotion(false)
		end
		print("[BATM] Finished loading Blue ATM entities.")
	else
		print("[BATM] No map data found for Blue's ATM entities. Please place some and do !saveatms to create the data.")
	end
end

hook.Add("InitPostEntity", "spawn:batms", function()
	LoadAtms()
end)

--Handle saving and loading of slots
hook.Add("PlayerSay", "handlebatmcommands" , function(ply, text)
	if string.sub(string.lower(text), 1, 10) == "!saveatms" then
		if table.HasValue(BATM.Config.AuthorisedRanks, ply:GetUserGroup()) then
			SaveAtms()
			ply:ChatPrint(BATM.Lang["[ATM] Blue's atms have been saved for the map "]..game.GetMap().."!")
		else
			ply:ChatPrint(BATM.Lang["[ATM] You do not have permission to perform this action, please contact an admin."])
		end
	end
end)














