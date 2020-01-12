--[[-------------------------------------------------------------------------
This file handles account tables
---------------------------------------------------------------------------]]

local ACCOUNTS = {}

--Used to handle saving and loading of data
ACCOUNTS.SQL = CBLib.LoadModule("batm/bm_sql.lua", true)

--A list of accounts that have been cached
ACCOUNTS.CachedPersonalAccounts = {}
ACCOUNTS.CachedGroupAccounts = {}



--A metatable representing an account
local AccountMeta = {}

AccountMetaAccessor = {__index = AccountMeta}

local PLAYER = FindMetaTable("Player")

--Returns the balance of the account its called on
function AccountMeta:GetBalance()
	return self.balance
end

--Returns either the whole or part of the balance history for the account
function AccountMeta:GetBalanceHistory(index)
	if index ~= nil and index ~= -1 then
		return self.balanceHistory[index]
	else
		return self.balanceHistory
	end
end

--This does not perfom the trasaction, it only adds it
--into the balance history log
function AccountMeta:InsertTransaction(amount, description)
	local newBalanceHistory = {}

	for i = 1 , 20 do
		if i ~= 1 and self.balanceHistory[i - 1] ~= nil then
			newBalanceHistory[i] = self.balanceHistory[i - 1]
		end
	end

	--Insert the new balance
	newBalanceHistory[1] = {
		amount = amount,
		description = description
	}

	--Now update the new balance history
	self.balanceHistory = newBalanceHistory
end

--Adds a balance, then adds a log in the balance history
function AccountMeta:AddBalance(amount, description)
	self.balance = self.balance + amount

	self:InsertTransaction(amount, description or "Unkown...")
end

--Returns wether or not the account is a group account or personal
function AccountMeta:IsGroupAccount()
	return self.IsGroup or false
end

--Returns wether or not the account is a group account or personal
function AccountMeta:IsGroupAccount()
	return not self.IsGroup or true
end

--Adds an owner, can only be used on group accounts
function AccountMeta:AddOwner(steamid64, name, callback)
	if self:IsGroupAccount() then
		--Now we need to make sure that the person they are adding
		--has an account, and if so we need to add the groupid to there group table`
		ACCOUNTS.GetCachedPersonalAccount(steamid64, function(account)
			if account == false then
				callback(false)
			else 
				if not table.HasValue(self.owners, steamid64) then
					table.insert(self.owners, steamid64)
					self.ownerNames[steamid64] = name

					--Now let the player know that there part of this group
					table.insert(account.groupAccounts, {id = self.ownerID, name = self.ownerName})
					account:SaveAccount()

					if player.GetBySteamID64(steamid64) ~= false then
						BATM.NetworkAccount( player.GetBySteamID64(steamid64), account, false)
					end

					callback(true)
				else
					callback(true)
				end
			end
		end)
	else
		print("[BATM ERROR] Tried to add owner to a personal account, this should not happen, please open a support ticket.")
	end
end

--Removes an owner, can only be used on group accounts
function AccountMeta:RemoveOwner(steamid64, callback)
	if self:IsGroupAccount() then
		if steamid64 == self.ownerID then
			callback(false, "You cannot kick the owner of the group acocunt.")
			return
		end

 		if table.HasValue(self.owners, steamid64) then
			for k ,v in pairs(self.owners) do
				if v == steamid64 then
					--Remove it
					table.remove(self.owners, k)
					self.ownerNames[steamid64] = nil --Remove there name from the storage

					--Now we need to check if the player has a personal account, if they do remove our id from there gruop list
					ACCOUNTS.GetCachedPersonalAccount(steamid64, function(account)
						if account == false then
							callback(false, "Account does not exist.")
						else 
							--Now find to see if our group is there, if so remove it
							for k ,v in pairs(account.groupAccounts) do
								if v.id == self.ownerID then --Dont break incase it bugs and there multiple entries
									account.groupAccounts[k] = nil
								end 
							end

							if player.GetBySteamID64(steamid64) ~= false then
								BATM.NetworkAccount( player.GetBySteamID64(steamid64), account, false)
							end

							account:SaveAccount()

							callback(true)
						end
					end)
				end
			end
		end
	else
		print("[BATM ERROR] Tried to remove owner from a personal account, this should not happen, please open a support ticket.")
	end
end

--This will save an account to the sql database
function AccountMeta:SaveAccount()
	if self.IsGroup == true then
		ACCOUNTS.SQL.SaveGroupAccount(self)
	else
		ACCOUNTS.SQL.SavePersonalAccount(self)
	end
end


--Returns a table of that users permission in the group account its called on
--Pass either a steamid for offline players of a steamid64 for online players
--[[function AccountMeta:GetUserPerms(steamid64)
	if not isnumber(steamid64) then
		steamid64 = steamid64:SteamID64()
	end

	--Lets check if we are an owner first
	for k , v in pairs(owners) do
		if v.id == steamid64 then
			return v.perms
		end
	end

	--If we made it this far there not in the group account, so lets just return false perms
	return {withdraw = false, deposite = false, addusers = false}
end
]]--

--Returns a personal account table structure
function ACCOUNTS.CreatePersonalAccount(params)
	--Create account table
	local _account = {
		balance = params.balance or BATM.Config.StartingBalance, --The balance
		balanceHistory = params.balanceHistory or {}, --Last 20 transactions
		ownerID = params.ownerID or -1, --    -1 = no owner
		IsGroup = false,
		groupAccounts = params.groupAccounts or {} --A table of all the group accounts they belong to (id's)
	}

	--Set the meta table
	setmetatable(_account, AccountMetaAccessor)

	--Returnt he account
	return _account
end

--Returns a group account table stucture
function ACCOUNTS.CreateGroupAccount(params)
	--Create account table
	local _account = {
		balance = params.balance or 0, --The balance
		balanceHistory = params.balanceHistory or {}, --Last 20 transactions
		ownerID = params.ownerID or -1, --The primary owner, this person has control over all
		ownerNames = params.ownerNames or {}, --A list of the names of owner, so they can be viewer offline
		ownerName = params.ownerName or "NAME ERROR",
		owners = params.owners or {}, --contains a table of steamid's64 that can access the account
		IsGroup = true
	}

	--Set the meta table
	setmetatable(_account, AccountMetaAccessor)

	--Returnt he account
	return _account
end

--Checks to see if there is a cashed version of
--an account, if not it returns false otherwise it returns the account
function ACCOUNTS.GetCachedPersonalAccount(steamID, callback)
	if ACCOUNTS.CachedPersonalAccounts[steamID] == nil then
		ACCOUNTS.LoadPersonalAccount(steamID, callback)
	else
		callback(ACCOUNTS.CachedPersonalAccounts[steamID], true)
	end
end

--Gets a group account, the account ID is the user that created it.
--You may notice that this no longer caches (it used to) but has not been removed due to having
--to change a bucnh of other code, this cannot be cached becuase if a member of a group account
--is on one server, and anouther of the other then they can essentially duplicate money using it
--its a bit less efficient but its the only way I could think to combat it
function ACCOUNTS.GetCachedGroupAccount(steamID, shouldCreate, callback)
	ACCOUNTS.LoadGroupAccount(steamID, shouldCreate, function(account, worked)
		if not worked and shouldCreate then
			callback(account, false)
		elseif worked then
			callback(account, true)
		else
			callback(false, false)
		end
	end)
end

--Tries to load a personal account from SQL. if it fails it creates the account
function ACCOUNTS.LoadPersonalAccount(steamid, callback)
	ACCOUNTS.SQL.LoadPersonalAccount(steamid, function(account)
		if account ~= false then --yay
			local account = ACCOUNTS.CreatePersonalAccount(account)
			--cache it
			ACCOUNTS.CachedPersonalAccounts[steamid] = account
			callback(account, true)
		else -- uh oh
			local account = ACCOUNTS.CreatePersonalAccount({ownerID = steamid})
			ACCOUNTS.CachedPersonalAccounts[steamid] = account
			callback(account, false)
		end
	end)
end

function ACCOUNTS.DoesPersonalAccountExist(steamid, callback)
	ACCOUNTS.SQL.LoadPersonalAccount(steamid, function(account)
		if account ~= false then --yay
			callback(true)
		else -- uh oh
			callback(false)
		end
	end)
end

--Tries to load a group account from SQL
function ACCOUNTS.LoadGroupAccount(steamid, shouldCreate, callback)
	ACCOUNTS.SQL.LoadGroupAccount(steamid, function(account)
		if account ~= false then --yay
			local _account = ACCOUNTS.CreateGroupAccount(account)
			--cache it
			if (ACCOUNTS.CachedGroupAccounts[steamid] == nil) then
				ACCOUNTS.CachedGroupAccounts[steamid] = _account
			end
			callback(ACCOUNTS.CachedGroupAccounts[steamid], true)
		elseif account == false and shouldCreate then -- uh oh
			if player.GetBySteamID64(steamid) == false then return end --Tried to create a group for an offline player, not allowed
			local ply = player.GetBySteamID64(steamid)
			local _account = ACCOUNTS.CreateGroupAccount({ownerID = steamid, ownerName = ply:Name(), owners = {steamid}, ownerNames = {[steamid] = ply:Name()}})
			ACCOUNTS.CachedGroupAccounts[steamid] = _account
			callback(_account, false)
		else
			callback(false, false)
		end
	end)
end

--Finds and returns a list of group accounts 
--That the user is linked to
function PLAYER:BATM_GetGroupAccounts()
	--Do some SQL shit here to get shit and stuff
end

function PLAYER:BATM_GetPersonalAccount()
	--Do some shit to return the personal account
end

hook.Add("PlayerDisconnected", "removeChachedAccountBATM", function(ply)
	local sid = ply:SteamID64()
	ACCOUNTS.CachedPersonalAccounts[sid] = nil
end)

CBLIB_MODULE = ACCOUNTS