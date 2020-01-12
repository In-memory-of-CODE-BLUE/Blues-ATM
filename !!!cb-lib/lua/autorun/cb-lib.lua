if _G.CBLib ~= nil then return _G.CBLib end --Prevent Lua refresh.

local CBLib = {}

--[[-------------------------------------------------------------------------
Helper functions
---------------------------------------------------------------------------]]
CBLib.Helper = {}

--Formats a number as a string with commas inserted
function CBLib.Helper.CommaFormatNumber(amount)
	local formatted = amount
	while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then
			break
		end
	end 
	return formatted
end

--Credit to facepunch (Didnt see guys name)
--Retursn the text in a table for, an index for each new line
function CBLib.Helper.WrapText(Str,font,width)
	if( font ) then  --Dr Magnusson's much less prone to failure and more optimized version
         surface.SetFont( font )  
     end  
       
     local tbl, len, Start, End = {}, string.len( Str ), 1, 1  
       
     while ( End < len ) do  
         End = End + 1  
         if ( surface.GetTextSize( string.sub( Str, Start, End ) ) > width ) then  
             local n = string.sub( Str, End, End )  
             local I = 0  
             for i = 1, 15 do  
                 I = i  
                 if( n != " " and n != "," and n != "." and n != "\n" ) then  
                     End = End - 1  
                     n = string.sub( Str, End, End )  
                 else  
                     break  
                 end  
             end  
             if( I == 15 ) then  
                 End = End + 14  
             end  
               
             local FnlStr = string.Trim( string.sub( Str, Start, End ) )  
             table.insert( tbl, FnlStr )  
             Start = End + 1  
         end                   
     end  
     table.insert( tbl, string.sub( Str, Start, End ) )  
     return tbl 
end



-----------------------------
--		   MODULES 	       --
-----------------------------

--Modules are basicly instances of a table. This handles loading and destroying modules.
--Or anouther way to look at it is like a static class in an oop language.

--A module can also contain three event functions, OnLoaded, OnUnloaded, and OnReloaded

--A Table for all modules loaded.
CBLib.Modules = {}

--loads a module script and stores a reference, if a module is loaded of the same name then 
--the function will instead return the already loaded module to prevent reloading of them.
--Unless you pass true for reload the module will not be reloaded but instead return the current instance.
--Subfolder is a folder you know its located in, even if its in anouther folder. For example store you modules in lua/codebluemodules then supply lua/codebluemodules as the subfolder
function CBLib.LoadModule(modulePath, reload)
	reload = reload or false 

	--Check if a module was found
	if modulePath == nil then
		CBLib.Debug.Error("Failed to load module '"..modulePath.."'. Module not found...")
		return
	end

	--We must re-load the module
	if reload then 
		CBLib.Modules[modulePath] = nil --Destroy the old reference
	end

	--This will either return the already created module, or it will create a new one
	if CBLib.Modules[modulePath] == nil then

		--Load the module code.
		local moduleContents = file.Read(modulePath, "lsv")

		local module = nil
		include(modulePath)

		if CBLIB_MODULE ~= nil then
			module = CBLIB_MODULE
			CBLIB_MODULE = nil
		else
			CBLib.Debug.Error("Tried to locate module @"..modulePath.." but the module returned nothing, it either does not exist or has produced an error!")
			return
		end

		CBLib.Debug.Info("Loaded Module : "..modulePath)

		--Did compile string return an error?
		if isstring(module) then
			CBLib.Debug.Error("Failed to load module. Error : "..module)
		else
			--Execute the module
			CBLib.Modules[modulePath] = module

			if CBLib.Modules[modulePath].OnLoaded then
				CBLib.Modules[modulePath].OnLoaded()
			end

			if reload and CBLib.Modules[modulePath].OnReloaded then
				CBLib.Modules[modulePath].OnReloaded()
			end
		end
	end

	--Return the reference.
	return CBLib.Modules[modulePath]
end


--Altough it does not destroy 'copies' of the module it does remove the reference stored here.
function CBLib.UnloadModule(modulePath)
	if CBLib.Modules[modulePath].OnUnloaded then
		CBLib.Modules[modulePath].OnUnloaded()
	end

	CBLib.Modules[modulePath] = nil
end

--Scans for all modules and sends any client/shared ones to the server using AddCSLuaFile()
function CBLib.NetworkModules()
	local base = ""

	local function ScanForClientSideModules(first, currentDirectory, currentFiles, path)
		if first then
			currentFiles, currentDirectory = file.Find("*", "lsv")
			path = base
			first = false  
		else
			currentFiles, currentDirectory = file.Find(path.."/*", "lsv")
		end  

		for k ,v in pairs(currentFiles) do
			--Client
			if string.find( v, "bmcl_" ) then
				local modulePath = path.."/"..v --Found it!
				AddCSLuaFile(modulePath)
				CBLib.Debug.Info("Added client side file '"..modulePath.."'")
			end

			--Shared
			if string.find( v, "bmsh_" ) then
				local modulePath = path.."/"..v --Found it!
				AddCSLuaFile(modulePath)
				CBLib.Debug.Info("Added client side file '"..modulePath.."'")
			end
		end 

		for k , v in pairs(currentDirectory) do
			local newPath = ""
			if path == "" then
				newPath = v
			else
				newPath = path.."/"..v
			end

			--Scan again and append directory.
			if ScanForClientSideModules(first, currentDirectory, currentFiles, newPath) then return true end --Cancle scan
		end
	end

	ScanForClientSideModules(true) 
end

----------------------------- 
--		   DEBUG 	       --
-----------------------------

CBLib.Debug = {} --A table with a bunch of debug functions

function CBLib.Debug.Error(message)
	MsgC(Color(255,120,120), "[CB-LIB][ERROR] ", message, "\n")
end

function CBLib.Debug.Warning(message)
	MsgC(Color(255,255,0), "[CB-LIB][WARNING] ", message, "\n")
end

function CBLib.Debug.Info(message)
	MsgC(Color(0,191,255), "[CB-LIB][INFO] ", message, "\n")
end

--Add global reference
_G.CBLib = CBLib

if CLIENT then
	--Done!
	CBLib.Debug.Info("Finished loading CB-LIB client-side")
else
	--Add Clientside modules
	CBLib.NetworkModules()

	--Done!
	CBLib.Debug.Info("Finished loading CB-LIB server-side")
end
