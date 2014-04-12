PLUGIN.Title = "Prayer"
PLUGIN.Description = "Ask the Rust gods for favors..."
PLUGIN.Version = "0.5"
PLUGIN.ConfigVersion = "0.2"
PLUGIN.Author = "BadZombi"
print( "Loading " .. PLUGIN.Title .. " V: " .. PLUGIN.Version .. " ..." )


-- TODO:
-- Remove Oxmin stuff... not needed and can conflict
-- maybe play with moving a bunch of stuff to BZutils and using plugins.Find to save space

--Gets the function to call date time
local dateTime = util.GetStaticPropertyGetter( System.DateTime, 'Now' )

--Thanks to user973713
local function split(str, delimiter)
    result = {};
	if delimiter == nil then
                delimiter = "%s"
    end
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end
--True for date false for date + time
local function getTimeOrDate(dtB)
	local dt = split(tostring(dateTime()))
	local date = dt[1]
	local time = dt[2]
	local ap = dt[3]
	
	local dateSplit = split(date,"/")
	if (string.len(dateSplit[1]) == 1) then dateSplit[1] = "0"..dateSplit[1] end 
	date = table.concat( {dateSplit[1], dateSplit[2], dateSplit[3] }, "-" )
	
	local timeSplit = split(time,":")
	if ap == "PM:" then timeSplit[1] = tonumber( timeSplit[1] ) + 12 end
	time = table.concat( timeSplit, ":" )
	
	if dtB then return "(" .. date .. ")"end
	return "(" .. date .. " " .. time .. ")"
end

local function findNetUserByID(userID)
    allnetusers = rust.GetAllNetUsers()
    if (not allnetusers) then 
    	return 
    end
    local tmp = {}

    for i=1, #allnetusers do
    	local netuser = allnetusers[i]
    	if (rust.GetUserID(netuser) == userID) then
    		return netuser
    	end
    end
end

function PLUGIN:Init()

	self.PrayerDB = util.GetDatafile( "prayer_list" )
	if (self.PrayerDB:GetText() == "") then
		self.Prayers = {}
	else
		self.Prayers = json.decode( self.PrayerDB:GetText() )
		if (not self.Prayers) then
			error( "could not decode the prayer list" )
			self.Prayers = {}
		end
	end

	print(dateTime)

--	self:AddChatCommands();
--
--	local b, res = config.Read( self.Title )
--	self.Config = res or {}
--	if (not b) then
--		print("Loading Default " .. self.Title .. " Config...")
--		self:LoadDefaultConfig()
--		if (res) then config.Save( self.Title ) end
--	end
--	if ( self.Config.configVersion ~= self.ConfigVersion) then
--		print("Out of date " .. self.Title .." Config, Updating!")
--		--Note old values will be replaced until update 1.5
--		self:LoadDefaultConfig()
--		config.Save( "BZ Shop" )
--	end
--	
--
--	self:AddChatCommand( "Shop", self.setConfigValue)
--	oxmin_Plugin = plugins.Find("oxmin")
--
--	if not oxmin_Plugin or not oxmin then
--		print("Flag BZShop not added! Requires Oxmin")
--		self.oxminInstalled = false
--		return
--	else
--		self.FLAG_BZSHOP = oxmin.AddFlag("BZshop")
--		self.oxminInstalled = true
--		print("Flag BZShop added!")
--	end
--	self:getInventory()
end

function PLUGIN:LoadDefaultConfig()
	self.Config.configVersion = self.ConfigVersion
	self.Config.chatName = "Prayer"
end

function PLUGIN:AddChatCommands()
    self:AddChatCommand( "shop", self.cmdShop );
end

--Gets user data from datastore
function PLUGIN:GetUserData( netuser )
	local userID = rust.GetUserID( netuser );
	return self:GetUserDataFromID(netuser, userID, netuser.displayName );
end

function PLUGIN:GetUserDataFromID(netuser, userID, name )
	local userentry = self.JsonData[ userID ];
	--Create user if user is not present in datastore
	if (not userentry) then
		userentry = {};
		userentry.LoggedOn=1;
		userentry.ID = userID;
		userentry.Name = name;
		userentry.X = self.X;
		userentry.Y = self.Y;
		userentry.Z = self.Z;
		self.JsonData[ userID ] = userentry;
        self:Save();
	end
	return userentry;
end

function PLUGIN:tosteamid(somedata)

	return rust.CommunityIDToSteamID( tonumber( rust.GetUserID( somedata ) ) )
end

function PLUGIN:datetime()

	local nowtime = util.GetStaticPropertyGetter( System.DateTime, 'Now' )
	return nowtime().Year .. "|" .. nowtime().Month .. "|" .. nowtime().Day .. "|" .. nowtime().Hour .. "|" .. nowtime().Minute .. "|" .. nowtime().Second
end


api.Bind( PLUGIN, "BZStoreBind" )

