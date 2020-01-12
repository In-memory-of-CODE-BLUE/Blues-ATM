BATM = BATM or {} --Global table for easy access
BATM.PersonalAccount = nil --Stores an updated reference to the players personal account
BATM.GroupAccounts = {} --Stores an updated reference to ALL the group accounts this player has (if loaded first)
BATM.SelectedAccount = nil
BATM.ScreenDisabled = false
BATM.LightsDisabled = false

include("batm_translation.lua")

--Returns the players personal account
function BATM.GetPersonalAccount()
	return BATM.PersonalAccount or false --False if not loaded
end

--Returns the group account, false if none found
function BATM.GetGroupAccount(accountID)
	return BATM.GroupAccounts[accountID] or false
end

--[[-------------------------------------------------------------------------
Handle net messages
---------------------------------------------------------------------------]]
local networkEvents = {}
local function addNetworkEvent(typeID, func)
	networkEvents[typeID] = func
end

net.Receive("blueatm", function()
	local type = net.ReadUInt(8)
	--Prevent false calls
	if type == nil then return end
	if networkEvents[type] == nil then return end
	networkEvents[type]()
end)

--Handle incomming account updates
addNetworkEvent(BATM_NET_COMMANDS.receiveAccountInfo, function(ent)
	local account = net.ReadTable()
	local updateAccountType = net.ReadBool()

	if not account.IsGroup then
		if updateAccountType then
			BATM.SelectedAccount = "personal"
		end
		BATM.PersonalAccount = account 
	elseif account.IsGroup and account.ownerID == LocalPlayer():SteamID64() then
		if updateAccountType then
			BATM.SelectedAccount = "personalgroup"
		end
		BATM.GroupAccount = account
	elseif account.IsGroup then
		if updateAccountType then
			BATM.SelectedAccount = "group"
		end
		BATM.GroupAccount = account
	else
		print("[BATM ERROR] Error reading data on client, this should not happen, if it does open a support ticket.")
	end
	
end)

--Check is a number is "valid"
function BATM.VerifyNumber(number)
	return number ~= nil and number > 0
end

--Returns the active loaded account
function BATM.GetActiveAccount()
	if BATM.SelectedAccount == "personal" then
		return BATM.PersonalAccount
	else
		return BATM.GroupAccount
	end
end

--Tries to deposite that ammount into the loaded account
function BATM.Deposit(ent, amount)
	net.Start("blueatm")
	net.WriteUInt(BATM_NET_COMMANDS.deposit, 8)
	net.WriteEntity(ent)
	net.WriteString(BATM.SelectedAccount)
	net.WriteDouble(amount)
	net.SendToServer()
end 

--Tries to withdraw that ammount from the loaded account and adds it to the players darkrp balance
function BATM.Withdraw(ent, amount)
	net.Start("blueatm")
	net.WriteUInt(BATM_NET_COMMANDS.withdraw, 8)
	net.WriteEntity(ent)
	net.WriteString(BATM.SelectedAccount)
	net.WriteDouble(amount)
	net.SendToServer()
end

--Tries to withdraw that ammount from the loaded account and adds it to the players darkrp balance
--Target needs to be steamid64 or player object
function BATM.Transfer(ent, target, amount)
	local steamid
	if isentity(target) then
		steamid = tostring(target:SteamID64())
	end 

	if BATM.SelectedAccount == "personal" then
		net.Start("blueatm")
		net.WriteUInt(BATM_NET_COMMANDS.transfer, 8)
		net.WriteEntity(ent) 
		net.WriteDouble(amount) 
		net.WriteString(steamid or target) --There steamid 64
		net.SendToServer()
	end
end

--Tries to kick a user from your activly loaded account.
function BATM.KickUser(ent, target)
	local steamid
	if isentity(target) then
		steamid = tostring(target:SteamID64())
	end 

	if BATM.SelectedAccount ~= "personal" then
		net.Start("blueatm")
		net.WriteUInt(BATM_NET_COMMANDS.kickUser, 8)
		net.WriteEntity(ent) 
		net.WriteString(steamid or target) --There steamid 64
		net.SendToServer()
	end
end

--Tries to add a user from your activly loaded account.
function BATM.AddUser(ent, target)
	local steamid
	if isentity(target) then
		steamid = tostring(target:SteamID64() or "777777777777777")
	end 

	if BATM.SelectedAccount ~= "personal" then
		net.Start("blueatm")
		net.WriteUInt(BATM_NET_COMMANDS.addUser, 8)
		net.WriteEntity(ent) 
		net.WriteString(steamid or target) --There steamid 64
		net.SendToServer()
	end
end