--[[
    Phantom Forces Cheat
        - Herrtt
    
    Discord: discord.gg/NMCv3pMJf8

    Supports
        * No Fall Damage
        * WalkSpeed
        * JumpPower
        * SilentAim
        * Headshot Percentage
        * Wallhacks
    
]]

-- Default launch settings
local settings = {
    silentaim = true,
    nofalldamage = false,

    setwalkspeed = false,
    walkspeed = 55,

    setjumppower = false,
    jumppower = 45,


    headshotchanceenabled = true,
    headshotchance = 25,
    
    --

    fov = 350,
    fovcircle = true,
    fovsides = 12,
    fovthickness = 1
}

local main = {running = true}
local end_funcs = {}
local __SETTINGS__ = {}
function main:End()
    main.running = false
    for _,func in pairs(end_funcs) do
        func()
    end
    if (main == shared.__main) then
        shared.__main = nil -- k
    end

    main = nil
    spawn(function()
        for i,v in pairs(connections) do
            pcall(function() v:Disconnect() end)
        end
    end)
    shared.main = nil -- k
    __SETTINGS__:Save()
end
if shared.__main then
    pcall(shared.__main.End, shared.__main)
    shared.__main = nil
end
shared.__main = main

local connections = {}
local function bindEvent(event, callback) -- Let me disconnect in peace
    local con = event:Connect(callback)
    table.insert(connections, con)
    return con
end
table.insert(end_funcs, function()
    for i,v in pairs(connections) do
        v:Disconnect()
        connections[i] = nil
    end
end)

local servs
servs = setmetatable(
{
    Get = function(self, serv)
        if servs[serv] then return servs[serv] end
        local s = game:GetService(serv)
        if s then servs[serv] = s end
        return s
    end;
}, {
    __index = function(self, index)
        local s = game:GetService(index)
        if s then servs[index] = s end
        return s
    end;
})

local players = servs.Players
local runservice = servs.RunService
local http = servs.HttpService
local uis = servs.UserInputService

local function jsonEncode(t)
    return http:JSONEncode(t)
end
local function jsonDecode(t)
    return http:JSONDecode(t)
end

local function existsFile(name)
    return pcall(function()
        return readfile(name)
    end)
end

local function mergetab(a,b)
    local c = a or {}
    for i,v in pairs(b or {}) do 
        c[i] = v 
    end
    return c
end

local serialize
local deserialize
do
    --/ Serializer : garbage : slow as fuck
	
	local function hex_encode(IN, len)
	    local B,K,OUT,I,D=16,"0123456789ABCDEF","",0,nil
	    while IN>0 do
	        I=I+1
	        IN,D=math.floor(IN/B), IN%B+1
	        OUT=string.sub(K,D,D)..OUT
	    end
		if len then
			OUT = ('0'):rep(len - #OUT) .. OUT
		end
	    return OUT
	end
	local function hex_decode(IN) 
		return tonumber(IN, 16) 
	end

    local types = {
        ["nil"] = "0";
        ["boolean"] = "1";
        ["number"] = "2";
        ["string"] = "3";
        ["table"] = "4";

		["Vector3"] = "5";
		["CFrame"] = "6";
        ["Instance"] = "7";
	
		["Color3"] = "8";
    }
    local rtypes = (function()
        local a = {}
        for i,v in pairs(types) do
            a[v] = i
        end
        return a
    end)()

    local typeof = typeof or type
    local function encode(t, ...)
        local type = typeof(t)
        local s = types[type]
        local c = ''
        if type == "nil" then
            c = types[type] .. "0"
        elseif type == "boolean" then
            local t = t == true and '1' or '0'
            c = s .. t
        elseif type == "number" then
            local new = tostring(t)
            local len = #new
            c = s .. len .. "." .. new
        elseif type == "string" then
            local new = t
            local len = #new
            c = s .. len .. "." .. new
		elseif type == "Vector3" then
			local x,y,z = tostring(t.X), tostring(t.Y), tostring(t.Z)
			local new = hex_encode(#x, 2) .. x .. hex_encode(#y, 2) .. y .. hex_encode(#z, 2) .. z
			c = s .. new
		elseif type == "CFrame" then
			local a = {t:GetComponents()}
			local new = ''
			for i,v in pairs(a) do
				local l = tostring(v)
				new = new .. hex_encode(#l, 2) .. l
			end
			c = s .. new
		elseif type == "Color3" then
			local a = {t.R, t.G, t.B}
			local new = ''
			for i,v in pairs(a) do
				local l = tostring(v)
				new = new .. hex_encode(#l, 2) .. l
			end
			c = s .. new
        elseif type == "table" then
            return serialize(t, ...)
        end
        return c
    end
    local function decode(t, extra)
        local p = 0
        local function read(l)
            l = l or 1
            p = p + l
            return t:sub(p-l + 1, p)
        end
        local function get(a)
            local k = ""
            while p < #t do
                if t:sub(p+1,p+1) == a then
                    break
                else
                    k = k .. read()
                end
            end
            return k
        end
        local type = rtypes[read()]
        local c

        if type == "nil" then
            read()
        elseif type == "boolean" then
            local d = read()
            c = d == "1" and true or false
        elseif type == "number" then
            local length = tonumber(get("."))
            local d = read(length+1):sub(2,-1)
            c = tonumber(d)
        elseif type == "string" then
            local length = tonumber(get(".")) --read()
            local d = read(length+1):sub(2,-1)
            c = d
		elseif type == "Vector3" then
			local function getnext()
				local length = hex_decode(read(2))
				local a = read(tonumber(length))
				return tonumber(a)
			end
			local x,y,z = getnext(),getnext(),getnext()
			c = Vector3.new(x, y, z)
		elseif type == "CFrame" then
			local a = {}
			for i = 1,12 do
				local l = hex_decode(read(2))
				local b = read(tonumber(l))
				a[i] = tonumber(b)
			end
			c = CFrame.new(unpack(a))
        elseif type == "Instance" then
			local pos = hex_decode(read(2))
			c = extra[tonumber(pos)]
		elseif type == "Color3" then
			local a = {}
			for i = 1,3 do
				local l = hex_decode(read(2))
				local b = read(tonumber(l))
				a[i] = tonumber(b)
			end
			c = Color3.new(unpack(a))
        end
        return c
    end

    function serialize(data, p)
		if data == nil then return end
        local type = typeof(data)
        if type == "table" then
            local extra = {}
            local s = types[type]
            local new = ""
            local p = p or 0
            for i,v in pairs(data) do
                local i1,v1
                local t0,t1 = typeof(i), typeof(v)

				local a,b
                if t0 == "Instance" then
                    p = p + 1
                    extra[p] = i
                    i1 = types[t0] .. hex_encode(p, 2)
                else
                    i1, a = encode(i, p)
					if a then
						for i,v in pairs(a) do
							extra[i] = v
						end
					end
                end
                
                if t1 == "Instance" then
                    p = p + 1
                    extra[p] = v
                    v1 = types[t1] .. hex_encode(p, 2)
                else
                    v1, b = encode(v, p)
					if b then
						for i,v in pairs(b) do
							extra[i] = v
						end
					end
                end
                new = new .. i1 .. v1
            end
            return s .. #new .. "." .. new, extra
		elseif type == "Instance" then
			return types[type] .. hex_encode(1, 2), {data}
        else
            return encode(data), {}
        end
    end

    function deserialize(data, extra)
		if data == nil then return end
		extra = extra or {}
		
        local type = rtypes[data:sub(1,1)]
        if type == "table" then

            local p = 0
            local function read(l)
                l = l or 1
                p = p + l
                return data:sub(p-l + 1, p)
            end
            local function get(a)
                local k = ""
                while p < #data do
                    if data:sub(p+1,p+1) == a then
                        break
                    else
                        k = k .. read()
                    end
                end
                return k
            end

            local length = tonumber(get("."):sub(2, -1))
            read()

            local new = {}

            local l = 0
            while p <= length do
                l = l + 1

				local function getnext()
					local i
                    local t = read()
                    local type = rtypes[t]

                    if type == "nil" then
                        i = decode(t .. read())
                    elseif type == "boolean" then
                        i = decode(t .. read())
                    elseif type == "number" then
                        local l = get(".")
                        
                        local dc = t .. l .. read()
                        local a = read(tonumber(l))
                        dc = dc .. a

                        i = decode(dc)
                 	elseif type == "string" then
                        local l = get(".")
                        local dc = t .. l .. read()
                        local a = read(tonumber(l))
                        dc = dc .. a

                        i = decode(dc)
					 elseif type == "Vector3" then
						local function getnext()
							local length = hex_decode(read(2))
							local a = read(tonumber(length))
							return tonumber(a)
						end
						local x,y,z = getnext(),getnext(),getnext()
						i = Vector3.new(x, y, z)
					elseif type == "CFrame" then
						local a = {}
						for i = 1,12 do
							local l = hex_decode(read(2))
							local b = read(tonumber(l)) -- why did I decide to do this
							a[i] = tonumber(b)
						end
						i = CFrame.new(unpack(a))
					elseif type == "Instance" then
						local pos = hex_decode(read(2))
						i = extra[tonumber(pos)]
					elseif type == "Color3" then
						local a = {}
						for i = 1,3 do
							local l = hex_decode(read(2))
							local b = read(tonumber(l))
							a[i] = tonumber(b)
						end
						i = Color3.new(unpack(a))
                    elseif type == "table" then
                        local l = get(".")
                        local dc = t .. l .. read() .. read(tonumber(l))
                        i = deserialize(dc, extra)
                    end
					return i
				end
                local i = getnext()
                local v = getnext()

               new[(typeof(i) ~= "nil" and i or l)] =  v
            end


            return new
		elseif type == "Instance" then
			local pos = tonumber(hex_decode(data:sub(2,3)))
			return extra[pos]
        else
            return decode(data, extra)
        end
    end
end


local utility do
    -- shit
    utility = {}

    local servs
    servs = setmetatable({}, {
        __index = function(self, index)
            local s = game:GetService(index)
            if s then servs[index] = s end
            return s
        end;
    })
    
    local game, workspace = game, workspace

    local v2 = Vector2
    local math, table = math, table

    local v2new = v2.new

    local players = servs.Players
    local locpl = players.LocalPlayer
    local mouse = locpl:GetMouse()
    local camera = workspace.CurrentCamera
    
    local findFirstChildOfClass = game.FindFirstChildOfClass
    local isDescendantOf = game.IsDescendantOf    

    local getPlayers = players.GetPlayers
    local getPartsObscuringTarget = camera.GetPartsObscuringTarget
    local worldToViewportPoint = camera.WorldToViewportPoint
    local raynew = Ray.new
    local findPartOnRayWithIgnoreList = workspace.FindPartOnRayWithIgnoreList
    local findFirstChild = game.FindFirstChild

    local function raycast(ray, ignore, callback)
        local ignore = ignore or {}

        local hit, pos, normal, material = findPartOnRayWithIgnoreList(workspace, ray, ignore)
        while hit and callback do
            local Continue, _ignore = callback(hit)
            if not Continue then
                break
            end
            if _ignore then
                table.insert(ignore, _ignore)
            else
                table.insert(ignore, hit)
            end
            hit, pos, normal, material = findPartOnRayWithIgnoreList(workspace, ray, ignore)
        end
        return hit, pos, normal, material
    end



--- value-to-string: value, string (out), level (indentation), parent table, var name, is from tovar
function v2s(v, l, p, n, vtv, i, pt, path, tables, tI)
    if not tI then
        tI = {0}
    else
        tI[1] += 1
    end
    if typeof(v) == "number" then
        if v == math.huge then
            return "math.huge"
        elseif tostring(v):match("nan") then
            return "0/0 --[[NaN]]"
        end
        return tostring(v)
    elseif typeof(v) == "boolean" then
        return tostring(v)
    elseif typeof(v) == "string" then
        return formatstr(v, l)
    elseif typeof(v) == "function" then
        return f2s(v)
    elseif typeof(v) == "table" then
        return t2s(v, l, p, n, vtv, i, pt, path, tables, tI)
    elseif typeof(v) == "Instance" then
        return i2p(v)
    elseif typeof(v) == "userdata" then
        return "newproxy(true)"
    elseif type(v) == "userdata" then
        return u2s(v)
    elseif type(v) == "vector" then
        return string.format("Vector3.new(%s, %s, %s)", v2s(v.X), v2s(v.Y), v2s(v.Z))
    else
        return "nil --[[" .. typeof(v) .. "]]"
    end
end

--- value-to-variable
--- @param t any
function v2v(t)
    topstr = ""
    bottomstr = ""
    getnilrequired = false
    local ret = ""
    local count = 1
    for i, v in pairs(t) do
        if type(i) == "string" and i:match("^[%a_]+[%w_]*$") then
            ret = ret .. "local " .. i .. " = " .. v2s(v, nil, nil, i, true) .. "\n"
        elseif tostring(i):match("^[%a_]+[%w_]*$") then
            ret = ret .. "local " .. tostring(i):lower() .. "_" .. tostring(count) .. " = " .. v2s(v, nil, nil, tostring(i):lower() .. "_" .. tostring(count), true) .. "\n"
        else
            ret = ret .. "local " .. type(v) .. "_" .. tostring(count) .. " = " .. v2s(v, nil, nil, type(v) .. "_" .. tostring(count), true) .. "\n"
        end
        count = count + 1
    end
    if getnilrequired then
        topstr = "function getNil(name,class) for _,v in pairs(getnilinstances())do if v.ClassName==class and v.Name==name then return v;end end end\n" .. topstr
    end
    if #topstr > 0 then
        ret = topstr .. "\n" .. ret
    end
    if #bottomstr > 0 then
        ret = ret .. bottomstr
    end
    return ret
end

--- table-to-string
--- @param t table
--- @param l number
--- @param p table
--- @param n string
--- @param vtv boolean
--- @param i any
--- @param pt table
--- @param path string
--- @param tables table
--- @param tI table
function t2s(t, l, p, n, vtv, i, pt, path, tables, tI)
    local globalIndex = table.find(getgenv(), t) -- checks if table is a global
    if type(globalIndex) == "string" then
        return globalIndex
    end
    if not tI then
        tI = {0}
    end
    if not path then -- sets path to empty string (so it doesn't have to manually provided every time)
        path = ""
    end
    if not l then -- sets the level to 0 (for indentation) and tables for logging tables it already serialized
        l = 0
        tables = {}
    end
    if not p then -- p is the previous table but doesn't really matter if it's the first
        p = t
    end
    for _, v in pairs(tables) do -- checks if the current table has been serialized before
        if n and rawequal(v, t) then
            bottomstr = bottomstr .. "\n" .. tostring(n) .. tostring(path) .. " = " .. tostring(n) .. tostring(({v2p(v, p)})[2])
            return "{} --[[DUPLICATE]]"
        end
    end
    table.insert(tables, t) -- logs table to past tables
    local s =  "{" -- start of serialization
    local size = 0
    l = l + indent -- set indentation level
    for k, v in pairs(t) do -- iterates over table
        size = size + 1 -- changes size for max limit
        if size > (_G.SimpleSpyMaxTableSize or 1000) then
            s = s .. "\n" .. string.rep(" ", l) .. "-- MAXIMUM TABLE SIZE REACHED, CHANGE '_G.SimpleSpyMaxTableSize' TO ADJUST MAXIMUM SIZE "
            break
        end
        if rawequal(k, t) then -- checks if the table being iterated over is being used as an index within itself (yay, lua)
            bottomstr = bottomstr .. "\n" .. tostring(n) .. tostring(path) .. "[" .. tostring(n) .. tostring(path) .. "]" .. " = " .. (rawequal(v, k) and tostring(n) .. tostring(path) or v2s(v, l, p, n, vtv, k, t, path .. "[" .. tostring(n) .. tostring(path) .. "]", tables))
            size -= 1
            continue
        end
        local currentPath = "" -- initializes the path of 'v' within 't'
        if type(k) == "string" and k:match("^[%a_]+[%w_]*$") then -- cleanly handles table path generation (for the first half)
            currentPath = "." .. k
        else
            currentPath = "[" .. k2s(k, l, p, n, vtv, k, t, path .. currentPath, tables, tI) .. "]"
        end
        if size % 100 == 0 then
            scheduleWait()
        end
        -- actually serializes the member of the table
        s = s .. "\n" .. string.rep(" ", l) .. "[" .. k2s(k, l, p, n, vtv, k, t, path .. currentPath, tables, tI) .. "] = " .. v2s(v, l, p, n, vtv, k, t, path .. currentPath, tables, tI) .. ","
    end
    if #s > 1 then -- removes the last comma because it looks nicer (no way to tell if it's done 'till it's done so...)
        s = s:sub(1, #s - 1)
    end
    if size > 0 then -- cleanly indents the last curly bracket
        s = s .. "\n" .. string.rep(" ", l - indent)
    end
    return s .. "}"
end

--- key-to-string
function k2s(v, ...)
    if keyToString then
        if typeof(v) == "userdata" and getrawmetatable(v) then
            return string.format('"<void> (%s)" --[[Potentially hidden data (tostring in SimpleSpy:HookRemote/GetRemoteFiredSignal at your own risk)]]', safetostring(v))
        elseif typeof(v) == "userdata" then
            return string.format('"<void> (%s)"', safetostring(v))
        elseif type(v) == "userdata" and typeof(v) ~= "Instance" then
            return string.format('"<%s> (%s)"', typeof(v), tostring(v))
        elseif type(v) == "function" then
            return string.format('"<Function> (%s)"', tostring(v))
        end
    end
    return v2s(v, ...)
end

--- function-to-string
function f2s(f)
    for k, x in pairs(getgenv()) do
        local isgucci, gpath
        if rawequal(x, f) then
            isgucci, gpath = true, ""
        elseif type(x) == "table" then
            isgucci, gpath = v2p(f, x)
        end
        if isgucci and type(k) ~= "function" then
            if type(k) == "string" and k:match("^[%a_]+[%w_]*$") then
                return k .. gpath
            else
                return "getgenv()[" .. v2s(k) .. "]" .. gpath
            end
        end
    end
    if funcEnabled and debug.getinfo(f).name:match("^[%a_]+[%w_]*$") then
        return "function()end --[[" .. debug.getinfo(f).name .. "]]"
    end
    return "function()end --[[" .. tostring(f) .. "]]"
end

--- instance-to-path
--- @param i userdata
function i2p(i)
    local player = getplayer(i)
    local parent = i
    local out = ""
    if parent == nil then
        return "nil"
    elseif player then
        while true do
            if parent and parent == player.Character then
                if player == Players.LocalPlayer then
                    return 'game:GetService("Players").LocalPlayer.Character' .. out
                else
                    return i2p(player) .. ".Character" .. out
                end
            else
                if parent.Name:match("[%a_]+[%w+]*") ~= parent.Name then
                    out = ':FindFirstChild(' .. formatstr(parent.Name) .. ')' .. out
                else
                    out = "." .. parent.Name .. out
                end
            end
            parent = parent.Parent
        end
    elseif parent ~= game then
        while true do
            if parent and parent.Parent == game then
                local service = game:FindService(parent.ClassName)
                if service then
                    if parent.ClassName == "Workspace" then
                        return "workspace" .. out
                    else
                        return 'game:GetService("' .. service.ClassName .. '")' .. out
                    end
                else
                    if parent.Name:match("[%a_]+[%w_]*") then
                        return "game." .. parent.Name .. out
                    else
                        return 'game:FindFirstChild(' .. formatstr(parent.Name) .. ')' .. out
                    end
                end
            elseif parent.Parent == nil then
                getnilrequired = true
                return 'getNil(' .. formatstr(parent.Name) .. ', "' .. parent.ClassName .. '")' .. out
            elseif parent == Players.LocalPlayer then
                out = ".LocalPlayer" .. out
            else
                if parent.Name:match("[%a_]+[%w_]*") ~= parent.Name then
                    out = ':FindFirstChild(' .. formatstr(parent.Name) .. ')' .. out
                else
                    out = "." .. parent.Name .. out
                end
            end
            parent = parent.Parent
        end
    else
        return "game"
    end
end

--- userdata-to-string: userdata
--- @param u userdata
function u2s(u)
    if typeof(u) == "TweenInfo" then
        -- TweenInfo
        return "TweenInfo.new(" ..tostring(u.Time) .. ", Enum.EasingStyle." .. tostring(u.EasingStyle) .. ", Enum.EasingDirection." .. tostring(u.EasingDirection) .. ", " .. tostring(u.RepeatCount) .. ", " .. tostring(u.Reverses) .. ", " .. tostring(u.DelayTime) .. ")"
    elseif typeof(u) == "Ray" then
        -- Ray
        return "Ray.new(" .. u2s(u.Origin) .. ", " .. u2s(u.Direction) .. ")"
    elseif typeof(u) == "NumberSequence" then
        -- NumberSequence
        local ret = "NumberSequence.new("
        for i, v in pairs(u.KeyPoints) do
            ret = ret .. tostring(v)
            if i < #u.Keypoints then
                ret = ret .. ", "
            end
        end
        return ret .. ")"
    elseif typeof(u) == "DockWidgetPluginGuiInfo" then
        -- DockWidgetPluginGuiInfo
        return "DockWidgetPluginGuiInfo.new(Enum.InitialDockState" .. tostring(u) .. ")"
    elseif typeof(u) == "ColorSequence" then
        -- ColorSequence
        local ret = "ColorSequence.new("
        for i, v in pairs(u.KeyPoints) do
            ret = ret .. "Color3.new(" .. tostring(v) .. ")"
            if i < #u.Keypoints then
                ret = ret .. ", "
            end
        end
        return ret .. ")"
    elseif typeof(u) == "BrickColor" then
        -- BrickColor
        return "BrickColor.new(" .. tostring(u.Number) .. ")"
    elseif typeof(u) == "NumberRange" then
        -- NumberRange
        return "NumberRange.new(" .. tostring(u.Min) .. ", " .. tostring(u.Max) .. ")"
    elseif typeof(u) == "Region3" then
        -- Region3
        local center = u.CFrame.Position
        local size = u.CFrame.Size
        local vector1 = center - size / 2
        local vector2 = center + size / 2
        return "Region3.new(" .. u2s(vector1) .. ", " .. u2s(vector2) .. ")"
    elseif typeof(u) == "Faces" then
        -- Faces
        local faces = {}
        if u.Top then
            table.insert(faces, "Enum.NormalId.Top")
        end
        if u.Bottom then
            table.insert(faces, "Enum.NormalId.Bottom")
        end
        if u.Left then
            table.insert(faces, "Enum.NormalId.Left")
        end
        if u.Right then
            table.insert(faces, "Enum.NormalId.Right")
        end
        if u.Back then
            table.insert(faces, "Enum.NormalId.Back")
        end
        if u.Front then
            table.insert(faces, "Enum.NormalId.Front")
        end
        return "Faces.new(" .. table.concat(faces, ", ") .. ")"
    elseif typeof(u) == "EnumItem" then
        return tostring(u)
    elseif typeof(u) == "Enums" then
        return "Enum"
    elseif typeof(u) == "Enum" then
        return "Enum." .. tostring(u)
    elseif typeof(u) == "RBXScriptSignal" then
        return "nil --[[RBXScriptSignal]]"
    elseif typeof(u) == "Vector3" then
        return string.format("Vector3.new(%s, %s, %s)", v2s(u.X), v2s(u.Y), v2s(u.Z))
    elseif typeof(u) == "CFrame" then
        return string.format("CFrame.new(%s, %s)", v2s(u.Position), v2s(u.LookVector))
    elseif typeof(u) == "DockWidgetPluginGuiInfo" then
        return string.format("DockWidgetPluginGuiInfo(%s, %s, %s, %s, %s, %s, %s)", "Enum.InitialDockState.Right", v2s(u.InitialEnabled), v2s(u.InitialEnabledShouldOverrideRestore), v2s(u.FloatingXSize), v2s(u.FloatingYSize), v2s(u.MinWidth), v2s(u.MinHeight))
    elseif typeof(u) == "PathWaypoint" then
        return string.format("PathWaypoint.new(%s, %s)", v2s(u.Position), v2s(u.Action))
    elseif typeof(u) == "UDim" then
        return string.format("UDim.new(%s, %s)", v2s(u.Scale), v2s(u.Offset))
    elseif typeof(u) == "UDim2" then
        return string.format("UDim2.new(%s, %s, %s, %s)", v2s(u.X.Scale), v2s(u.X.Offset), v2s(u.Y.Scale), v2s(u.Y.Offset))
    elseif typeof(u) == "Rect" then
        return string.format("Rect.new(%s, %s)", v2s(u.Min), v2s(u.Max))
    else
        return string.format("nil --[[%s]]", typeof(u))
    end
end

--- Gets the player an instance is descended from
function getplayer(instance)
    for _, v in pairs(Players:GetPlayers()) do
        if v.Character and (instance:IsDescendantOf(v.Character) or instance == v.Character) then
            return v
        end
    end
end

--- value-to-path (in table)
function v2p(x, t, path, prev)
    if not path then
        path = ""
    end
    if not prev then
        prev = {}
    end
    if rawequal(x, t) then
        return true, ""
    end
    for i, v in pairs(t) do
        if rawequal(v, x) then
            if type(i) == "string" and i:match("^[%a_]+[%w_]*$") then
                return true, (path .. "." .. i)
            else
                return true, (path .. "[" .. v2s(i) .. "]")
            end
        end
        if type(v) == "table" then
            local duplicate = false
            for _, y in pairs(prev) do
                if rawequal(y, v) then
                    duplicate = true
                end
            end
            if not duplicate then
                table.insert(prev, t)
                local found
                found, p = v2p(x, v, path, prev)
                if found then
                    if type(i) == "string" and i:match("^[%a_]+[%w_]*$") then
                        return true, "." .. i .. p
                    else
                        return true, "[" .. v2s(i) .. "]" .. p
                    end
                end
            end
        end
    end
    return false, ""
end

--- format s: string, byte encrypt (for weird symbols)
function formatstr(s, indentation)
    if not indentation then
        indentation = 0
    end
    local handled, reachedMax = handlespecials(s, indentation)
    return '"' .. handled .. '"' .. (reachedMax and " --[[ MAXIMUM STRING SIZE REACHED, CHANGE '_G.SimpleSpyMaxStringSize' TO ADJUST MAXIMUM SIZE ]]" or "")
end

--- Adds \'s to the text as a replacement to whitespace chars and other things because string.format can't yayeet
function handlespecials(value, indentation)
    local buildStr = {}
    local i = 1
    local char = string.sub(value, i, i)
    local indentStr
    while char ~= "" do
        if char == '"' then
            buildStr[i] = '\\"'
        elseif char == "\\" then
            buildStr[i] = "\\\\"
        elseif char == "\n" then
            buildStr[i] = "\\n"
        elseif char == "\t" then
            buildStr[i] = "\\t"
        elseif string.byte(char) > 126 or string.byte(char) < 32 then
            buildStr[i] = string.format("\\%d", string.byte(char))
        else
            buildStr[i] = char
        end
        i = i + 1
        char = string.sub(value, i, i)
        if i % 200 == 0 then
            indentStr = indentStr or string.rep(" ", indentation + indent)
            table.move({'"\n', indentStr, '... "'}, 1, 3, i, buildStr)
            i += 3
        end
    end
    return table.concat(buildStr)
end

-- safe (ish) tostring
function safetostring(v: any)
    if typeof(v) == "userdata" or type(v) == "table" then
        local mt = getrawmetatable(v)
        local badtostring = mt and rawget(mt, "__tostring")
        if mt and badtostring then
            rawset(mt, "__tostring", nil)
            local out = tostring(v)
            rawset(mt, "__tostring", badtostring)
            return out
        end
    end
    return tostring(v)
end


    -- yes I copied this from simplespy because I am lazy
    function v2s(v, l, p, n, vtv, i, pt, path, tables, tI)
        if not tI then
            tI = {0}
        else
            tI[1] += 1
        end
        if typeof(v) == "number" then
            if v == math.huge then
                return "math.huge"
            elseif tostring(v):match("nan") then
                return "0/0 --[[NaN]]"
            end
            return tostring(v)
        elseif typeof(v) == "boolean" then
            return tostring(v)
        elseif typeof(v) == "string" then
            return formatstr(v, l)
        elseif typeof(v) == "function" then
            return f2s(v)
        elseif typeof(v) == "table" then
            return t2s(v, l, p, n, vtv, i, pt, path, tables, tI)
        elseif typeof(v) == "Instance" then
            return i2p(v)
        elseif typeof(v) == "userdata" then
            return "newproxy(true)"
        elseif type(v) == "userdata" then
            return u2s(v)
        elseif type(v) == "vector" then
            return string.format("Vector3.new(%s, %s, %s)", v2s(v.X), v2s(v.Y), v2s(v.Z))
        else
            return "nil --[[" .. typeof(v) .. "]]"
        end
    end

    function utility.value2string(...)
        return v2s(...)
    end

    local function badraycastnotevensure(pos, ignore) -- 1 ray > 1 obscuringthing | 100 rays < 1 obscuring thing
        local hitparts = getPartsObscuringTarget(camera, {pos}, ignore or {})
        return hitparts
    end

    local charshit = {}
    function utility.getcharacter(player) -- Change this or something if you want to add support for other games.
        if (player == nil) then return end
        if (charshit[player]) then return charshit[player] end

        local char = player.Character
        if (char == nil or isDescendantOf(char, game) == false) then
            char = findFirstChild(workspace, player.Name)
        end

        return char
    end

    utility.mychar = nil
    utility.myroot = nil

    local rootshit = {}
    function utility.getroot(player)
        if (player == nil) then return end
        if (rootshit[player]) then return rootshit[player] end

        local char
        if (player:IsA("Player")) then
            char = utility.getcharacter(player)
        else
            char = player
        end

        if (char ~= nil) then
            return (findFirstChild(char, "Torso") or char.PrimaryPart)
        end

        return
    end

    function utility.isalive(_1, _2)
        if _1 == nil then return end
        local Char, RootPart
        if _2 ~= nil then
            Char, RootPart = _1,_2
        else
            Char = utility.getcharacter(_1)
            RootPart = Char and (Char:FindFirstChild("Torso") or Char.PrimaryPart)
        end

        if Char and RootPart then
            local Human = findFirstChildOfClass(Char, "Humanoid")
            if RootPart and Human then
                if Human.Health > 0 then
                    return true
                end
            elseif RootPart and isDescendantOf(Char, game) then
                return true
            end
        end

        return false
    end

    local shit = false
    function utility.isvisible(char, root, max, ...)
        local pos = root.Position
        if shit or max > 4 then
            local parts = badraycastnotevensure(pos, {utility.mychar, ..., workspace.CurrentCamera, char, root, workspace:FindFirstChild("Ignore"), })
            
            return parts <= max
        else
            local camp = camera.CFrame.p
            local dist = (camp - pos).Magnitude

            local hitt = 0
            local hit = raycast(raynew(camp, (pos - camp).unit * dist), {utility.mychar, ..., camera}, function(hit)
                if hit.Name == "Window" then
                    return true
                end

                if hit.CanCollide == true then-- hit.Transparency ~= 1 then
                    hitt = hitt + 1
                    return hitt < max
                end
            
                if isDescendantOf(hit, char) then
                    return
                end

                return true
            end)

            return hit == nil or isDescendantOf(hit, char) or hitt <= max, hitt
        end
    end
    function utility.sameteam(player, p1)
        local p0 = p1 or locpl
        return (player.Team~=nil and player.Team==p0.Team) and player.Neutral == false or false
    end
    function utility.getDistanceFromMouse(position)
        local screenpos, vis = worldToViewportPoint(camera, position)
        if vis and screenpos.Z > 0 then
            return (v2new(mouse.X, mouse.Y) - v2new(screenpos.X, screenpos.Y)).Magnitude
        end
        return math.huge
    end

    function utility.getClosestMouseTarget(settings)
        local closest, temp = nil, settings.fov or math.huge
        local plr

        local mychar = utility.getcharacter(locpl)
        utility.mychar = mychar
        local myroot = utility.getroot(mychar)
        utility.myroot = myroot

        for i,v in pairs(getPlayers(players)) do
            if (locpl ~= v and (settings.ignoreteam==true and utility.sameteam(v)==false or settings.ignoreteam == false)) then
                local character = utility.getcharacter(v)
                if character then
                    local part = findFirstChild(character, settings.name or "Torso") or findFirstChild(character, "Torso") or character.PrimaryPart
                    if part and part:IsA("BasePart") then
                        local legal = true

                        local distance = utility.getDistanceFromMouse(part.CFrame.Position)
                        if temp <= distance then
                            legal = false
                        end

                        if legal and settings.checkifalive then
                            local isalive = utility.isalive(character, part)
                            if not isalive then
                                legal = false
                            end
                        end

                        if legal and settings.ignorewalls == false then
                            if not utility.isvisible(character, part, (settings.maxobscuringparts or 0)) then
                                legal = false
                            end
                        end

                        if legal and myroot and settings.maxdist then
                            if settings.maxdist < (myroot.Position - part.Position).Magnitude then
                                legal = false
                            end
                        end

                        if legal then
                            temp = distance
                            closest = part
                            plr = v
                        end
                    end
                end
            end
        end -- who doesnt love 5 ends in a row?

        return closest, temp, plr
    end
end



local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local RunService = game:GetService("RunService")

local function assert(a, b, ...)
    if not a then
        print(...)
        return error(b)
    end
end

local function kick(...)
    LocalPlayer:Kick(...)
end

local function findFirstChild(parent,child,callback)
    if parent ~= nil and callback ~= nil then
        local obj = parent:FindFirstChild(tostring(child))
        if obj ~= nil then
            callback(obj)
        end
    end
end

local function map(a, f)
    local b = {}
    for i,v in pairs(a) do
        local i2,v2 = f(i,v)
        if typeof(i2) ~= nil then
            b[i2] = v2
        end
    end
    return b
end

local function findLocal(lookinfor)
    local found = {}

    for i,v in pairs(lookinfor.gc and getgc()  or getreg()) do
        if typeof(v) == "function" and islclosure(v) then
            local upvals = debug.getupvalues(v)
            for i2,v2 in pairs(upvals) do
                
                if typeof(v2) == "table" then
                    local Correct = true
                    if typeof(lookinfor) == "table" then
                        if lookinfor.env ~= nil then
                            local env = getfenv(v)
                            for i3,v3 in pairs(lookinfor.env) do
                                if typeof(v3) == "string" then
                                    if tostring(rawget(env, i3)) ~= v3 then
                                        Correct = false
                                        break
                                    end
                                end
                            end
                        end

                        if Correct then
                            if #lookinfor == 0 and lookinfor.env == nil then
                                Correct = false
                            end
                            for i3,v3 in pairs(lookinfor) do
                                if typeof(i3) == "number" then
                                    if rawget(v2, v3) == nil then
                                        Correct = false
                                        break
                                    end
                                end
                            end
                        end
                    else
                        if rawget(v2, lookinfor) == nil then
                            Correct = false
                        end
                    end

                    if Correct then
                        if lookinfor.remove then
                            debug.setupvalue(v, i2, nil)
                        end
                        if lookinfor.replace then
                            debug.setupvalue(v, i2, lookinfor.replace)
                        end
                        table.insert(found, v2)
                    end
                elseif typeof(v2) == "function" and islclosure(v2) then
                    local Correct = true
                    if lookinfor.constants ~= nil then
                        local consts = debug.getconstants(v2)
                        consts = map(consts, function(a,b) return b,true end)

                        for i3,v3 in pairs(lookinfor.constants) do
                            if typeof(i3) == "number" then
                                if not consts[v3] then
                                    Correct = false
                                    break
                                end
                            end
                        end

                        if Correct then
                            if lookinfor.remove then
                                debug.setupvalue(v, i2, nil)
                            end
                            if lookinfor.replace then
                                debug.setupvalue(v, i2, lookinfor.replace)
                            end

                            table.insert(found, v2)
                        end
                    end
                end
            end
        end
    end

    return found
end



-- just so I can re-execute multiple times
local storage = shared.gamer_storage or {}
shared.gamer_storage = storage -- fuck off

storage.misc = storage.misc or {}

-- yup
local network = storage.misc.network or findLocal({
    "fetch",
    "send",
    "ready",
    "servertick"
})[1]
assert(network, kick, "Failed to find network module")
storage.misc.network = network

-- character handler
local char = storage.misc.char or findLocal({
    "setsprint",
    "setbasewalkspeed",
    "getstate",
    
    env = {
        script = "Framework"
    }
})[1]
assert(char, kick, "Failed to find char module")
storage.misc.char = char

local hudModule = storage.misc.hud or findLocal({
    "firehitmarker"
})[1]
assert(hudModule, kick, "Failed to find hud module")
storage.misc.hud = hudModule

local effects = storage.misc.effects or findLocal({
    "bloodhit",
    "breakwindow",

    gc = true,
})[1]
assert(effects, kick, "Failed to find effects module")
storage.misc.effects = effects

local sound = storage.misc.sound or findLocal({
    "PlaySound",
    "PlaySoundId",

    gc = true,
})[1]
assert(sound, kick, "Failed to find sound module")
storage.misc.sound = sound

local gamelogic = storage.misc.gamelogic or findLocal({
    "gammo",
    "setsprintdisable",
    "controllerstep",
    gc = true,
    
})[1]
assert(gamelogic, kick, "Failed to find gamelogic module")
storage.misc.gamelogic = gamelogic

do -- Character shit, pf renames characters so yeah umh
    local replication = storage.misc.replication or findLocal({
        "removecharacterhash",
        "getplayerhit",
        "thickcastplayers",
    
        env = {
            script = "Framework"
        }
    })[1]
    assert(replication, kick, "Failed to find replication module")
    storage.misc.replication = replication

    utility.getcharacter = function(player)
        if player == LocalPlayer then
            return char.rootpart and char.rootpart.Parent
        end

        for i,v in pairs(debug.getupvalue(replication.getplayerhit, 1)) do
            if v == player then
                return i
            end
        end
    end

    char.humanoid = debug.getupvalue(char.getstate, 1)


    storage.char = storage.char or {}

    -- Infinite jump & JumpPower
    storage.char.jump = storage.char.jump or char.jump
    char.jump = function(self, ...)
        if (settings.setjumppower) then
            char.humanoid.JumpPower = (2 * game.Workspace.Gravity * settings.jumppower) ^ 0.5
            char.humanoid.Jump = true
            return true
        end
        return storage.char.jump(self, ...)
    end


    -- walkspeed
    storage.char.setbasewalkspeed = storage.char.setbasewalkspeed or char.setbasewalkspeed
    storage.char.oldWalkspeed = 16
    char.setbasewalkspeed = function(self, speed, ...)
        storage.char.oldWalkspeed = speed
        if (settings.setwalkspeed) then
            return storage.char.setbasewalkspeed(self, settings.walkspeed)
        end
        return storage.char.setbasewalkspeed(self, speed, ...)
    end


end


do -- Network hook funcs

    storage.network = storage.network or {}

    local old_send = storage.network.send or network.send
    storage.network.send = old_send

    network.send = function(self, method, ...) -- hookfunction randomly broke, idk why :(
        if checkcaller() then return old_send(self, method, ...) end
        local args = {...}

        if method == "closeconnection" then
            return
        end
        
        if method == "falldamage" and settings.nofalldamage then
            return -- Remove fall damage
        end


        if method == "bullethit" and settings.headshotchanceenabled then -- headshot %
            if args[3] and typeof(args[3]) == 'string' then
                local ran = math.random(1,100)
                if ran <= settings.headshotchance then
                    args[3] = "Head"
                else
                    args[3] = "Torso"
                end
            end
        end

        if method == "knifehit" and settings.headshotchanceenabled then -- headshot %
            if args[3] and typeof(args[3]) == "Instance" then

                local ran = math.random(1,100)

                if ran <= settings.headshotchance then
                    args[3] = args[3].Parent:FindFirstChild("Head") or args[3]
                else
                    args[3] = args[3].Parent:FindFirstChild("Torso") or args[3]
                end
            end
        end

        return old_send(self, method, unpack(args))
    end

end

do -- Some silent aim shit

    local old_mt = storage.old_mt or {}
    storage.old_mt = old_mt
    
    local _nindex = hookmetamethod(game, "__index", function(...)
        local self, index = ...
        if checkcaller() then 
            return old_mt.__index(self, index) 
        end

        if index == "CFrame" and settings.silentaim then -- its a meh..

            local barrel = gamelogic and gamelogic.currentgun and gamelogic.currentgun.barrel
            local sight = gamelogic and gamelogic.currentgun and gamelogic.currentgun.aimsightdata and gamelogic.currentgun.aimsightdata[1] and gamelogic.currentgun.aimsightdata[1].sightpart
            
            if barrel and (self == barrel or self == sight) then
                local Head, dist, plr = utility.getClosestMouseTarget({
                    ignoreteam = true,
                    ignorewalls = false,
                    maxobscuringparts = 0,
                    name = 'Head',
                    fov = settings.fov,
                    maxdist = 3000,
                    checkifalive = false
                })

                if Head then
                    local bulletspeed = gamelogic.currentgun.data and gamelogic.currentgun.data.bulletspeed or dist * 10
                    --dist = (bulletspeed ^ 2 * dist + 196.2 * dist) / bulletspeed ^ 2
                    local t = (bulletspeed * dist + 196.2 * dist) / bulletspeed ^ 2

                    local Dir = Vector3.new(
                        Head.Position.X,
                        Head.Position.Y + (((196.2 ^ t) / 2) - (t * 2)),
                        Head.Position.Z
                    )

                    Dir = Dir + (Head.Parent.Torso.Velocity * (dist / bulletspeed))

                    return CFrame.new(barrel.Position, Dir)
                end
            end
        end

        return old_mt.__index(self, index)
    end)
    old_mt.__index = old_mt.__index or _nindex
end

local clearDrawn, newdrawing
do
    --/ Drawing extra functions

    local insert = table.insert
    local newd = Drawing.new

    local drawn = {}
    function clearDrawn() -- who doesnt love drawing library
        for i,v in pairs(drawn) do
            pcall(function() v:Remove() end)
            drawn[i] = nil
        end
        drawn = {}
    end

    function newdrawing(class, props)
        --if visuals.enabled ~= true then
        --    return
        --end
        local new = newd(class)
        for i,v in pairs(props) do
            new[i] = v
        end
        insert(drawn, new)
        return new
    end
end

local sett_2 = settings
local settings = __SETTINGS__
do
    --/ Settings

    -- TODO: Other datatypes.
    settings.fileName = "PFHax_settings.txt" -- Lovely
    settings.saved = {}

    function settings:Get(name, default)
        local self = {}
        local value = settings.saved[name]
        if value == nil and default ~= nil then
            value = default
            settings.saved[name] = value
        end
        self.Value = value
        function self:Set(val)
            self.Value = val
            settings.saved[name] = val
        end
        return self  --value or default
    end

    function settings:Set(name, value)
        local r = settings.saved[name]
        settings.saved[name] = value
        return r
    end

    function settings:Save()
        local savesettings = settings:GetAll() or {}
        local new = mergetab(savesettings, settings.saved)
        local js = serialize(new)

        writefile(settings.fileName, js)
    end

    function settings:GetAll()
        if not existsFile(settings.fileName) then
            return
        end
        local fileContents = readfile(settings.fileName)

        local data
        pcall(function()
            data = deserialize(fileContents)
        end)
        return data
    end

    function settings:Load()
        if not existsFile(settings.fileName) then
            return
        end
        local fileContents = readfile(settings.fileName)

        local data
        pcall(function()
            data = deserialize(fileContents)
        end)

        if data then
            data = mergetab(settings.saved, data)
        end
        settings.saved = data
        return data
    end
    settings:Load()

    spawn(function()
        while main and main.enabled do
            settings:Save()
            wait(5)
        end
    end)
end

local esp = {} do
    local esp_settings = {}

    esp_settings.enabled = settings:Get("esp.enabled", true)
    esp_settings.showteam = settings:Get("esp.showteam", true)
    
    esp_settings.teamcolor = Color3.fromRGB(57,255,20) -- 121,255,97, 57,255,20
    esp_settings.enemycolor = Color3.fromRGB(255,7,58) -- 238,38,37, 255,0,13, 255,7,58
    esp_settings.visiblecolor = Color3.fromRGB(0, 141, 255) -- 0, 141, 255


    esp_settings.size = settings:Get("esp.size", 16)
    esp_settings.centertext = settings:Get("esp.centertext", true)
    esp_settings.outline = settings:Get("esp.outline", true)
    esp_settings.transparency = settings:Get("esp.transparency", 0.1)

    esp_settings.drawdistance = settings:Get("esp.drawdistance", 1500)


    esp_settings.showvisible = settings:Get("esp.showvisible", true)

    esp_settings.yoffset = settings:Get("esp.yoffset", 0)

    esp_settings.showhealth = settings:Get("esp.showhealth", true)
    esp_settings.showdistance = settings:Get("esp.showdistance", true)

    setmetatable(esp, {
        __index = function(self, index)
            if esp_settings[index] ~= nil then
                local Value = esp_settings[index]
                if typeof(Value) == "table" then
                    return typeof(Value) == "table" and Value.Value
                else
                    return Value
                end
            end
            warn(("EspSettings : Tried to index %s"):format(tostring(index)))
        end;
        __newindex = function(self, index, value)
            if typeof(value) ~= "function" then
                if esp_settings[index] then
                    local v = esp_settings[index]
                    if typeof(v) ~= "table" then
                        esp_settings[index] = value
                        return
                    elseif v.Set then
                        v:Set(value)
                        return
                    end
                end
            end
            rawset(self, index, value)
        end;
    })

    local camera = workspace.CurrentCamera
    local worldToViewportPoint = camera.WorldToViewportPoint

    local floor = math.floor
    local insert = table.insert
    local concat = table.concat
    local v2new = Vector2.new

    local drawn = {}
    local completeStop = false

    local function drawTemplate(player)
        if completeStop then return end
        if drawn[player] then return drawn[player] end

        local obj = newdrawing("Text", {
            Text = "n/a",
            Size = esp.size,
            Color = esp.enemycolor,
            Center = esp.centertext,
            Outline = esp.outline,
            Transparency = (1 - esp.transparency),
        })
        return obj
    end

    function esp:Draw(player, character, root, humanoid, onscreen, isteam, dist)
        if completeStop then return end
        if character == nil then return esp:Remove(player) end
        if root == nil then return esp:Remove(player) end
        if esp.showteam~=true and isteam then return esp:Remove(player) end

        if dist then
            if dist > esp.drawdistance then
                return esp:Remove(player)
            end
        end

        local where, isvis = worldToViewportPoint(camera, (root.CFrame * esp.offset).p);
        --if not isvis then return esp:Remove(player) end


        local oesp = drawn[player]
        if oesp == nil then
            oesp = drawTemplate(player)
            drawn[player] = oesp
        end
        
        if oesp then
            oesp.Visible = isvis
            if isvis then
                oesp.Position = v2new(where.X, where.Y)

                local color
                if isteam == false and esp.showvisible then
                    if utility.isvisible(character, root, 0) then
                        color = esp.visiblecolor
                    else
                        color = isteam and esp.teamcolor or esp.enemycolor
                    end
                else
                    color = isteam and esp.teamcolor or esp.enemycolor
                end

                oesp.Color = color

                oesp.Center = esp.centertext
                oesp.Size = esp.size
                oesp.Outline = esp.outline
                oesp.Transparency = (1 - esp.transparency)

                local texts = {
                    player.Name,
                }
                
                local b = humanoid and esp.showhealth and ("%s/%s"):format(floor(humanoid.Health + .5), floor(humanoid.MaxHealth + .5))
                if b then
                    insert(texts, b)
                end
                local c = dist and esp.showdistance and ("%s"):format(floor(dist + .5))
                if c then
                    insert(texts, c)
                end

                local text = "[  " .. concat(texts, " | ") .. " ]"
                oesp.Text = text
            end
        end
    end

    function esp:Remove(player)
        local data = drawn[player]
        if data ~= nil then
            data:Remove()
            drawn[player] = nil
        end
    end

    function esp:RemoveAll()
        for i,v in pairs(drawn) do
            pcall(function() v:Remove() end)
            drawn[i] = nil
        end
    end

    function esp:End()
        completeStop = true
        esp:RemoveAll()
    end
end


local boxes = {} do
    --/ Boxes

    local boxes_settings = {}
    boxes_settings.enabled = settings:Get("boxes.enabled", true)
    boxes_settings.transparency = settings:Get("boxes.transparency", .2)
    boxes_settings.thickness = settings:Get("boxes.thickness", 1.5)
    boxes_settings.showteam = settings:Get("boxes.showteam", true)

    boxes_settings.teamcolor = Color3.fromRGB(57,255,20) -- 121,255,97,  57,255,20
    boxes_settings.enemycolor = Color3.fromRGB(255,7,58) -- 238,38,37, 255,0,13, 255,7,58
    boxes_settings.visiblecolor = Color3.fromRGB(0, 141, 255)

    boxes_settings.thirddimension = settings:Get("boxes.thirddimension", true)

    boxes_settings.showvisible = settings:Get("boxes.showvisible", true)

    boxes_settings.dist3d = settings:Get("boxes.dist3d", 1000)
    boxes_settings.drawdistance = settings:Get("boxes.drawdistance", 4000)
    boxes_settings.color = Color3.fromRGB(255, 50, 50)

    setmetatable(boxes, {
        __index = function(self, index)
            if boxes_settings[index] ~= nil then
                local Value = boxes_settings[index]
                if typeof(Value) == "table" then
                    return typeof(Value) == "table" and Value.Value
                else
                    return Value
                end
            end
            warn(("BoxesSettings : Tried to index %s"):format(tostring(index)))
        end;
        __newindex = function(self, index, value)
            if typeof(value) ~= "function" then
                if boxes_settings[index] then
                    local v = boxes_settings[index]
                    if typeof(v) ~= "table" then
                        boxes_settings[index] = value
                        return
                    elseif v.Set then
                        v:Set(value)
                        return
                    end
                end
            end
            rawset(self, index, value)
        end;
    })

    local camera = workspace.CurrentCamera
    local unpack = unpack
    local worldToViewportPoint = camera.WorldToViewportPoint
    local v2new = Vector2.new
    local cfnew = CFrame.new

    local completeStop = false
    local drawn = {}
    local function drawTemplate(player, amount)
        if completeStop then return end

        if drawn[player] then
            if #drawn[player] == amount then
                return drawn[player]
            end
            boxes:Remove(player)
        end

        local props = {
            Visible = true;
            Transparency = 1 - boxes.transparency;
            Thickness = boxes.thickness;
            Color = boxes.color;
        }

        local a = {}
        for i = 1,amount or 4 do
            a[i] = newdrawing("Line", props)
        end

        drawn[player] = {unpack(a)}
        return unpack(a)
    end

    local function updateLine(line, from, to, vis, color)
        if line == nil then return end

        line.Visible = vis
        if vis then
            line.From = from
            line.To = to
            line.Color = color
        end
    end

    function boxes:Draw(player, character, root, humanoid, onscreen, isteam, dist) -- No skid plox
        if completeStop then return end
        if character == nil then return boxes:Remove(player) end
        if root == nil then return boxes:Remove(player) end
        if not onscreen then return boxes:Remove(player) end
        if boxes.showteam == false and isteam then return boxes:Remove(player) end

        local _3dimension = boxes.thirddimension
        if dist ~= nil then
            if dist > boxes.drawdistance then
                return boxes:Remove(player)
            elseif _3dimension and dist > boxes.dist3d then
                _3dimension = false
            end
        end

        local color
        if isteam == false and boxes.showvisible then
            if utility.isvisible(character, root, 0) then
                color = boxes.visiblecolor
            else
                color = isteam and boxes.teamcolor or boxes.enemycolor
            end
        else
            color = isteam and boxes.teamcolor or boxes.enemycolor
        end

        --size = ... lastsize--, v3new(5,8,0) --getBoundingBox(character)--]] root.CFrame, getExtentsSize(character)--]] -- Might change this later idk + idc
        if _3dimension then

            local tlb, trb, blb, brb, tlf, trf, blf, brf, tlf0, trf0, blf0, brf0
            if drawn[player] == nil or #drawn[player] ~= 12 then
                tlb, trb, blb, brb, tlf, trf ,blf, brf, tlf0, trf0, blf0, brf0 = drawTemplate(player, 12)
            else
                tlb, trb, blb, brb, tlf, trf ,blf, brf, tlf0, trf0, blf0, brf0 = unpack(drawn[player])
            end

            local pos, size = root.CFrame, root.Size--lastsize--, v3new(5,8,0)

            local topleftback, topleftbackvisible = worldToViewportPoint(camera, (pos * cfnew(-size.X, size.Y, size.Z)).p);
            local toprightback, toprightbackvisible = worldToViewportPoint(camera, (pos * cfnew(size.X, size.Y, size.Z)).p);
            local btmleftback, btmleftbackvisible = worldToViewportPoint(camera, (pos * cfnew(-size.X, -size.Y, size.Z)).p);
            local btmrightback, btmrightbackvisible = worldToViewportPoint(camera, (pos * cfnew(size.X, -size.Y, size.Z)).p);

            local topleftfront, topleftfrontvisible = worldToViewportPoint(camera, (pos * cfnew(-size.X, size.Y, -size.Z)).p);
            local toprightfront, toprightfrontvisible = worldToViewportPoint(camera, (pos * cfnew(size.X, size.Y, -size.Z)).p);
            local btmleftfront, btmleftfrontvisible = worldToViewportPoint(camera, (pos * cfnew(-size.X, -size.Y, -size.Z)).p);
            local btmrightfront, btmrightfrontvisible = worldToViewportPoint(camera, (pos * cfnew(size.X, -size.Y, -size.Z)).p);

            local topleftback = v2new(topleftback.X, topleftback.Y)
            local toprightback = v2new(toprightback.X, toprightback.Y)
            local btmleftback = v2new(btmleftback.X, btmleftback.Y)
            local btmrightback = v2new(btmrightback.X, btmrightback.Y)

            local topleftfront = v2new(topleftfront.X, topleftfront.Y)
            local toprightfront = v2new(toprightfront.X, toprightfront.Y)
            local btmleftfront = v2new(btmleftfront.X, btmleftfront.Y)
            local btmrightfront = v2new(btmrightfront.X, btmrightfront.Y)

            -- pls don't copy this bad code
			updateLine(tlb, topleftback, toprightback, topleftbackvisible, color)
            updateLine(trb, toprightback, btmrightback, toprightbackvisible, color)
            updateLine(blb, btmleftback, topleftback, btmleftbackvisible, color)
            updateLine(brb, btmleftback, btmrightback, btmrightbackvisible, color)

            --

            updateLine(brf, btmrightfront, btmleftfront, btmrightfrontvisible, color)
            updateLine(tlf, topleftfront, toprightfront, topleftfrontvisible, color)
            updateLine(trf, toprightfront, btmrightfront, toprightfrontvisible, color)
            updateLine(blf, btmleftfront, topleftfront, btmleftfrontvisible, color)

            --

            updateLine(brf0, btmrightfront, btmrightback, btmrightfrontvisible, color)
            updateLine(tlf0, topleftfront, topleftback, topleftfrontvisible, color)
            updateLine(trf0, toprightfront, toprightback, toprightfrontvisible, color)
            updateLine(blf0, btmleftfront, btmleftback, btmleftfrontvisible, color)
            return
        else

            local tl, tr, bl, br
            if drawn[player] == nil or #drawn[player] ~= 4 then
                tl, tr, bl, br = drawTemplate(player, 4)
            else
                tl, tr, bl, br = unpack(drawn[player])
            end

            local pos, size = root.CFrame, root.Size

            local topleft, topleftvisible = worldToViewportPoint(camera, (pos * cfnew(-size.X, size.Y, 0)).p);
            local topright, toprightvisible = worldToViewportPoint(camera, (pos * cfnew(size.X, size.Y, 0)).p);
            local btmleft, btmleftvisible = worldToViewportPoint(camera, (pos * cfnew(-size.X, -size.Y, 0)).p);
            local btmright, btmrightvisible = worldToViewportPoint(camera, (pos * cfnew(size.X, -size.Y, 0)).p);

            local topleft = v2new(topleft.X, topleft.Y)
            local topright = v2new(topright.X, topright.Y)
            local btmleft = v2new(btmleft.X, btmleft.Y)
            local btmright = v2new(btmright.X, btmright.Y)

            updateLine(tl, topleft, topright, topleftvisible, color)
            updateLine(tr, topright, btmright, toprightvisible, color)
            updateLine(bl, btmleft, topleft, btmleftvisible, color)
            updateLine(br, btmleft, btmright, btmrightvisible, color)
            return
        end


        -- I have never been more bored when doing 3d boxes.
    end

    function boxes:Remove(player)
        local data = drawn[player]
        if data == nil then return end

        if data then
            for i,v in pairs(data) do
                v:Remove()
                data[i] = nil
            end
        end
        drawn[player] = nil
    end

    function boxes:RemoveAll()
        for i,v in pairs(drawn) do
            pcall(function()
                for i2,v2 in pairs(v) do
                    v2:Remove()
                    v[i] = nil
                end
            end)
            drawn[i] = nil
        end
        drawn = {}
    end

    function boxes:End()
        completeStop = true
        for i,v in pairs(drawn) do
            for i2,v2 in pairs(v) do
                pcall(function()
                    v2:Remove()
                    v[i2] = nil
                end)
            end
            drawn[i] = nil
        end
        drawn = {}
    end
end


local visuals = {} do
    --/ Visuals

    visuals.enabled = settings:Get("visuals.enabled", true).Value

    local players = game:GetService("Players")
    local locpl = players.LocalPlayer
    local mouse = locpl:GetMouse()
    local isDescendantOf = game.IsDescendantOf
    local getPlayers = players.GetPlayers
    local findFirstChildOfClass = game.FindFirstChildOfClass

    local cfnew = CFrame.new

    local completeStop = false
    bindEvent(players.PlayerRemoving, function(p)
        if completeStop then return end
        boxes:Remove(p)
        esp:Remove(p)
    end)


    local camera = workspace.CurrentCamera
    local worldToViewportPoint = camera.WorldToViewportPoint

    local function remove(p)
        esp:Remove(p)
        boxes:Remove(p)
    end

    local circle = newdrawing("Circle", {
        Position = Vector2.new(mouse.X, mouse.Y+36),
        Radius = sett_2.fov,
        Color = Color3.fromRGB(240,240,240),
        Thickness = sett_2.fovthickness,
        Filled = false,
        Transparency = 0,
        NumSides = sett_2.fovsides,
        Visible = sett_2.fovcircle;
    })
    
    function visuals.step()
        --if visuals.enabled ~= true then return clearDrawn() end
        if completeStop then return end
        
        if (visuals.enabled and (sett_2.fovcircle)) then                 
            circle.Position = Vector2.new(mouse.X, mouse.Y+36)
            circle.Radius = sett_2.fov
            circle.NumSides = sett_2.fovsides
            circle.Thickness = sett_2.fovthickness
            circle.Transparency = .8
        else
            circle.Transparency = 0
        end

        if visuals.enabled and (esp.enabled or boxes.enabled) then

            if esp.enabled then
                esp.offset = cfnew(0, esp.yoffset, 0)
            end

            for i,v in pairs(getPlayers(players)) do
                if (v ~= locpl) then
                    local character = utility.getcharacter(v)
                    if character and isDescendantOf(character, game) == true then
                        local root = utility.getroot(character)
                        local humanoid = findFirstChildOfClass(character, "Humanoid")
                        if root and isDescendantOf(character, game) == true then
                            local screenpos, onscreen = worldToViewportPoint(camera, root.Position)
                            local dist = utility.myroot and (utility.myroot.Position - root.Position).Magnitude
                            local isteam = (v.Team~=nil and v.Team==locpl.Team) and not v.Neutral or false

                            if boxes.enabled then -- Profilebegin is life
                                boxes:Draw(v, character, root, humanoid, onscreen, isteam, dist)
                            else
                                boxes:Remove(v)
                            end
        
                            if esp.enabled then
                                esp:Draw(v, character, root, humanoid, onscreen, isteam, dist)
                            else
                                esp:Remove(v)
                            end
                        else
                            remove(v)
                        end
                    else
                        remove(v)
                    end
                end
            end
        else
            -- mhm
            boxes:RemoveAll()
            esp:RemoveAll()
        end
    end

    function visuals:End()
        completeStop = true
        boxes:End()
        esp:End()

        clearDrawn()
    end
    table.insert(end_funcs, visuals.End)
end



-- Ok yes
local run = {} do
    --/ Run

    local tostring = tostring;
    local warn = warn;
    local debug = debug;

    local runservice = game:GetService("RunService")
    local renderstep = runservice.RenderStepped
    local heartbeat = runservice.Heartbeat
    local stepped = runservice.Stepped
    local wait = renderstep.wait

    local function Warn(a, ...) -- ok frosty get to bed
        warn(tostring(a):format(...))
    end
    
    run.dt = 0
    run.time = tick()

    local engine = {
        {
            name = 'visuals.step',
            func = visuals.step
        };
    }
    local heartengine = {
    }
    local whilerender = {
    }

    run.onstep = {}
    run.onthink = {}
    run.onrender = {}
    function run.wait()
        wait(renderstep)
    end

    local rstname = "Renderstep"
    bindEvent(renderstep, function(delta)
        local ntime = tick()
        run.dt = ntime - run.time
        run.time = ntime

        for i,v in pairs(engine) do
            xpcall(v.func, function(err)
                Warn("Failed to run %s! %s | %s", v.name, tostring(err), debug.traceback())
                engine[i] = nil
            end, run.dt)
        end
    end)

    bindEvent(heartbeat, function(delta)
        for i,v in pairs(heartengine) do
            xpcall(v.func, function(err)
                Warn("Failed to run %s! %s | %s", v.name, tostring(err), debug.traceback())
                heartengine[i] = nil
            end, delta)
        end
    end)

    bindEvent(stepped, function(delta)
        for i,v in pairs(whilerender) do
            xpcall(v.func, function(err)
                Warn("Failed to run %s! %s | %s", v.name, tostring(err), debug.traceback())
                heartengine[i] = nil
            end, delta)
        end
    end)
end


local uid = tick() .. math.random(1,100000) .. math.random(1,100000)
if shared.main and shared.main.close and shared.main.uid~=uid then shared.main:close() end

local hud = loadstring(game:HttpGet("https://pastebin.com/raw/3hREvLEU", true))()[1]
table.insert(end_funcs, hud.End)

do
    --/ Main or something I am not sure what I am writing anymore
    settings:Save()

    main.enabled = true
    main.visible = hud.Visible
    function main:show()
        hud:show()
        main.visible = hud.Visible
    end

    function main:hide()
        hud:hide()
        main.visible = hud.Visible
    end

    setmetatable(main, { -- ok safazi be happy now
        __newindex = function(self, index, value)
            if (index == "Keybind") then
                settings:Set("hud.keybind", value)
                hud.Keybind = value
                return
            end
        end;
    })

    shared.main = main

    local players = game:GetService("Players")
    local loc = players.LocalPlayer
    bindEvent(players.PlayerRemoving, function(p)
        if p == loc then
            settings:Save()
        end
    end)

end

local shais = sett_2


-- I didn't think this ui lib through
local Aiming = hud:AddTab({
	Text = "silent aim",
})

Aiming:AddToggle({
    Text = "enable silent aim",
    State = shais.silentaim,
}, function(new)
    shais.silentaim = new
end)

Aiming:AddSlider({
    Text = "headshot chance",
    Current = shais.headshotchance,
}, {0, 100, 1}, function(new)
    shais.headshotchance = new
end)

local FieldOfView = Aiming:AddToggleCategory({
    Text = "fov",
    State = shais.fovcircle,
}, function(state) 
    shais.fovcircle = state
end)

FieldOfView:AddSlider({
    Text = "Radius",
    Current = shais.fov,
}, {1, 1000, 1}, function(new)
    shais.fov = new
end)

FieldOfView:AddSlider({
    Text = "Sides",
    Current = shais.fovsides,
}, {6, 40, 1}, function(new)
    shais.fovsides = new
end)


FieldOfView:AddSlider({
    Text = "Thickness",
    Current = shais.fovthickness,
}, {0.1, 50, 0.1}, function(new)
    shais.fovthickness = new
end)



local Character = hud:AddTab({
	Text = "character",
})


Character:AddToggle({
    Text = "no fall damage",
    State = shais.nofalldamage,
}, function(new)
    shais.nofalldamage = new
end)


Character:AddToggle({
    Text = "enable speed",
    State = shais.setwalkspeed,
}, function(new)
    shais.setwalkspeed = new
    if (not new) then
        storage.char.setbasewalkspeed(char, storage.char.oldWalkspeed)
    else
        storage.char.setbasewalkspeed(char, shais.walkspeed)
    end
end)

Character:AddSlider({
    Text = "speed",
    Current = shais.walkspeed,
}, {1, 100, 1}, function(new)
    shais.walkspeed = new
    storage.char.setbasewalkspeed(char, new)
end)

Character:AddToggle({
    Text = "enable jump",
    State = shais.setjumppower,
}, function(new)
    shais.setjumppower = new
end)

Character:AddSlider({
    Text = "jumppower",
    Current = shais.jumppower,
}, {1, 50, 1}, function(new)
    shais.jumppower = new
end)

local Hud = hud:AddTab({
    Text = "Hud",
})

hud.Keybind = settings:Get("hud.keybind", "RightAlt").Value
Hud:AddKeybind({
    Text = "Toggle",
    Current = hud.Keybind,
}, function(new)
    settings:Set("hud.keybind", new.Name)
    hud.Keybind = new.Name
end)

Hud:AddButton({
    Text = "Exit"
}, function()
    main:End()
end)
