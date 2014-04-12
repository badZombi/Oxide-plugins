PLUGIN.Title = "BZ location an tracking mod"
PLUGIN.Description = "Location command for players... can be saved to remote host"
PLUGIN.Version = "0.1.5"
PLUGIN.ConfigVersion = "0.2"
PLUGIN.Author = "BadZombi"
print( "Loading " .. PLUGIN.Title .. " V: " .. PLUGIN.Version .. " ..." )

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

function PLUGIN:tablelength(stuff)
    local icount = 0
    for k in pairs(stuff) do 
        icount = icount + 1
    end
    return icount
end

function PLUGIN:debug(message, forcetolog)
    if forcetolog ~= nil then
        forcetolog = true;
    end

    if self.Config.chatDebug then
        rust.BroadcastChat("debug", message)
    end

    if self.Config.logDebug or forcetolog == true then
        print(self.Title .. " debug message: " .. message)
    end

end

--Server initialization of the plugin
function PLUGIN:Init()
        --Add chat commands
        self:AddChatCommands();
        self.lastPos = {};

        local b, res = config.Read( "BZLoc" )
        self.Config = res or {}
        if (not b) then
            print("Creating new BZLoc Config...")
            self:LoadDefaultConfig()
            if (res) then config.Save( "BZLoc" ) end
        end
        if ( self.Config.configVersion ~= self.ConfigVersion) then
            print( "BZloc config file is out of date... Creating new file. Be sure to update settings!")
            --Note old values will be replaced until update 1.5
            self:LoadDefaultConfig()
            config.Save( "BZLoc" )
        end

        -- add timer timing to config file... for now hardcode at 15 sec?
        self.myTimer = timer.Repeat(3, 0, function() self:allPlayersToWebsite() end)

        print("Completed loading of BZLoc plugin.")

end

function PLUGIN:LoadDefaultConfig()
    self.Config.configVersion = self.ConfigVersion
    self.Config.logToWebsite = false
    self.Config.useQueue = false 
    self.Config.serverAddress = "http://YourDomainOrIpAddress/" -- address requires trailing slash
    self.Config.serverScript = "logger"
    self.Config.serverID = "12345"
    self.Config.serverPassword = "YourPassword"
    self.Config.showServerResponse = false -- only works when NOT using BZqueue still need to add callbacks for Queued sends.
    self.Config.msgName = "Location" -- who does the message about location come from in chat?
    self.Config.locDelimiter = ", "
    self.Config.timeDelimiter = "|"
end

function PLUGIN:updatesite(locData)
    if self.Config.logToWebsite then
        local BASEURL = self.Config.serverAddress .. self.Config.serverScript
        local URLSTRING = "?action=location&serverID=" .. self.Config.serverID .. "&pass=" .. self.Config.serverPassword .. touri(locData);
        
        if self.Config.useQueue then
            api.Call("BZQueueBind", "QueueMsg", self.Title, BASEURL, URLSTRING)
        else
            local b = webrequest.Send(( BASEURL .. URLSTRING), function( code, response )
                if self.Config.showServerResponse then
                    rust.BroadcastChat(self.Config.msgName, response)
                end
            end )
        end
    end 

end
 
--Adds chat commands to the server
function PLUGIN:AddChatCommands()
    self:AddChatCommand( "loc", self.cmdLoc );
    --self:AddChatCommand( "ploc", self.cmdPloc );
    -- delete
    --self:AddChatCommand( "startrec", self.startrecording );
    --self:AddChatCommand( "stoprec", self.stoprecording );
end

-- delete all this shit after getting the map road done:


--function PLUGIN:startrecording(netuser)
--    print('plotter started')
--    self.plotcount = 0;
--    self.plotData = {}
--    self.myTimer = timer.Repeat(5, 0, function() self:autoLog(netuser) end)
--end
--
--function PLUGIN:stoprecording()
--    print('plotter stopped')
--    self.myTimer:Destroy()
--    self.myTimer = nil;
--end
--
--function PLUGIN:autoLog(netuser)
--
--   
--    -- save time for web
--    self.plotData['time'] = self:datetime()
--    self.plotData['location_name'] = "plot" .. self.plotcount
--    --print(self.plotData['location_name'])
--    
--    --local targetUser = rust.FindNetUsersByName( "BadZombi" )
--    self.plotcount = self.plotcount + 1
--    self.plotData['steam_id'] = tonumber( rust.GetUserID( netuser ) )
--    self.plotData['displayname'] = netuser.displayName
--    --print(self.plotData['steam_id'])
--    
--    self.plotData['position'] = self:getUserLocationWeb(netuser)
--    --print(self.plotData['position'])
--
--    rust.SendChatToUser( netuser, self.Config.msgName,"Autologged '".. self.plotData['location_name'] )--;
--    self:updatesite(self.plotData)
--
--    --self.plotcount = self.plotcount + 1
--   
--    
--end


-- end delete all this shit

function PLUGIN:datetime()

    local nowtime = util.GetStaticPropertyGetter( System.DateTime, 'Now' )
    return nowtime().Year .. self.Config.timeDelimiter .. nowtime().Month .. self.Config.timeDelimiter .. nowtime().Day .. self.Config.timeDelimiter .. nowtime().Hour .. self.Config.timeDelimiter .. nowtime().Minute .. self.Config.timeDelimiter .. nowtime().Second
end

function PLUGIN:tosteamid(somedata)
    return rust.CommunityIDToSteamID( tonumber( rust.GetUserID( somedata ) ) )
end

--Shows user location and direction
function PLUGIN:cmdLoc(netuser, cmd, args)

    if (args[2]) then
        rust.SendChatToUser( netuser, self.Config.msgName,'To save a location on RusTard.com type: /loc "Name Here"' );
        rust.SendChatToUser( netuser, self.Config.msgName,'(name must be enclosed in quotes if it has a space)' );
        rust.SendChatToUser( netuser, self.Config.msgName,'Just use /loc (with no name) if you dont want to save this position.' );
        return
    end

    local locData = {}
    -- save time for web
    locData['time'] = self:datetime()

    rust.SendChatToUser( netuser, self.Config.msgName,"Your current location id: " .. self:findNearestPoint(netuser) .. " " .. self:getUserLocation(netuser) );
    rust.SendChatToUser( netuser, self.Config.msgName,"You are facing " .. self:getUserDirection(netuser) );

    if (args[1]) then
        locData['location_name'] = args[1]
        locData['steam_id'] = tonumber( rust.GetUserID( netuser ) )
        locData['displayname'] = netuser.displayName
        locData['position'] = self:getUserLocationWeb(netuser)
        rust.SendChatToUser( netuser, self.Config.msgName,"Location will be saved as '".. locData['location_name'] .."' on RusTard.com" );
        self:updatesite(locData)
    end

    

   
    
    
end

function PLUGIN:cmdPloc(netuser, cmd, args)
    local locData = {}
    
    if (not netuser:CanAdmin()) then
        return
    end

    -- Get the target user
    local b, targetuser = rust.FindNetUsersByName( args[1] )
    if (not b) then
        if (targetuser == 0) then
            rust.Notice( netuser, "No players found with that name!" )
        else
            rust.Notice( netuser, "Multiple players found with that name!" )
        end
        return
    end

    rust.SendChatToUser( netuser, targetuser.displayName .. "'s current location: " .. self:findNearestPoint(targetuser) .. " " .. self:getUserLocation(targetuser) );
    rust.SendChatToUser( netuser, "They are currently facing " .. self:getUserDirection(targetuser) );
end

function PLUGIN:compassLetter(dir)
        if (dir > 337.5) or (dir < 22.5) then
                return "North"
        elseif (dir >= 22.5) and (dir <= 67.5) then
                return "Northeast"
        elseif (dir > 67.5) and (dir < 112.5) then
                return "East"
        elseif (dir >= 112.5) and (dir <= 157.5) then
                return "Southeast"
        elseif (dir > 157.5) and (dir < 202.5) then
                return "South"
        elseif (dir >= 202.5) and (dir <= 247.5) then
                return "Southwest"
        elseif (dir > 247.5) and (dir < 292.5) then
                return "West"
        elseif (dir >= 292.5) and (dir <= 337.5) then
                return "Northwest"
        end
end
 
function PLUGIN:getUserDirection(netuser)
        local controllable = netuser.playerClient.controllable
        local char = controllable:GetComponent( "Character" )
        -- Convert unit circle angle to compass angle. 
        -- Known error: char.eyesYaw randomly returns a String value and breaks output
        local direction = (char.eyesYaw+90)%360
 
        return self:compassLetter(direction)
end

function PLUGIN:getUserLocation(netuser)
        local coords = netuser.playerClient.lastKnownPosition
        return "(x : " .. math.floor(coords.x) .. ", y : " .. math.floor(coords.y) .. ", z : " .. math.floor(coords.z) .. ")"
end

function PLUGIN:getUserLocationWeb(netuser)
    local coords = netuser.playerClient.lastKnownPosition
    return math.floor(coords.x) .. self.Config.locDelimiter .. math.floor(coords.y) .. self.Config.locDelimiter .. math.floor(coords.z)
end

function PLUGIN:findNearestPoint(netuser)
        local coords = netuser.playerClient.lastKnownPosition
        local points = {
            { name = "Hacker Valley South", x = 5907, z = -1848 },
            { name = "Hacker Mountain South", x = 5268, z = -1961 },
            { name = "Hacker Valley Middle", x = 5268, z = -2700 },
            { name = "Hacker Mountain North", x = 4529, z = -2274 },
            { name = "Hacker Valley North", x = 4416, z = -2813 },
            { name = "Wasteland North", x = 3208, z = -4191 },
            { name = "Wasteland South", x = 6433, z = -2374 },
            { name = "Wasteland East", x = 4942, z = -2061 },
            { name = "Wasteland West", x = 3827, z = -5682 },
            { name = "Sweden", x = 3677, z = -4617 },
            { name = "Everust Mountain", x = 5005, z = -3226 },
            { name = "North Everust Mountain", x = 4316, z = -3439 },
            { name = "South Everust Mountain", x = 5907, z = -2700 },
            { name = "Metal Valley", x = 6825, z = -3038 },
            { name = "Metal Mountain", x = 7185, z = -3339 },
            { name = "Metal Hill", x = 5055, z = -5256 },
            { name = "Resource Mountain", x = 5268, z = -3665 },
            { name = "Resource Valley", x = 5531, z = -3552 },
            { name = "Resource Hole", x = 6942, z = -3502 },
            { name = "Resource Road", x = 6659, z = -3527 },
            { name = "Beach", x = 5494, z = -5770 },
            { name = "Beach Mountain", x = 5108, z = -5875 },
            { name = "Coast Valley", x = 5501, z = -5286 },
            { name = "Coast Mountain", x = 5750, z = -4677 },
            { name = "Coast Resource", x = 6120, z = -4930 },
            { name = "Secret Mountain", x = 6709, z = -4730 },
            { name = "Secret Valley", x = 7085, z = -4617 },
            { name = "Factory Radtown", x = 6446, z = -4667 },
            { name = "Small Radtown", x = 6120, z = -3452 },
            { name = "Big Radtown", x = 5218, z = -4800 },
            { name = "Hangar", x = 6809, z = -4304 },
            { name = "Tanks", x = 6859, z = -3865 },
            { name = "Civilian Forest", x = 6659, z = -4028 },
            { name = "Civilian Mountain", x = 6346, z = -4028 },
            { name = "Civilian Road", x = 6120, z = -4404 },
            { name = "Ballzack Mountain", x =4316, z = -5682 },
            { name = "Ballzack Valley", x = 4720, z = -5660 },
            { name = "Spain Valley", x = 4742, z = -5143 },
            { name = "Portugal Mountain", x = 4203, z = -4570 },
            { name = "Portugal", x = 4579, z = -4637 },
            { name = "Lone Tree Mountain", x = 4842, z = -4354 },
            { name = "Forest", x = 5368, z = -4434 },
            { name = "Rad-Town Valley", x = 5907, z = -3400 },
            { name = "Next Valley", x = 4955, z = -3900 },
            { name = "Silk Valley", x = 5674, z = -4048 },
            { name = "French Valley", x = 5995, z = -3978 },
            { name = "Ecko Valley", x = 7085, z = -3815 },
            { name = "Ecko Mountain", x = 7348, z = -4100 },
            { name = "Middle Mountain", x = 6346, z = -4028 },
            { name = "Zombie Hill", x = 6396, z = -3428 }
        }

        local min = -1
        local minIndex = -1
        for i = 1, #points do
           if (minIndex==-1) then
                min = (points[i].x-coords.x)^2+(points[i].z-coords.z)^2
                minIndex = i
           else
                local dist = (points[i].x-coords.x)^2+(points[i].z-coords.z)^2
                if (dist<min) then
                    min = dist
                    minIndex = i
                end
           end
        end

        return points[minIndex].name
end


function PLUGIN:allPlayersToWebsite()
    local updatePlayers = {}
    local playerTable = rust.GetAllNetUsers();
    local playersOnline = self:tablelength(playerTable);
    --rust.BroadcastChat('loc debug', 'boo')
    if playersOnline >= 1 then
        local i = 1;
        while playerTable[i] do
            local netuser = playerTable[i];
            if(netuser) then
                local thisUser = tonumber( rust.GetUserID( netuser ) )
                local curPos = self:getUserLocationWeb( netuser )
                --rust.BroadcastChat('loc debug', self.lastPos[thisuser] .. ' : ' .. curPos)

                if self.lastPos[thisUser] == nil then
                    --rust.BroadcastChat('loc debug', 'not set yet... doing it now:'..thisUser..":"..curPos)
                    local tmpTable = {}
                    tmpTable['position'] = curPos
                    tmpTable['user'] = thisUser 
                    self.lastPos[thisUser] = curPos;
                    updatePlayers[i] =  tmpTable
                elseif self.lastPos[thisUser] ~= curPos then
                    --rust.BroadcastChat('loc debug', 'position has changed')
                    local tmpTable = {}
                    tmpTable['position'] = curPos
                    tmpTable['user'] = thisUser 
                    self.lastPos[thisUser] = curPos;
                    updatePlayers[i] =  tmpTable
                else
                    --rust.BroadcastChat('loc debug', 'same position. user has not moved')
                    return
                end 

            end
            i = i + 1;
        end

        -- send updatePlayers to site with post...
        local Chunk = json.encode(updatePlayers)
        --rust.BroadcastChat('loc debug', Chunk)
        local BASEURL = self.Config.serverAddress .. self.Config.serverScript
        local URLSTRING = "serverID=" .. self.Config.serverID .. "&pass=" .. self.Config.serverPassword .. "&action=updatePlayerPositions&playerData=";
        local request = webrequest.Post(BASEURL, URLSTRING .. Chunk, function(code, response)
            --print(response)
        end)
    else
        --print('no players online')
    end

   
   
end
 
function PLUGIN:SendHelpText(netuser)
    rust.SendChatToUser( netuser, "Use /loc to find out where you are. Add a name to save the location to your map on RusTard.com!");
end