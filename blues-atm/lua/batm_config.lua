--Its important that you read this correctly to fully understand how it works and not break your server!

--Do !saveatms to make the atms permanent!

--The following console commands can be run to improve performance if a player is lagging for some reason
--batm_enable_screens Enables the rendering of screens on the atm
--batm_disable_screens Disable rendering of the screens
--batm_enable_lights Enabled the dynamic lights on the ATM
--batm_disable_screens Disabled the dynamic lights on the ATM (This will improve performance but will make the atm look very out of place.)

BATM = BATM or {}
BATM.Config = {}

--MySQL stuff here
BATM.Config.UseMySQL = false --If this is true it will use mysqloo (make sure its installed) and if false it will use the sqlite database on the server

--These are the details for the mysql database, these wont be used unless the above option is true
--IMPORTANT! This was all developed and testing using msv_mysqloo v9
--A link to the module can be found here 
--https://gmod.facepunch.com/f/gmodaddon/jjdq/gmsv-mysqloo-v9-Rewritten-MySQL-Module-prepared-statements-transactions/1/
--or here https://web.archive.org/web/20160605173039/https://facepunch.com/showthread.php?t=1515853
BATM.Config.MySQLDetails = {
	host = "XX.XXX.XXX.XXX",
	port = "3306",
	databasename = "databasename",
	username = "username",
	password = "password"
}

--This is the % of interest they get every 15 minutes of PLAYTIME not offline time.
--Keep this number low otherwise you will ruin your economy.
--If your unsure what interest rates are then be sure to google it
BATM.Config.InterestRate = 1  --Set this to 0 to disable it!
BATM.MaxInterest = 50000 --This is the maximum they can get in interest, regardless of there account balance
BATM.Config.InterestInterval = 15 --This is the time in minutes between each payout for the interest

--This is how much money the user starts with when they first open a new account
BATM.Config.StartingBalance = 100

--This is a link of usergroups that can use the command !saveatms
BATM.Config.AuthorisedRanks = {
	"superadmin",
	"owner",
	"anyotherrankyouwant"
}


--This function is what should add money to the player, edit this if your running
--a custom gamemode that isnt darkrp
BATM.Config.AddMoney = function(ply, amount)
	ply:addMoney(amount)
end

--This function should take money from the player, edit this if your running
--a custom gamemode that isnt darkrp
BATM.Config.TakeMoney = function(ply, amount)
	ply:addMoney(amount * -1)
end

--This function should return true of false if the player can afford the amount
--Only edit this you are running a custom gamemode that isnt darkrp
BATM.Config.CanAfford = function(ply, amount)
	return ply:canAfford(amount)
end

--The DARKRP ADD ENTITY IS LOCATED IN blues-atm/lua/autorun/sh_batm.lua edit there if you want to change it