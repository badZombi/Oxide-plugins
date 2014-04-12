PLUGIN.Title = "BZ Users"
PLUGIN.Description = "Track server and user activity on website..."
PLUGIN.Version = "0.1"
PLUGIN.ConfigVersion = "0.1"
PLUGIN.Author = "BadZombi"
PLUGIN.Cfgfile = "BZUsers"
print( "Loading " .. PLUGIN.Title .. " V: " .. PLUGIN.Version .. " ..." )

local dateTime = util.GetStaticPropertyGetter( System.DateTime, 'Now' )

local function touri(datatable)
	if datatable ~= nil then
		local uri = ''
		for k,v in pairs(datatable) do 
			uri = uri .. "&" .. k .. "=" .. v 
		end
		return uri
	end
end

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

function PLUGIN:datetime()
	local nowtime = util.GetStaticPropertyGetter( System.DateTime, 'Now' )
	return nowtime().Year .. "|" .. nowtime().Month .. "|" .. nowtime().Day .. "|" .. nowtime().Hour .. "|" .. nowtime().Minute .. "|" .. nowtime().Second
end

function PLUGIN:Init()

	local b, res = config.Read( self.Cfgfile )
	self.Config = res or {}
	if (not b) then
		print("Loading Default " .. self.Title .. " Config...")
		self:LoadDefaultConfig()
		if (res) then config.Save( self.Cfgfile ) end
	end
	if ( self.Config.configVersion ~= self.ConfigVersion) then
		print("Out of date " .. self.Title .." Config, Updating!")
		self:LoadDefaultConfig()
		config.Save( self.Cfgfile )
	end
	
	-- send init to server
	local Itimestamp = self:datetime()
	local initUpdate = {}
	initUpdate["action"] = "ServerInit"
	initUpdate["time"] = Itimestamp

	self:updatesite(initUpdate, true);

	-- add timer timing to config file... for now hardcode at 15 sec?
	self.myTimer = timer.Repeat(60, 0, function() self:updateCurrentPlayers() end)

end

function PLUGIN:LoadDefaultConfig()
	self.Config.configVersion = self.ConfigVersion
	self.Config.useQueue = false
	self.Config.serverAddress = "http://rustard.com/" -- address requires trailing slash
	self.Config.serverScript = "logger"
	self.Config.serverID = ""
	self.Config.serverPassword = ""
	self.Config.showServerResponse = false

end

function PLUGIN:updatesite(data, noQueue)

	local BASEURL = self.Config.serverAddress .. self.Config.serverScript
	local URLSTRING = "?serverID=" .. self.Config.serverID .. "&pass=" .. self.Config.serverPassword .. touri(data);
	
	if self.Config.useQueue and noQueue == nil then
		api.Call("BZQueueBind", "QueueMsg", self.Title, BASEURL, URLSTRING)
	else
		local b = webrequest.Send(( BASEURL .. URLSTRING), function( code, response )
			if self.Config.showServerResponse then
				rust.BroadcastChat('BZusers debug', response)
			end
		end )
	end

end

function PLUGIN:OnUserConnect( netuser )

	local userdata = {};
	userdata['action'] = 'connect'
	userdata['userid'] = rust.GetUserID( netuser )
	userdata['sid'] = rust.CommunityIDToSteamID( tonumber( rust.GetUserID( netuser ) ) )
	userdata['name'] = netuser.displayName

	self:updatesite(userdata)
	
end

function PLUGIN:OnUserDisconnect( networkplayer )

	local netuser = networkplayer:GetLocalData()
	if (not netuser or netuser:GetType().Name ~= "NetUser") then return end
	local sid = rust.CommunityIDToSteamID( tonumber( rust.GetUserID( netuser ) ) )

	local userdata = {};
	userdata['action'] = 'disconnect'
	userdata['sid'] = rust.CommunityIDToSteamID( tonumber( rust.GetUserID( netuser ) ) )
	
	self:updatesite(userdata)

end

-- maybe make this queue later using BZqueue ... need to add a POST function to that though.
function PLUGIN:updateCurrentPlayers()
	local updatePlayers = {}
	local playerTable = rust.GetAllNetUsers();
	local i = 1;
    while playerTable[i] do
		local netuser = playerTable[i];
		if(netuser) then
			updatePlayers[i] =  tonumber( rust.GetUserID( netuser ) ) 
		end
		i = i + 1;
    end
    -- send updatePlayers to site with post...
    local Chunk = json.encode(updatePlayers)
    local BASEURL = self.Config.serverAddress .. self.Config.serverScript
    local URLSTRING = "serverID=" .. self.Config.serverID .. "&pass=" .. self.Config.serverPassword .. "&action=update_online&players=";
    --rust.BroadcastChat('debugger', URLSTRING)
    --rust.BroadcastChat('debugger', 'sending')
    local request = webrequest.Post(BASEURL, URLSTRING .. Chunk, function(code, response)
    	--rust.BroadcastChat('foobar', response)

    end)

   
   
end
