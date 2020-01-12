--[[-------------------------------------------------------------------------
This file handles anything to do with SQL. Its object based.
---------------------------------------------------------------------------]]

local SQLMeta = {}
local SQLMetaAccessor = {__index = SQLMeta}

local SQL = {}

--[[-------------------------------------------------------------------------
SQL Stuff
---------------------------------------------------------------------------]]

--Try to load up SQL
local mysqlFound = false
pcall(function(fileName) 
	require(fileName)
	if mysqloo ~= nil then
		mysqlFound = true
	end, 
end, "mysqloo")

if no mysqlFound then
		CBLib.Debug.Warning("---------------WARNING!---------------")
		CBLib.Debug.Warning("MySQLOO not found, this is not an issue if your not using MySQL, otherwise it is and you need to install it!")
		CBLib.Debug.Warning("--------------------------------------")
end

--Returns an SQL object
function SQL.CreateInstance(host, username, password, database, port)
	local instance = {}
	setmetatable(instance, SQLMetaAccessor)
	instance.database = mysqloo.connect(host, username, password, database, port)
	instance.connected = false

	instance.database.onConnected = function(db)
		CBLib.Debug.Info("Connect to database succesfully! ('"..host.."/"..database.."')")
		instance.connected = false
	end

	instance.database.onConnectionFailed = function(err, db)
		CBLib.Debug.Error("---------------ERROR!---------------")
		CBLib.Debug.Error("Failed to connect to database! ('"..host.."/"..database.."')")
		CBLib.Debug.Error("DATA LOSS WILL OCURE! I Recommend shutting the server down.")
		CBLib.Debug.Error("REASON : "..err)

		CBLib.Debug.Error("------------------------------------")
		instance.connected = false
	end

	instance.database:connect()

	return instance
end

function SQLMeta:



