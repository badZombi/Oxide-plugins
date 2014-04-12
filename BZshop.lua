PLUGIN.Title = "BZShop"
PLUGIN.Description = "Buy stuff in-game with RTC"
PLUGIN.Version = "0.5"
PLUGIN.ConfigVersion = "0.2"
PLUGIN.Author = "BadZombi"
print( "Loading " .. PLUGIN.Title .. " V: " .. PLUGIN.Version .. " ..." )


-- TODO:
-- Remove Oxmin stuff... not needed and can conflict
-- maybe play with moving a bunch of stuff to BZutils and using plugins.Find to save space

--Gets the function to call date time
local dateTime = util.GetStaticPropertyGetter( System.DateTime, 'Now' )
if not fileLog then fileLog = {} end

local function touri(datatable)
	if datatable ~= nil then
		local uri = ''
		for k,v in pairs(datatable) do 
			uri = uri .. "&" .. k .. "=" .. v 
		end

		return uri
	else

	end
end

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

	self:AddChatCommands();

	local b, res = config.Read( self.Title )
	self.Config = res or {}
	if (not b) then
		print("Loading Default " .. self.Title .. " Config...")
		self:LoadDefaultConfig()
		if (res) then config.Save( self.Title ) end
	end
	if ( self.Config.configVersion ~= self.ConfigVersion) then
		print("Out of date " .. self.Title .." Config, Updating!")
		--Note old values will be replaced until update 1.5
		self:LoadDefaultConfig()
		config.Save( "BZ Shop" )
	end
	

	self:AddChatCommand( "Shop", self.setConfigValue)
	oxmin_Plugin = plugins.Find("oxmin")

	if not oxmin_Plugin or not oxmin then
		print("Flag BZShop not added! Requires Oxmin")
		self.oxminInstalled = false
		return
	else
		self.FLAG_BZSHOP = oxmin.AddFlag("BZshop")
		self.oxminInstalled = true
		print("Flag BZShop added!")
	end
	self:getInventory()
end

function PLUGIN:getInventory()

	local BASEURL = self.Config.serverAddress .. self.Config.serverScript
	local URLSTRING = "?serverID=" .. self.Config.serverID .. "&pass=" .. self.Config.serverPassword .. "&action=getInventory";

	local b = webrequest.Send(( BASEURL .. URLSTRING), function( resCode, response )
		if resCode == 200 then
			--print(response)

			local returnData = json.decode(response)
			if (not returnData) then
				print('BZShop error: Inventory failed to load!');
				return
			end			
			
			if returnData['inventory'] then
				print('BZshop inventory loaded from website!')
				self.ShopItems = returnData['inventory']
			end

		else
			print('BZShop error: Inventory failed to load!');
			return
		end

	end )

end


function PLUGIN:LoadDefaultConfig()
	self.Config.configVersion = self.ConfigVersion
	self.Config.chatName = "Shop"
	self.Config.shopactive = true
	self.Config.useQueue = false 
	self.Config.serverAddress = "http://rustard.com/" -- address requires trailing slash
	self.Config.serverScript = "logger"
	self.Config.serverID = "123456"
	self.Config.serverPassword = "notsetyet"
	self.Config.showServerResponse = false
	self.Config.currencyName = 'RTC'
end

function PLUGIN:AddChatCommands()
    self:AddChatCommand( "shop", self.cmdShop );
    self:AddChatCommand( "buy", self.cmdBuy );
    self:AddChatCommand( "wallet", self.cmdWallet );
end

function PLUGIN:cmdShop(netuser, cmd, args)

	if args[1] == 'help' then

		rust.SendChatToUser( netuser, self.Config.chatName,'Here are a few things you may need to know...' );
		rust.SendChatToUser( netuser, self.Config.chatName,'use "/shop" in chat to see whats for sale.' );
		rust.SendChatToUser( netuser, self.Config.chatName,'use "/buy #" with the item number from /shop to purchase.' );
		rust.SendChatToUser( netuser, self.Config.chatName,'use "/wallet" to see how many '..self.Config.currencyName..' you have saved.' );
		rust.SendChatToUser( netuser, self.Config.chatName,'You can always check out RusTard.com for more info.' );

	else

		if self.ShopItems then 
			rust.SendChatToUser( netuser, self.Config.chatName,'Welcome to the Shop! Here are the available items:' );
			rust.SendChatToUser( netuser, self.Config.chatName,'--------------------------------------------------' );
			local itemlist = self.ShopItems
			local count = 1
			for k,v in pairs(itemlist) do 
		    	local item = itemlist[k]
		    	rust.SendChatToUser( netuser, self.Config.chatName, k .. ': ' .. item['name'] ..' - '..item['price']..' '..self.Config.currencyName );
		    end

			rust.SendChatToUser( netuser, self.Config.chatName,'--------------------------------------------------' );
			rust.SendChatToUser( netuser, self.Config.chatName,'Type "/shop help" in chat for more info.' );
			rust.SendChatToUser( netuser, self.Config.chatName,'--------------------------------------------------' );
		else
			rust.SendChatToUser( netuser, self.Config.chatName,'Sadly there is nothing in the shop right now.' );
			rust.SendChatToUser( netuser, self.Config.chatName,'Check the website (RusTard.com) or ask an admin if there is a problem.' );
		end

	end

end

function PLUGIN:cmdBuy(netuser, cmd, args)

	rust.SendChatToUser( netuser, self.Config.chatName,'Sorry. The buy feature has not been fully implemented yet.' );
	--rust.SendChatToUser( netuser, self.Config.chatName,'We\'ll let everyone know when its ready.' );
	if args[1] then 
		local number = tonumber(args[1])
		rust.SendChatToUser( netuser, self.Config.chatName,'If it was, you would have just placed an order for:' );
		local selecteditem = self.ShopItems[number]
		rust.SendChatToUser( netuser, self.Config.chatName,selecteditem['amount']..' "'..selecteditem['item']..'"' );
	end


end

function PLUGIN:cmdWallet(netuser)

	rust.SendChatToUser( netuser, self.Config.chatName,'Checking wallet balance...' );

	local BASEURL = self.Config.serverAddress .. self.Config.serverScript
	local URLSTRING = "?serverID=" .. self.Config.serverID .. "&pass=" .. self.Config.serverPassword .. "&action=getWallet&steam_id=" .. rust.CommunityIDToSteamID( tonumber( rust.GetUserID( netuser ) ) );

	local b = webrequest.Send(( BASEURL .. URLSTRING), function( resCode, response )
		if resCode == 200 then
			--print(response)

			local returnData = json.decode(response)
			if (not returnData) then
				rust.SendChatToUser( netuser, self.Config.chatName,'Something went wrong... we couldn\'t find your account.' );
				rust.SendChatToUser( netuser, self.Config.chatName,'Please try again in a few minutes.' );
				print('BZShop error: Wallet data retrieval failed!');
				return
			end			
			
			if returnData['wallet'] then
				rust.SendChatToUser( netuser, self.Config.chatName,'Your wallet currently holds '..returnData['wallet']..' '..self.Config.currencyName );
			end

		else
			rust.SendChatToUser( netuser, self.Config.chatName,'Something went wrong... we couldn\'t find your account.' );
			rust.SendChatToUser( netuser, self.Config.chatName,'Please try again in a few minutes.' );
			print('BZShop error: Wallet request server error!');
			return
		end

	end )


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

function PLUGIN:sendtosite(data)

	
	local CALLBACK = false
	local BASEURL = self.Config.serverAddress .. self.Config.serverScript
	local URLSTRING = "?serverID=" .. self.Config.serverID .. "&pass=" .. self.Config.serverPassword .. touri(killData);
	if killData['callback'] ~= nil then
		CALLBACK = killData['callback']
	end
	if self.Config.useQueue and noQueue == nil then
		-- print("x " .. CALLBACK .. 'x')
		api.Call("BZQueueBind", "QueueMsg", self.Title, BASEURL, URLSTRING, CALLBACK)
	else
		local b = webrequest.Send(( BASEURL .. URLSTRING), function( code, response )
			if self.Config.showServerResponse then
				rust.BroadcastChat(self.Config.chatName, response)
			end
		end )
	end
	
end

function PLUGIN:reward( response )
	local rewardData = json.decode(response)

	if (not rewardData) then
		error( "json decode error during reward response" )
		return
	end

	if rewardData['reward'] and rewardData['player'] then
		targUser = findNetUserByID(rewardData['player'])
		rust.InventoryNotice(targUser, rewardData['reward'])
		print(rewardData['player'] .. ": " .. rewardData['reward'])
	end
end

function PLUGIN:tosteamid(somedata)

	return rust.CommunityIDToSteamID( tonumber( rust.GetUserID( somedata ) ) )
end

function PLUGIN:datetime()

	local nowtime = util.GetStaticPropertyGetter( System.DateTime, 'Now' )
	return nowtime().Year .. "|" .. nowtime().Month .. "|" .. nowtime().Day .. "|" .. nowtime().Hour .. "|" .. nowtime().Minute .. "|" .. nowtime().Second
end


api.Bind( PLUGIN, "BZStoreBind" )

