--[[---------------------------------------------------------------------------------
  Clique by Cladhaire <cladhaire@gmail.com>
----------------------------------------------------------------------------------]]

Clique = {Locals = {}}

assert( DongleStub, string.format( "Clique requires DongleStub." ) )
DongleStub( "Dongle-1.2" ):New( "Clique", Clique )
Clique.version = GetAddOnMetadata( "Clique", "Version" )
if Clique.version == "wowi:revision" then Clique.version = "SVN" end

local L = Clique.Locals

function Clique:Enable()
  -- Grab the localisation header
  L = Clique.Locals
  self.ooc = {}

  self.defaults = {
    profile = {
      clicksets = {
        [ L.CLICKSET_DEFAULT ] = {},
        [ L.CLICKSET_HARMFUL ] = {},
        [ L.CLICKSET_HELPFUL ] = {},
        [ L.CLICKSET_OOC ] = {},
      },
      blacklist = {
      },
      tooltips = false,
    },
    char = {
      switchSpec = false,
      downClick = false,
    },
  }

  self.db = self:InitializeDB( "CliqueDB", self.defaults )
  self.profile = self.db.profile
  self.clicksets = self.profile.clicksets

  self.editSet = self.clicksets[ L.CLICKSET_DEFAULT ]

  ClickCastFrames = ClickCastFrames or {}
  self.ccframes = ClickCastFrames

  local newindex = function(t,k,v)
    if v == nil then
      Clique:UnregisterFrame(k)
      rawset(self.ccframes, k, nil)
    else
      Clique:RegisterFrame(k)
      rawset(self.ccframes, k, v)
    end
  end

  ClickCastFrames = setmetatable({}, {__newindex=newindex})

  Clique:OptionsOnLoad()
  Clique:EnableFrames()

  -- Register for dongle events
  self:RegisterMessage( "DONGLE_PROFILE_CHANGED" )
  self:RegisterMessage( "DONGLE_PROFILE_DELETED" )
  self:RegisterMessage( "DONGLE_PROFILE_RESET" )

  self:RegisterEvent( "PLAYER_REGEN_ENABLED" )
  self:RegisterEvent( "PLAYER_REGEN_DISABLED" )

  self:RegisterEvent( "LEARNED_SPELL_IN_TAB" )
  self:RegisterEvent( "COMMENTATOR_SKIRMISH_QUEUE_REQUEST" )
  self:RegisterEvent( "ADDON_LOADED" )

  -- Change to correct profile based on talent spec
  if self.db.char.switchSpec then
    self.silentProfile = true
    self.talentGroup = CA_GetActiveSpecId() + 1
    if self.db.char[ "spec"..self.talentGroup.."Profile" ] then
      self.db:SetProfile( self.db.char[ "spec"..self.talentGroup.."Profile" ] )
    end
    self.silentProfile = false
  end

  self:UpdateClicks()

  -- Register all frames that snuck in before we did =)
  for frame in pairs( self.ccframes ) do
    self:RegisterFrame( frame )
  end

-- The original code:
  -- Securehook CreateFrame to catch any new raid frames
--  local raidFunc = function( type, name, parent, template )
--    if template == "RaidPulloutButtonTemplate" then
--      ClickCastFrames[ getglobal( name.."ClearButton" ) ] = true
--    end
--  end
--  hooksecurefunc( "CreateFrame", raidFunc )

  -- My code:  Raid support
  -- Previously:
  --   Must reloadui if raid size changes
  --   Each person who joins is appended as a new number. For example, a third person to join is CompactRaidFrame3 which wouldn't have existed in the initial reloadui.
  --   Once that person exists, then the CompactRaidFrame_ is populated and then any person can leave/join and be reassigned that slot, and Clique will work as-expected.
  -- In a raid this will apply to CompactRaidFrame1 etc.
  -- This will also apply to raid-style party frames via CompactPartyFrameMember1 etc.
  self:RegisterEvent( "RAID_ROSTER_UPDATE" )
  function Clique:RAID_ROSTER_UPDATE(event, addon)
    --self:Print( "RAID_ROSTER_UPDATE - triggering Enable()" )
    self:Enable()
  end


  local oldotsu = GameTooltip:GetScript( "OnTooltipSetUnit" )
  if oldotsu then
    GameTooltip:SetScript( "OnTooltipSetUnit", function(...)
      Clique:AddTooltipLines()
      return oldotsu(...)
    end)
  else
    GameTooltip:SetScript( "OnTooltipSetUnit", function(...)
      Clique:AddTooltipLines()
    end)
  end
    
  -- Create our slash command
  self.cmd = self:InitializeSlashCommand( "Clique commands", "CLIQUE", "clique" )
  self.cmd:RegisterSlashHandler( "debug - Enables extra messages for debugging purposes", "debug", "ShowAttributes" )
  self.cmd:InjectDBCommands( self.db, "copy", "delete", "list", "reset", "set" )
  self.cmd:RegisterSlashHandler( "tooltip - Enables binding lists in tooltips.", "tooltip", "ToggleTooltip" )
  self.cmd:RegisterSlashHandler( "showbindings - Shows a window that contains the current bindings", "showbindings", "ShowBindings" )

  -- Place the Clique tab
  self:LEARNED_SPELL_IN_TAB()

  -- Register the arena frames, if they're already loaded
  if IsAddOnLoaded( "Blizzard_ArenaUI" ) then
    self:EnableArenaFrames()
  end

end  --  function Clique:Enable()


-- EDITED
function Clique:EnableFrames()
  --self:Print( "triggered Clique:EnableFrames()" )
  -- My preference:
  CompactRaidFrameContainer:SetScale( 1.5 )
  -- Other notable frames related to raiding, but which don't seem to matter:
  --   CompactRaidFrameContainer:Hide()
  --   CompactRaidFrame2:Hide()
  --   CompactRaidFrameContainerBorderFrame:Hide()
  -- Still more notable frames:
  --   CompactRaidFrame2Container, CompactRaidFrame2Elements, CompactRaidFrame2HealthBar, CompactRaidFrame2PowerBar, 
  local tbl = {
    PlayerFrame,
    PetFrame,
    PartyMemberFrame1,
    PartyMemberFrame2,
    PartyMemberFrame3,
    PartyMemberFrame4,
    PartyMemberFrame1PetFrame,
    PartyMemberFrame2PetFrame,
    PartyMemberFrame3PetFrame,
    PartyMemberFrame4PetFrame,
    TargetFrame,
    TargetFrameToT,
    FocusFrame,
        FocusFrameToT,
        Boss1TargetFrame,
        Boss2TargetFrame,
        Boss3TargetFrame,
        Boss4TargetFrame,
    CompactRaidFrame1, 
      CompactRaidFrame2, 
      CompactRaidFrame3, 
      CompactRaidFrame4,
      CompactRaidFrame5,
      CompactRaidFrame6,
      CompactRaidFrame7,
      CompactRaidFrame8,
      CompactRaidFrame9,
      CompactRaidFrame10,
      CompactRaidFrame11,
      CompactRaidFrame12,
      CompactRaidFrame13,
      CompactRaidFrame14,
      CompactRaidFrame15,
      CompactRaidFrame16,
      CompactRaidFrame17,
      CompactRaidFrame18,
      CompactRaidFrame20,
      CompactRaidFrame21,
      CompactRaidFrame22,
      CompactRaidFrame23,
      CompactRaidFrame24,
      CompactRaidFrame25,
      CompactRaidFrame26,
      CompactRaidFrame27,
      CompactRaidFrame28,
      CompactRaidFrame30,
      CompactRaidFrame31,
      CompactRaidFrame32,
      CompactRaidFrame33,
      CompactRaidFrame34,
      CompactRaidFrame35,
      CompactRaidFrame36,
      CompactRaidFrame37,
      CompactRaidFrame38,
      CompactRaidFrame30,
      CompactRaidFrame31,
      CompactRaidFrame32,
      CompactRaidFrame33,
      CompactRaidFrame34,
      CompactRaidFrame35,
      CompactRaidFrame36,
      CompactRaidFrame37,
      CompactRaidFrame38,
      CompactRaidFrame39,
      CompactRaidFrame40,
    CompactRaidGroup1Member1,
      CompactRaidGroup1Member2,
      CompactRaidGroup1Member3,
      CompactRaidGroup1Member4,
      CompactRaidGroup1Member5,
      CompactRaidGroup2Member1,
      CompactRaidGroup2Member2,
      CompactRaidGroup2Member3,
      CompactRaidGroup2Member4,
      CompactRaidGroup2Member5,
      CompactRaidGroup3Member1,
      CompactRaidGroup3Member2,
      CompactRaidGroup3Member3,
      CompactRaidGroup3Member4,
      CompactRaidGroup3Member5,
      CompactRaidGroup4Member1,
      CompactRaidGroup4Member2,
      CompactRaidGroup4Member3,
      CompactRaidGroup4Member4,
      CompactRaidGroup4Member5,
      CompactRaidGroup5Member1,
      CompactRaidGroup5Member2,
      CompactRaidGroup5Member3,
      CompactRaidGroup5Member4,
      CompactRaidGroup5Member5,
      CompactRaidGroup6Member1,
      CompactRaidGroup6Member2,
      CompactRaidGroup6Member3,
      CompactRaidGroup6Member4,
      CompactRaidGroup6Member5,
      CompactRaidGroup7Member1,
      CompactRaidGroup7Member2,
      CompactRaidGroup7Member3,
      CompactRaidGroup7Member4,
      CompactRaidGroup7Member5,
      CompactRaidGroup8Member1,
      CompactRaidGroup8Member2,
      CompactRaidGroup8Member3,
      CompactRaidGroup8Member4,
      CompactRaidGroup8Member5,
    CompactRaidGroup3Member5,
      CompactPartyFrameMember1,
      CompactPartyFrameMember2,
      CompactPartyFrameMember3,
      CompactPartyFrameMember4,
      CompactPartyFrameMember5,
  }
  for i,frame in pairs(tbl) do
    rawset(self.ccframes, frame, true)
  end
end   --  function Clique:EnableFrames()


function Clique:SpellBookButtonPressed(frame, button)
  local texture = getglobal( frame:GetParent():GetName().."IconTexture" ):GetTexture()
  local name = getglobal( frame:GetParent():GetName().."SpellName" ):GetText()
  local rank = getglobal( frame:GetParent():GetName().."SubSpellName" ):GetText()

  if rank == L.RACIAL_PASSIVE or rank == L.PASSIVE then
    StaticPopup_Show( "CLIQUE_PASSIVE_SKILL" )
    return
  end

  local type = "spell"

  if     self.editSet == self.clicksets[ L.CLICKSET_HARMFUL ]  then  button = string.format( "%s%d", "harmbutton", self:GetButtonNumber( button ) )
  elseif self.editSet == self.clicksets[ L.CLICKSET_HELPFUL ]  then  button = string.format( "%s%d", "helpbutton", self:GetButtonNumber( button ) )
  else                                                             button = self:GetButtonNumber( button )
  end

  -- Clear the rank if "Show all spell ranks" is selected
  if not GetCVarBool( "ShowAllSpellRanks" ) then
    rank = nil
  end

  -- Build the structure
  local t = {
    [ "button" ] = button,
    [ "modifier" ] = self:GetModifierText(),
    [ "texture" ] = texture,
    [ "type" ] = type,
    [ "arg1" ] = name,
    [ "arg2" ] = rank,
  }

  local key = t.modifier .. t.button

  if self:CheckBinding(key) then
    StaticPopup_Show( "CLIQUE_BINDING_PROBLEM" )
    return
  end

  self.editSet[ key ] = t
  self:ListScrollUpdate()
  self:UpdateClicks()
  -- We can only make changes when out of combat
  self:PLAYER_REGEN_ENABLED()
end  --  function Clique:SpellBookButtonPressed(frame, button)


-- Player is LEAVING combat
function Clique:PLAYER_REGEN_ENABLED()
  self:ApplyClickSet( L.CLICKSET_DEFAULT )
  self:RemoveClickSet( L.CLICKSET_HARMFUL )
  self:RemoveClickSet( L.CLICKSET_HELPFUL )
  self:ApplyClickSet( self.ooc )
end


-- Player is ENTERING combat
function Clique:PLAYER_REGEN_DISABLED()
  self:RemoveClickSet( self.ooc )
  self:ApplyClickSet( L.CLICKSET_DEFAULT )
  self:ApplyClickSet( L.CLICKSET_HARMFUL )
  self:ApplyClickSet( L.CLICKSET_HELPFUL )
end


function Clique:UpdateClicks()
  local ooc  = self.clicksets[ L.CLICKSET_OOC ]
  local harm = self.clicksets[ L.CLICKSET_HARMFUL ]
  local help = self.clicksets[ L.CLICKSET_HELPFUL ]

  -- Since harm/help buttons take priority over any others, we can't
  --
  -- just apply the OOC set last.  Instead we use the self.ooc pseudo
  -- set (which we build here) which contains only those help/harm
  -- buttons that don't conflict with those defined in OOC.

  self.ooc = table.wipe( self.ooc or {} )

  -- Create a hash map of the "taken" combinations
  local takenBinds = {}

  for name, entry in pairs( ooc ) do
    local key = string.format( "%s:%s", entry.modifier, entry.button )
    takenBinds[ key ] = true
    table.insert( self.ooc, entry )
  end

  for name, entry in pairs( harm ) do
    local button = string.gsub( entry.button, "harmbutton", "" )
    local key = string.format( "%s:%s", entry.modifier, button )
    if not takenBinds[ key ] then
      table.insert( self.ooc, entry )
    end
  end

  for name, entry in pairs( help ) do
    local button = string.gsub( entry.button, "helpbutton", "" )
    local key = string.format( "%s:%s", entry.modifier, button )
    if not takenBinds[ key ] then
      table.insert( self.ooc, entry )
    end
  end

  self:UpdateTooltip()
end  --  function Clique:UpdateClicks()


function Clique:RegisterFrame( frame )
  local name = frame:GetName()

  if self.profile.blacklist[ name ] then 
    rawset( self.ccframes, frame, false )
    return 
  end

  if not ClickCastFrames[ frame ] then 
    rawset( self.ccframes, frame, true )
    if CliqueTextListFrame then
      Clique:TextListScrollUpdate()
    end
  end

    -- Register AnyUp or AnyDown on this frame, depending on configuration
    self:SetClickType( frame )

  if frame:CanChangeAttribute() or frame:CanChangeProtectedState() then
    if InCombatLockdown() then
      self:ApplyClickSet( L.CLICKSET_DEFAULT, frame )
      self:ApplyClickSet( L.CLICKSET_HELPFUL, frame )
      self:ApplyClickSet( L.CLICKSET_HARMFUL, frame )
    else
      self:ApplyClickSet( L.CLICKSET_DEFAULT, frame )
      self:ApplyClickSet( self.ooc, frame )
    end
  end
end  --  function Clique:RegisterFrame(frame)


function Clique:ApplyClickSet( name, frame )
  local set = self.clicksets[ name ] or name

  if frame then
    for modifier,entry in pairs( set ) do
      self:SetAttribute( entry, frame )
    end
  else
    for modifier,entry in pairs( set ) do
      self:SetAction( entry )
    end
  end
end


function Clique:RemoveClickSet( name, frame )
  local set = self.clicksets[ name ] or name

  if frame then
    for modifier,entry in pairs( set ) do
      self:DeleteAttribute( entry, frame )
    end
  else
    for modifier,entry in pairs( set ) do
      self:DeleteAction( entry )
    end
  end
end


function Clique:UnregisterFrame(frame)
  assert(not InCombatLockdown(), "An addon attempted to unregister a frame from Clique while in combat.")
  for name,set in pairs( self.clicksets ) do
    for modifier,entry in pairs( set ) do
      self:DeleteAttribute( entry, frame )
    end
  end
end


function Clique:DONGLE_PROFILE_CHANGED( event, db, parent, svname, profileKey )
  if db == self.db then
    if not self.silentProfile then
      self:PrintF( L.PROFILE_CHANGED, profileKey )
    end

    for name,set in pairs( self.clicksets ) do
      self:RemoveClickSet( set )
    end
    self:RemoveClickSet( self.ooc )

    self.profile = self.db.profile
    self.clicksets = self.profile.clicksets
    self.editSet = self.clicksets[ L.CLICKSET_DEFAULT ]
    self.profileKey = profileKey

    -- Refresh the profile editor if it exists
    self.textlistSelected = nil
    self:TextListScrollUpdate()
    self:ListScrollUpdate()
    self:UpdateClicks()

    self:PLAYER_REGEN_ENABLED()
  end
end


function Clique:DONGLE_PROFILE_RESET( event, db, parent, svname, profileKey )
  if db == self.db then
    for name,set in pairs( self.clicksets ) do
      self:RemoveClickSet( set )
    end
    self:RemoveClickSet( self.ooc )

    self.profile = self.db.profile
    self.clicksets = self.profile.clicksets
    self.editSet = self.clicksets[ L.CLICKSET_DEFAULT ]
    self.profileKey = profileKey
  
    -- Refresh the profile editor if it exists
    self.textlistSelected = nil
    self:TextListScrollUpdate()
    self:ListScrollUpdate()
    self:UpdateClicks()

    self:PLAYER_REGEN_ENABLED()
    self:Print( L.PROFILE_RESET, profileKey )
  end
end


function Clique:DONGLE_PROFILE_DELETED( event, db, parent, svname, profileKey )
  if db == self.db then
    self:PrintF( L.PROFILE_DELETED, profileKey )

    self.textlistSelected = nil
    self:TextListScrollUpdate()
    self:ListScrollUpdate()
  end
end


function Clique:SetAttribute( entry, frame )
  local name = frame:GetName()

  if  self.profile.blacklist and self.profile.blacklist[ name ] then
    return
  end

  -- Set up any special attributes
  local type,button,value

  if not tonumber( entry.button ) then
    type,button = select( 3, string.find( entry.button, "(%a+)button(%d+)" ) )
    frame:SetAttribute( entry.modifier..entry.button, type..button )
    assert( frame:GetAttribute( entry.modifier..entry.button, type..button ) )
    button = string.format( "-%s%s", type, button )
  end

  button = button or entry.button

  if entry.type == "actionbar" then
    frame:SetAttribute( entry.modifier.."type"..button, entry.type )
    frame:SetAttribute( entry.modifier.."action"..button, entry.arg1 )
  elseif entry.type == "action" then
    frame:SetAttribute( entry.modifier.."type"..button, entry.type )
    frame:SetAttribute( entry.modifier.."action"..button, entry.arg1 )
    if entry.arg2 then
      frame:SetAttribute( entry.modifier.."unit"..button, entry.arg2 )
    end
  elseif entry.type == "pet" then
    frame:SetAttribute( entry.modifier.."type"..button, entry.type )
    frame:SetAttribute( entry.modifier.."action"..button, entry.arg1 )
    if entry.arg2 then
      frame:SetAttribute( entry.modifier.."unit"..button, entry.arg2 )
    end
  elseif entry.type == "spell" then
    local rank = entry.arg2
    local cast
    if rank then
      if tonumber( rank ) then
        -- The rank is a number (pre-2.3) so fill in the format
        cast = L.CAST_FORMAT:format( entry.arg1, rank )
      else
        -- The whole rank string is saved (post-2.3) so use it
        cast = string.format( "%s(%s)", entry.arg1, rank )
      end
    else
      cast = entry.arg1
    end

    frame:SetAttribute( entry.modifier.."type"..button, entry.type )
    frame:SetAttribute( entry.modifier.."spell"..button, cast )

    frame:SetAttribute( entry.modifier.."bag"..button, entry.arg2 )
    frame:SetAttribute( entry.modifier.."slot"..button, entry.arg3 )
    frame:SetAttribute( entry.modifier.."item"..button, entry.arg4 )
    if entry.arg5 then
      frame:SetAttribute( entry.modifier.."unit"..button, entry.arg5 )
    end
  elseif entry.type == "item" then
    frame:SetAttribute( entry.modifier.."type"..button, entry.type )
    frame:SetAttribute( entry.modifier.."bag"..button, entry.arg1 )
    frame:SetAttribute( entry.modifier.."slot"..button, entry.arg2 )
    frame:SetAttribute( entry.modifier.."item"..button, entry.arg3 )
    if entry.arg4 then
      frame:SetAttribute( entry.modifier.."unit"..button, entry.arg4 )
    end
  elseif entry.type == "macro" then
    frame:SetAttribute( entry.modifier.."type"..button, entry.type )
    if entry.arg1 then
      frame:SetAttribute( entry.modifier.."macro"..button, entry.arg1 )
    else
      local unit = SecureButton_GetModifiedUnit( frame, entry.modifier.."unit"..button )
      local macro = tostring( entry.arg2 )
      if unit and macro then
        macro = macro:gsub( "target%s*=%s*clique", "target="..unit )
      end

      frame:SetAttribute( entry.modifier.."macro"..button, nil )
      frame:SetAttribute( entry.modifier.."macrotext"..button, macro )
    end
  elseif entry.type == "stop" then
    frame:SetAttribute( entry.modifier.."type"..button, entry.type )
  elseif entry.type == "target" then
    frame:SetAttribute( entry.modifier.."type"..button, entry.type )
    if entry.arg1 then
      frame:SetAttribute( entry.modifier.."unit"..button, entry.arg1 )
    end
  elseif entry.type == "focus" then
    frame:SetAttribute( entry.modifier.."type"..button, entry.type )
    if entry.arg1 then
      frame:SetAttribute( entry.modifier.."unit"..button, entry.arg1 )
    end
  elseif entry.type == "assist" then
    frame:SetAttribute( entry.modifier.."type"..button, entry.type )
    if entry.arg1 then
      frame:SetAttribute( entry.modifier.."unit"..button, entry.arg1 )
    end
  elseif entry.type == "click" then
    frame:SetAttribute( entry.modifier.."type"..button, entry.type )
    frame:SetAttribute( entry.modifier.."clickbutton"..button, getglobal( entry.arg1 ) )
  elseif entry.type == "menu" then
    frame:SetAttribute( entry.modifier.."type"..button, entry.type )
  end
end  --  function Clique:SetAttribute( entry, frame )


function Clique:DeleteAttribute( entry, frame )
  local name = frame:GetName()
  if  self.profile.blacklist and self.profile.blacklist[ name ] then
    return
  end

  local type,button,value

  if not tonumber( entry.button ) then
    type,button = select( 3, string.find( entry.button, "(%a+)button(%d+)" ) )
    frame:SetAttribute( entry.modifier..entry.button, nil )
    button = string.format( "-%s%s", type, button )
  end

  button = button or entry.button

  entry.delete = true

  frame:SetAttribute( entry.modifier.."type"..button, nil )
  frame:SetAttribute( entry.modifier..entry.type..button, nil )
end


function Clique:SetAction( entry )
  for frame,enabled in pairs( self.ccframes ) do
    if enabled then
      self:SetAttribute( entry, frame )
    end
  end
end


function Clique:DeleteAction(entry)
  for frame in pairs( self.ccframes ) do
    self:DeleteAttribute( entry, frame )
  end
end


function Clique:ShowAttributes()
  self:Print( "Enabled enhanced debugging." )
  PlayerFrame:SetScript( "OnAttributeChanged", function(...) self:Print(...) end )
  self:UnregisterFrame( PlayerFrame )
  self:RegisterFrame( PlayerFrame )
end


local tt_ooc = {}
local tt_help = {}
local tt_harm = {}
local tt_default = {}


function Clique:UpdateTooltip()
  local ooc = self.ooc
  local default = self.clicksets[ L.CLICKSET_DEFAULT ]
  local harm    = self.clicksets[ L.CLICKSET_HARMFUL ]
  local help    = self.clicksets[ L.CLICKSET_HELPFUL ]

  for k,v in pairs( tt_ooc     ) do tt_ooc[ k ]     = nil end
  for k,v in pairs( tt_help    ) do tt_help[ k ]    = nil end
  for k,v in pairs( tt_harm    ) do tt_harm[ k ]    = nil end
  for k,v in pairs( tt_default ) do tt_default[ k ] = nil end

  -- Build the ooc lines, which includes both helpful and harmful
  for k,v in pairs( ooc ) do
    local button = self:GetButtonText( v.button )
    local mod = string.format( "%s%s", v.modifier or "", button )
    local action = string.format( "%s (%s)", v.arg1 or "", v.type )
    table.insert( tt_ooc, {mod = mod, action = action} )
  end

  -- Build the default lines
  for k,v in pairs( default ) do
    local button = self:GetButtonText( v.button )
    local mod = string.format( "%s%s", v.modifier or "", button )
    local action = string.format( "%s (%s)", v.arg1 or "", v.type )
    table.insert( tt_default, {mod = mod, action = action} )
  end

  -- Build the harm lines
  for k,v in pairs( harm ) do
    local button = self:GetButtonText( v.button )
    local mod = string.format( "%s%s", v.modifier or "", button )
    local action = string.format( "%s (%s)", v.arg1 or "", v.type )
    table.insert( tt_harm, {mod = mod, action = action} )
  end

  -- Build the help lines
  for k,v in pairs( help ) do
    local button = self:GetButtonText( v.button )
    local mod = string.format( "%s%s", v.modifier or "", button )
    local action = string.format( "%s (%s)", v.arg1 or "", v.type )
    table.insert( tt_help, {mod = mod, action = action} )
  end

  local function sort( a, b )
    return a.mod < b.mod
  end

  table.sort( tt_ooc, sort )
  table.sort( tt_default, sort )
  table.sort( tt_harm, sort )
  table.sort( tt_help, sort )
end  --  function Clique:UpdateTooltip()


function Clique:AddTooltipLines()
  if not self.profile.tooltips then return end

  local frame = GetMouseFocus()
  if not frame then return end
  if not self.ccframes[ frame ] then return end

  -- Add a buffer line
  GameTooltip:AddLine( " " )
  if UnitAffectingCombat( "player" ) then
    if #tt_default ~= 0 then
      GameTooltip:AddLine( "Default bindings:" )
      for k,v in ipairs( tt_default ) do  GameTooltip:AddDoubleLine( v.mod, v.action, 1, 1, 1, 1, 1, 1 )  end
    end

    if #tt_help ~= 0 and not UnitCanAttack( "player", "mouseover" ) then
      GameTooltip:AddLine( "Helpful bindings:" )
      for k,v in ipairs(tt_help)    do  GameTooltip:AddDoubleLine( v.mod, v.action, 1, 1, 1, 1, 1, 1 )  end
    end

    if #tt_harm ~= 0 and UnitCanAttack( "player", "mouseover" ) then
      GameTooltip:AddLine( "Hostile bindings:" )
      for k,v in ipairs( tt_harm )    do  GameTooltip:AddDoubleLine( v.mod, v.action, 1, 1, 1, 1, 1, 1 )  end
    end
  else
    if #tt_ooc ~= 0 then
      GameTooltip:AddLine( "Out of combat bindings:" )
      for k,v in ipairs( tt_ooc )     do  GameTooltip:AddDoubleLine( v.mod, v.action, 1, 1, 1, 1, 1, 1 )  end
    end
  end
end  --  function Clique:AddTooltipLines()


function Clique:ToggleTooltip()
  self.profile.tooltips = not self.profile.tooltips
  self:PrintF(
    "Listing of bindings in tooltips has been %s", 
    self.profile.tooltips and "Enabled" or "Disabled"
  )
end


function Clique:ShowBindings()
  if not CliqueTooltip then
    CliqueTooltip = CreateFrame( "GameTooltip", "CliqueTooltip", UIParent, "GameTooltipTemplate" )
    CliqueTooltip:SetPoint( "CENTER", 0, 0 )
    CliqueTooltip.close = CreateFrame( "Button", nil, CliqueTooltip )
    CliqueTooltip.close:SetHeight( 32 )
    CliqueTooltip.close:SetWidth( 32 )
    CliqueTooltip.close:SetPoint( "TOPRIGHT", 1, 0 )
    CliqueTooltip.close:SetScript( "OnClick", function() 
      CliqueTooltip:Hide()
    end)
    CliqueTooltip.close:SetNormalTexture( "Interface\\Buttons\\UI-Panel-MinimizeButton-Up" )
    CliqueTooltip.close:SetPushedTexture( "Interface\\Buttons\\UI-Panel-MinimizeButton-Down" )
    CliqueTooltip.close:SetHighlightTexture( "Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight" )

    CliqueTooltip:EnableMouse()
    CliqueTooltip:SetMovable()
    CliqueTooltip:SetPadding( 16 )
    CliqueTooltip:SetBackdropBorderColor( TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b )
    CliqueTooltip:SetBackdropColor( TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b )

    CliqueTooltip:RegisterForDrag( "LeftButton" )
    CliqueTooltip:SetScript( "OnDragStart", function( self )
      self:StartMoving()
    end)
    CliqueTooltip:SetScript( "OnDragStop", function( self )
      self:StopMovingOrSizing()
      ValidateFramePosition( self )
    end)    
    CliqueTooltip:SetOwner( UIParent, "ANCHOR_PRESERVE" )
  end

  if not CliqueTooltip:IsShown() then
    CliqueTooltip:SetOwner( UIParent, "ANCHOR_PRESERVE" )
  end

  -- Actually fill it with the bindings
  CliqueTooltip:SetText( "Clique Bindings" )

  if #tt_default > 0 then
    CliqueTooltip:AddLine( " " )
    CliqueTooltip:AddLine( "Default bindings:" )
    for k,v in ipairs( tt_default )   do  CliqueTooltip:AddDoubleLine( v.mod, v.action, 1, 1, 1, 1, 1, 1 )  end
  end

  if #tt_help > 0 then
    CliqueTooltip:AddLine( " " )
    CliqueTooltip:AddLine( "Helpful bindings:" )
    for k,v in ipairs( tt_help )      do  CliqueTooltip:AddDoubleLine( v.mod, v.action, 1, 1, 1, 1, 1, 1 )   end
  end

  if #tt_harm > 0 then
    CliqueTooltip:AddLine( " " )
    CliqueTooltip:AddLine( "Hostile bindings:" )
    for k,v in ipairs(tt_harm)      do  CliqueTooltip:AddDoubleLine( v.mod, v.action, 1, 1, 1, 1, 1, 1 )  end
  end

  if #tt_ooc > 0 then
    CliqueTooltip:AddLine( " " )
    CliqueTooltip:AddLine( "Out of combat bindings:" )
    for k,v in ipairs( tt_ooc )       do  CliqueTooltip:AddDoubleLine( v.mod, v.action, 1, 1, 1, 1, 1, 1 )  end
  end

  CliqueTooltip:Show()
end  --  function Clique:ShowBindings()


function Clique:COMMENTATOR_SKIRMISH_QUEUE_REQUEST( event, typeName, newGroup )
  if typeName ~= "ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED" then return end

  if self.db.char.switchSpec then
    self:Print( "Detected a talent spec change, changing profile" )
    -- self:Print( "Detected "..typeName..", changing profile to "..newGroup )

    newGroup = newGroup + 1
    if self.db.char[ "spec"..newGroup.."Profile" ] then
      self.db:SetProfile( self.db.char[ "spec"..newGroup.."Profile" ] )
    end

    if CliqueFrame then
      CliqueFrame.title:SetText( "Clique v. " .. Clique.version .. " - " .. tostring( Clique.db.keys.profile ) )
    end
  end
end


function Clique:SetClickType( frame )
  local clickType = Clique.db.char.downClick and "AnyDown" or "AnyUp"
  if frame then
    frame:RegisterForClicks( clickType )
  else
    for frame, enabled in pairs( self.ccframes ) do
      if enabled then
        frame:RegisterForClicks( clickType )
      end
    end
  end
end


function Clique:EnableArenaFrames()
  local arenaFrames = {
    ArenaEnemyFrame1,
    ArenaEnemyFrame2,
    ArenaEnemyFrame3,
    ArenaEnemyFrame4,
    ArenaEnemyFrame5,
  }

  for idx,frame in ipairs( arenaFrames ) do
    rawset( self.ccframes, frame, true )
  end
end


function Clique:ADDON_LOADED( event, addon )
  if addon == "Blizzard_ArenaUI" then
    self:EnableArenaFrames()
  end
end
