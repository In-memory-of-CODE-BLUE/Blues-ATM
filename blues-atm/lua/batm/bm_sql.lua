local SQL = {}
SQL.UseMySQL = false

--Tries to create the mysql tables if they dont exist
function SQL.CreateMySQLTables()
	local query = SQL.MySQLDB:query([[
		CREATE TABLE batm_personal_accounts (
		    steamid BIGINT,
		    accountinfo TEXT,
		    PRIMARY KEY (steamid)
		);		
	]])

	function query:onSuccess(data)
		print("[BATM] Created mysql personl accounts table.")
	end

	function query:onError(err)
		print("[ATM] Failed to create the sql tables, If the following error says that the table already exists then this is fine. Ignore it, otherwise open a suppor ticket. ERROR:"..err)
	end	

	query:start()
	query:wait()

	--Group table
	local query = SQL.MySQLDB:query([[
		CREATE TABLE batm_group_accounts (
		    steamid BIGINT,
		    accountinfo TEXT,
		    PRIMARY KEY (steamid)
		);	
	]])

	function query:onSuccess(data)
		print("[BATM] Created mysql group accounts table.")
	end

	function query:onError(err)
		print("[ATM] Failed to create the sql tables, If the following error says that the table already exists then this is fine. Ignore it, otherwise open a suppor ticket. ERROR:"..err)
	end	

	query:start()
	query:wait()
end

--Tries to connect to the database, creates the tables if they dont exists etc
function SQL.Initialize()
	if not BATM.Config.UseMySQL then
		if not sql.TableExists("batm_personal_accounts") then
			print("[BATM] Creating SQL tables...")
			local result = sql.Query([[
				CREATE TABLE batm_personal_accounts (
				    steamid INT,
				    accountinfo TEXT,
				    PRIMARY KEY (steamid)
				);
			]])
		end 

		if not sql.TableExists("batm_group_accounts") then
			result = sql.Query([[
				CREATE TABLE batm_group_accounts (
				    steamid INT,
				    accountinfo TEXT,
				    PRIMARY KEY (steamid)
				);
			]])
		end
	else
		--Try to load mysql
		require("mysqloo")

		if mysqloo == nil then return false, "[BATM] Failed to load MySQLoo, are you sure you have it installed?" end

		--Now try to connect to the database
		db = mysqloo.connect(BATM.Config.MySQLDetails.host, 
			BATM.Config.MySQLDetails.username, 
			BATM.Config.MySQLDetails.password, 
			BATM.Config.MySQLDetails.databasename, 
			tonumber(BATM.Config.MySQLDetails.port)
		)

		local worked = false
		function db:onConnected()
		    SQL.MySQLDB = db
		    print("[BATM] Connected to mysql database '"..BATM.Config.MySQLDetails.databasename.."'")
		    worked = true

		    --Now try to create the tables
		    SQL.CreateMySQLTables()
		end

		local error = "ERROR"
		function db:onConnectionFailed( err )
		    print( "[BATM] Connection to database failed!" )
		    error = err
		    worked = false
		end

		--Keep connection alive
		db:setAutoReconnect(true)

		db:connect()
		db:wait()

		return worked, error
	end
	
	return true, "congrats to derik and lamar on ur baby boi"
end

--takes an account meta object and saves it to the sql database
--This will only save personal accounts, use the other function for group accounts
function SQL.SavePersonalAccount(account)
	if not BATM.Config.UseMySQL then
		local result = sql.Query([[INSERT OR REPLACE INTO batm_personal_accounts VALUES (]]
			..account.ownerID..[[ , ]]..sql.SQLStr(util.TableToJSON(account))..[[);]])
		if result then
			print(sql.LastError())
		end
	else
		--MySQL stuff here 
		local query = SQL.MySQLDB:query([[INSERT INTO batm_personal_accounts (steamid, accountinfo) VALUES (]]
			..account.ownerID..[[ , ']]..SQL.MySQLDB:escape(util.TableToJSON(account))..[[') ON DUPLICATE KEY UPDATE accountinfo = ']]..SQL.MySQLDB:escape(util.TableToJSON(account))..[[']])

		function query:onSuccess(data)
			print("[BATM] Saved personal account succefully")
		end

		function query:onError(err)
			print("[ATM] Failed to save personal account, this will result in data loss. Please read the following error: "..err)
		end	

		query:start()
	end

end

--Save a group account
function SQL.SaveGroupAccount(account)
	if not BATM.Config.UseMySQL then
		--Before saving it, convert the name table
		--Fix the account table
		local newOwnerNames = {}
		for k ,v in pairs(account.ownerNames) do
			newOwnerNames["S"..k] = v
		end
		account.ownerNames = newOwnerNames

		local result = sql.Query([[INSERT OR REPLACE INTO batm_group_accounts VALUES (]]
			..account.ownerID..[[ , ]]..sql.SQLStr(util.TableToJSON(account))..[[);]])
		if result then
			print(sql.LastError())
		end

		--Now convert it back
		local newOwnerNames = {}
		for k ,v in pairs(account.ownerNames) do
			newOwnerNames[string.sub(k,2, string.len(k))] = v
		end
		account.ownerNames = newOwnerNames
	else
		--MySQL stuff here 
		
		--convert names
		local newOwnerNames = {}
		for k ,v in pairs(account.ownerNames) do
			newOwnerNames["S"..k] = v
		end
		account.ownerNames = newOwnerNames

		local query = SQL.MySQLDB:query([[INSERT INTO batm_group_accounts (steamid, accountinfo) VALUES (]]
			..account.ownerID..[[ , ']]..SQL.MySQLDB:escape(util.TableToJSON(account))..[[') ON DUPLICATE KEY UPDATE accountinfo = ']]..SQL.MySQLDB:escape(util.TableToJSON(account))..[[']])

		function query:onSuccess(data)
			print("[BATM] Saved group account succefully")
		end

		function query:onError(err)
			print("[ATM] Failed to save group account, this will result in data loss. Please read the following error: "..err)
		end	

		query:start()

		--Now convert it back
		local newOwnerNames = {}
		for k ,v in pairs(account.ownerNames) do
			newOwnerNames[string.sub(k,2, string.len(k))] = v
		end
		account.ownerNames = newOwnerNames
	end
end

--Tries to load a personal account, when it is retreived callback is called
--Passes the account to the callback or false if no account exists
function SQL.LoadPersonalAccount(steamid64, callback)
	if not BATM.Config.UseMySQL then
		--Escape it
		steamid64 = sql.SQLStr(steamid64)

		local result = sql.Query([[SELECT * FROM batm_personal_accounts WHERE steamid = ]]..steamid64..[[]])
		if istable(result) and result[1] ~= nil then
			local accountTable = util.JSONToTable(result[1].accountinfo)

			callback(accountTable)
		else
			callback(false)
		end
	else
		--MySQL stuff here 
		steamid64 = SQL.MySQLDB:escape(steamid64)

		local query = SQL.MySQLDB:query([[SELECT * FROM batm_personal_accounts WHERE steamid = ]]..steamid64..[[;]])

		function query:onSuccess(result)
			if istable(result) and result[1] ~= nil then
				local accountTable = util.JSONToTable(result[1].accountinfo)

				callback(accountTable)
			else
				callback(false)
			end
		end

		function query:onError(err)
			print("[ATM] Failed to load personal account, this will result in data loss. Please read the following error: "..err)
			callback(false)
		end	

		query:start()
	end
end

--Tries to load a personal account, when it is retreived callback is called
--Passes the account to the callback or false if no account exists
function SQL.LoadGroupAccount(steamid64, callback)
	if not BATM.Config.UseMySQL then
		--Escape it 
		steamid64 = sql.SQLStr(steamid64)

		local result = sql.Query([[SELECT * FROM batm_group_accounts WHERE steamid = ]]..steamid64..[[]])
		if istable(result) and result[1] ~= nil then
			local accountTable = util.JSONToTable(result[1].accountinfo)

			--Now convert it back
			local newOwnerNames = {}
			for k ,v in pairs(accountTable.ownerNames) do
				newOwnerNames[string.sub(k,2)] = v
				accountTable.ownerNames[k] = nil
			end
			accountTable.ownerNames = newOwnerNames

			callback(accountTable)
		else
			callback(false)
		end
	else
		--MySQL stuff here 
		--MySQL stuff here 
		steamid64 = SQL.MySQLDB:escape(tostring(steamid64))

		local query = SQL.MySQLDB:query([[SELECT * FROM batm_group_accounts WHERE steamid = ]]..steamid64..[[;]])

		function query:onSuccess(result)
			if istable(result) and result[1] ~= nil then
				local accountTable = util.JSONToTable(result[1].accountinfo)

				--Now convert it back
				local newOwnerNames = {}
				for k ,v in pairs(accountTable.ownerNames) do
					newOwnerNames[string.sub(k,2)] = v
					accountTable.ownerNames[k] = nil
				end
				accountTable.ownerNames = newOwnerNames

				callback(accountTable)
			else
				callback(false)
			end
		end

		function query:onError(err)
			print("[ATM] Failed to load personal account, this will result in data loss. Please read the following error: "..err)
			callback(false)
		end	

		query:start()
	end
end

CBLIB_MODULE = SQL