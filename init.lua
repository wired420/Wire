--[[
    Wire by wired420 - Release: 1b

    These are some functions I've used multiple times. I'm now converting them into
    utility script so I can use them over and over without copy pasting them anymore.
    You are free to include this in any script/project. Some of these items may require
    error checking in their usage to avoid script/mq crashes. I've left these checks to
    you where I've felt delays would be required resulting in minimal code on your end.
    You should dictate the speed of your script. Not me. Where the code absolutely
    requires a delay like waiting for a pack to open (lag + inteface time) I will add
    as short of delays as possible. I've added folding regions to each section that
    leaves its comment heading visible in vscode. I've left param/return comments where
    useful for vscode usage. If MQ2DanNet is loaded. You'll see errors that happen in your
    other windows to alert you of what is going on, and which character it happened on.

    --- WARNING ---
    If you see REQUIRED in a function's description heading. It is YOUR responsibility
    to make sure those plugins or other luas are available and loaded in your script.
]]
--
local mq = require("mq")

local WIRE = {}

-- Supports formatted strings but not required. Will be used EXTREMELY minimally. Will
-- be announced as simply Wire: and will be bland colorless informational messages. For
-- example it will announce when an item is not found instead of crashing your script if
-- you feed it a bad item to select. (Ex: Wire: Item Not Found (Dog Food Lid))
--
---@param s string -- Message with optional formatting.
---@param ...? any -- Optional formatting arguments
function WIRE.report_error(s, ...)
    if mq.TLO.Plugin('MQ2DanNet').IsLoaded then
        mq.cmdf('/dgt all Wire: %s', string.format(s, ...))
    else
        print('Wire: ' .. string.format(s, ...))
    end
end

--[[
    BEGIN INVENTORY MANAGEMENT SECTION

    Available Functions: is_pack_open, get_pack_slot_name, is_top_slot_pack, select_first_item_in_inventory

]]
   --#region

-- Checks if pack is open.
--
---@param i number -- Item.ItemSlot()
---@return boolean
function WIRE.is_pack_open(i)
    if mq.TLO.Me.Inventory(i).Open() == 1 then
        return true
    end
    return false
end

-- Conversion for easily handling packs without math stuff.
--
---@param i number -- Item.ItemSlot()
---@return string
function WIRE.get_pack_slot_name(i)
    local pack = {
        [23] = 'pack1',
        [24] = 'pack2',
        [25] = 'pack3',
        [26] = 'pack4',
        [27] = 'pack5',
        [28] = 'pack6',
        [29] = 'pack7',
        [30] = 'pack8',
        [31] = 'pack9',
        [32] = 'pack10',
        [33] = 'pack11',
        [34] = 'pack12'
    }
    return pack[i]
end

-- Check if slot contains a pack.
--
---@param i number -- Item.ItemSlot()
---@return boolean
function WIRE.is_top_slot_pack(i)
    if i > 22 and i < 35 then
        local container = mq.TLO.Me.Inventory(i).Container()
        if container ~= nil and container > 0 then
            return true
        end
    end
    return false
end

-- Picks up or selects the first item found by exact name. Not case sensistive.
-- You should check for the item being selected or on cursor when being used.
--
---@param name string -- Item.Name()
function WIRE.select_first_item_in_inventory(name)
    local found_inv_top  = mq.TLO.FindItem('=' .. name).ItemSlot()
    local found_inv_slot = mq.TLO.FindItem('=' .. name).ItemSlot2() + 1

    if found_inv_top ~= nil then
        if WIRE.is_top_slot_pack(found_inv_top) then
            if not WIRE.is_pack_open(found_inv_top) then
                mq.cmdf('/itemnotify %s rightmouseup', found_inv_top)
                while not WIRE.is_pack_open(found_inv_top) do
                    mq.delay(100)
                end
            end
            mq.cmdf('/itemnotify in %s %s leftmouseup', WIRE.get_pack_slot_name(found_inv_top), found_inv_slot)
        else
            mq.cmdf('/itemnotify %s leftmouseup', found_inv_top)
        end
    else
        WIRE.report_error('Item Not Found (%s)', name)
    end
end

--#endregion

--[[
    BEGIN MOVEMENT MANAGEMENT SECTION

    Available Functions: travel_to_remote_zone

]]
   --#region

-- Uses /travelto, to attempt to go to a zone.
--
-- REQUIRED: MQ2EasyFind, MQ2Nav, Nav Meshes (Optional: MQ2MeshManager)
--
---@param name string -- shortzonename (REQUIRES shortname)
---@param locyxz? string -- Optional: LocYXZ from intended destination (ex: in front of a store vendor, or the bank) [Format: "123, -2731, 25.20"]
---@param heading? number -- Optional: Counter Clockwise Heading to face at intended destination
---Usage: travel_to_remote_zone('poknowledge', '123, -2371, 25.20', 220)
---Usage: travel_to_remote_zone('poknowledge')
function WIRE.travel_to_remote_zone(name, locyxz, heading)
    local zoning = false
    local naving = false
    local sz = require('\\data\\zoneshortnames.lua')
    for _, v in pairs(sz.ZoneShortNames) do
        if v == name then
            mq.cmdf('/travelto %s', name)
            zoning = true
            break
        end
    end
    if not zoning then
        error.report_error('Failed to find (%s) in zone list.', name)
        return
    else
        while mq.TLO.Zone.ShortName() ~= name do
            mq.delay(1000)
        end
    end
    zoning = false
    if locyxz ~= nil then
        mq.cmdf("/nav locyxz %s", locyxz)
        naving = true
    end
    if not naving then
        error.report_error('Failed to navigate to location (%s)', locyxz)
        return
    end
    while mq.TLO.Navigation.Active() do
        mq.delay(1000)
    end
end

--#endregion

return WIRE
