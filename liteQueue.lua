--[[ 
  @file       oqueue.lua
  @brief      warcraft addon for finding and queuing premade groups for bgs

  @author     rmcinnis
  @date       april 06, 2012
  @copyright  Solid ICE Technologies
              this file may be distributed so long as it remains unaltered
              if this file is posted to a web site, credit must be given to me along with a link to my web page
              no code in this file may be used in other works without expressed permission  
]]--
local addonName, OQ = ... ;
local L = OQ._T ; -- for literal string translations
if (OQ.table == nil) then
  OQ.table = {} ;
end
local tbl = OQ.table ;

local OQ_MAJOR                 = 1 ;
local OQ_MINOR                 = 6 ;
local OQ_REVISION              = 1 ;
local OQ_BUILD                 = 161 ;
local OQ_SPECIAL_TAG           = "" ;
local OQUEUE_VERSION           = tostring(OQ_MAJOR) ..".".. tostring(OQ_MINOR) ..".".. OQ_REVISION ;
local OQUEUE_VERSION_SHORT     = tostring(OQ_MAJOR) ..".".. tostring(OQ_MINOR) .."".. OQ_REVISION ;
local OQ_VERSION               = tostring(OQ_MAJOR) .."".. tostring(OQ_MINOR) .."".. tostring(OQ_REVISION) ;
local OQ_VER_STR               = OQUEUE_VERSION ;
local OQ_VER                   = "0Z"  ;  -- just removing the dot
local OQSK_VER                 = "0C"  ;  
local OQSK_HEADER              = "OQSK" ;
local OQ_NOTIFICATION_CYCLE    = 2 * 60 * 60 ; -- every 2 hrs
local OQ_VERSION_SWAP_TM       = 24 * 60 * 60 ;  -- daily check for toons that are OQ enabled
local OQ_ONEDAY                = 24 * 60 * 60 ; 
local OQ_MAX_RELAY_REALMS      = 5 ; 
local OQ_NOEMAIL               = "." ;
local OQ_OLDBNHEADER           = "[OQ] " ;
local OQ_BNHEADER_TAG          = "(OQ)" ;
local OQ_BNHEADER              = OQ_BNHEADER_TAG .." " ;
local OQ_SKHEADER              = "[SK] " ;
local OQ_HEADER                = "OQ" ;
local OQ_MSGHEADER             = OQ_HEADER .."," ;
local OQ_FLD_TO                = "#to:" ;
local OQ_FLD_FROM              = "#fr:" ;
local OQ_FLD_REALM             = "#rlm:" ;
local OQ_TTL                   = 5 ;
local OQ_PREMADE_STAT_LIFETIME = 5*60 ; -- 5 minutes
local OQ_GROUP_TIMEOUT         = 2*60 ; -- 2 minutes (matches raid-timeout) if no response will remove group 
local OQ_GROUP_RECOVERY_TM     = 5*60 ; -- 5 minutes 
local OQ_SEC_BETWEEN_ADS       = 25 ; 
local OQ_SEC_BETWEEN_PROMO     = 25 ;
local OQ_BOOKKEEPING_INTERVAL  = 10 ;
local OQ_BRIEF_INTERVAL        = 30 ;
local OQ_MAX_ATOKEN_LIFESPAN   = 120 ; -- 120 seconds before token removed from ATOKEN list
local OQ_MIN_ATOKEN_RELAY_TM   = 30 ; -- do not relay atokens more then once every 30 seconds
local OQ_MAX_SUBMIT_ATTEMPTS   = 20 ;
local OQ_MAX_WAITLIST          = 40 ;
local OQ_MIN_CONNECTION        = 20 ;
local OQ_MIN_BNET_CONNECTIONS  = 10 ;
local OQ_FINDMESH_CD           = 7 ; -- seconds
local OQ_CREATEPREMADE_CD      = 5 ; -- seconds
local OQ_BTAG_SUBMIT_INTERVAL  = 4*24*60*60 ;
local MAX_OQGENERAL_TALKERS    = 20 ;
local my_group                 = 0 ;
local my_slot                  = 0 ;
local next_bn_check            = 0 ;
local next_check               = 0 ;
local next_invite_tm           = 0 ;
local last_ident_tm            = 0 ;
local last_stats_tm            = 0 ;
local skip_stats               = 0 ;
local last_stats               = "" ;
local player_name              = nil ;
local player_class             = nil ;
local player_realm             = nil ;
local player_realm_id          = 0 ;
local player_realid            = nil ;
local player_faction           = nil ;
local player_level             = 1 ;
local player_ilevel            = 1 ;  
local player_resil             = 1 ;  
local player_role              = 3 ;
local player_deserter          = nil ;
local player_queued            = nil ;
local player_online            = 1 ;
local player_karma             = 0 ;
local _source                  = nil ; -- bnet, addon, bnfinvite, oqgeneral, party
local _sender_pid              = nil ;
local _msg_token               = nil ;
local _debug                   = nil ;
local _inc_channel             = nil ;
local _received                = nil ;
local _ok2relay                = 1 ;
local _ok2decline              = true ;
local _ok2accept               = true ;
local _local_msg               = nil ;
local _last_find_tm            = 0 ;
local _inside_bg               = nil ;
local _bg_shortname            = nil ;
local _bg_zone                 = nil ;
local _winner                  = nil ;
local _msg                     = nil ;
local _msg_type                = nil ;
local _msg_id                  = nil ;
local _oq_note                 = nil ;
local _oq_msg                  = nil ;
local _dest_realm              = nil ;
local _core_msg                = nil ;
local _to_name                 = nil ;
local _to_realm                = nil ;
local _from                    = nil ;
local _last_report             = nil ;
local _map_open                = nil ;
local _ui_open                 = nil ;
local _oqgeneral_id            = nil ;
local _oqgeneral_count         = 0 ;
local _oqgeneral_lockdown      = true ; -- restricted until unlocked once the # of members of oqgeneral are determined
local _f                       = {} ;
local _toon                    = {} ;
local _flags                   = nil ;
local _enemy                   = nil ;
local _nkbs                    = 0 ;
local _arg                     = {} ;
local _opts                    = {} ;
local _vars                    = {} ;
local _hop                     = 0 ;
local player_away              = nil ;
local oq_ascii                 = {} ;
local oq_mime64                = {} ;
local lead_ticker              = 0 ;
local OQ_MAX_BNFRIENDS         = 85 ;
OQ.BNET_CAPB4THECAP            = 100 ; -- blizz increased the cap from 100 to 112 (also fixed the crash.  capb4cap needed?).  
local _ ; -- throw away (was getting taint warning; what happened blizz?)

if (OQ_toon == nil) then 
  OQ_toon = { last_tm = 0,
              auto_role = 1,
              class_portrait = 1
            } ;
end
--[[ OQ_toon used to help save group information if disconnected, reloaded, or quickly logged out
  my_group = 0 ;
  my_slot = 0 ;
  last_tm = 0 ;  -- if within 1 minute from now, try to re-establish
  raid = {} ; -- copied from oq on_logout
]]

local oq = { my_tok = nil, ui = {}, channels = {}, premades = {}, raid = {}, waitlist = {}, pending = {} } ;
--[[
  raid = {
    name         = 'the raid'
    leader       = 'bigdk'
    leader_realm = 'magtheridon'
    leader_rid   = 'joebob@someaddress.com'
    level_range  = '80-84'
    faction      = 'H'
    min_ilevel   = 380 ;
    min_resil    = 3000 ;
    bgs          = 'IoC,AV,AB,EotS'
    notes        = 'nothing much here' 
    raid_token   = 'OQ10002xxx'
    type         = OQ.TYPE_BG (D dungeon, A rated bgs, B battlegrounds(def))
    group        = { 
      [1] = { status = 'queued'                                                       -- group[1].member[1] is always the raid leader
              member = { 
                [1] = { name = 'bigman', class = 'dk'   , realm = '', bgroup = '', realid = nil, level = 0, hp = 0, flags = 0, bg[1]{ type,status } }, -- member[1] is always the group leader
                [2] = { name = 'jack'  , class = 'rogue', realm = '', bgroup = '', realid = nil }, -- realid is nil all but the raid leader
              }
      },
    }
    channel = 'oq00010022'
    pword   = 'pw00050001'
  },

  pending_invites = {
         [ name-realm ] = { raid_tok = oq.raid.raid_token, gid = group_id, slot = slot_, rid = rid_ } 
  },

  premades = {
    [1] = { raid_token = '', name = '', leader = '', leader_rid = '', level_range = '', faction = '', min_ilevel = '', min_resil = '', bgs = '' },
  },
  
  -- non-nil only for raid leader
  waitlist = {
    [1] = { name = 'slash', class = 'pally', realm = '', realid = '', level = '84', ilevel = '390', resil = '4200', realid = '' },
    [2] = { name = 'hack' , class = 'rogue', realm = '', realid = '', level = '84', ilevel = '390', resil = '4200', realid = '' },
  },
]]
local dtp = oq ;
function OQ:mod()  return oq ; end

if (OQ_data == nil) then 
  OQ_data = {  
    bn_friends = {}, 
    autoaccept_mesh_request = 1,
    ok2submit_tag = 1,
  } ;
  OQ_data.stats = {
    nGames      = 0 ;
    nWins       = 0 ;
    nLosses     = 0 ;
    start_tm    = 0 ; -- time() when this raid was created
    bg_start    = 0 ; -- place holder - time() of bg start
    bg_end      = 0 ; -- place holder - time() of bg end
    tm          = 0 ; -- time of last update from source.  able to know which data is the latest
  } ;
end

--[[
  -- OQ enabled BN friends
  bn_friends = {
    [toonName-realm] = { presenceID, givenName, surName, toonName, realm, isOnline, oq_enabled } ;
  }
]]

-------------------------------------------------------------------------------
--   local defines
-------------------------------------------------------------------------------
oq.old_bncustommsg        = nil ;
oq.old_bn_msg             = nil ;

OQ.CHK_VLIST_TM     = 15 ;

OQ.FLAG_ONLINE      = 0x01 ;
OQ.FLAG_DESERTER    = 0x02 ;
OQ.FLAG_QUEUED      = 0x04 ;
OQ.FLAG_BRB         = 0x08 ;
OQ.FLAG_TANK        = 0x10 ;
OQ.FLAG_HEALER      = 0x20 ;

OQ.FLAG_CLEAR       = 0x00 ;
OQ.FLAG_READY       = 0x01 ;
OQ.FLAG_NOTREADY    = 0x02 ;
OQ.FLAG_WAITING     = 0x04 ;

OQ.FACTION_ICON = {} ;
OQ.FACTION_ICON["H"] = "|TInterface\\BattlefieldFrame\\Battleground-Horde.blp:20:20:0:0|t";
OQ.FACTION_ICON["A"] = "|TInterface\\BattlefieldFrame\\Battleground-Alliance.blp:20:20:0:0|t";

local OQ_LOCK          = "|TInterface\\BUTTONS\\UI-Button-KeyRing.blp:28:20:0:0:20:24:0:16:0:16|t";
local OQ_KEY           = "Interface\\BUTTONS\\UI-Button-KeyRing" ;

local OQ_STAR_ICON     = "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp:16:16:0:0:64:64:0:16:0:16|t";
local OQ_CIRCLE_ICON   = "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp:16:16:0:0:64:64:16:32:0:16|t";
local OQ_DIAMOND_ICON  = "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp:10:10:0:0:64:64:32:48:0:16|t";
local OQ_BIGDIAMOND_ICON  = "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp:16:16:0:0:64:64:32:48:0:16|t";
local OQ_TRIANGLE_ICON = "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp:16:16:0:0:64:64:48:64:0:16|t";
local OQ_LILTRIANGLE_ICON = "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp:8:8:0:0:64:64:48:64:0:16|t";

local OQ_MOON_ICON     = "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp:16:16:0:0:64:64:0:16:16:32|t";
local OQ_SQUARE_ICON   = "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp:16:16:0:0:64:64:16:32:16:32|t";
local OQ_REDX_ICON     = "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp:16:16:0:0:64:64:32:48:16:32|t";
local OQ_LILREDX_ICON  = "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp:8:8:0:0:64:64:32:48:16:32|t";
local OQ_SKULL_ICON    = "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp:16:16:0:0:64:64:48:64:16:32|t";
local OQ_LILSKULL_ICON = "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp:10:10:0:0:64:64:48:64:16:32|t";
local OQ_LILCIRCLE_ICON= "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp:8:8:0:0:64:64:16:32:0:16|t";

OQ.ICON_NONE        = 0 ;
OQ.ICON_STAR        = 1 ;
OQ.ICON_CIRCLE      = 2 ;
OQ.ICON_DIAMOND     = 3 ;
OQ.ICON_TRIANGLE    = 4 ;
OQ.ICON_MOON        = 5 ;
OQ.ICON_SQUARE      = 6 ;
OQ.ICON_REDX        = 7 ;
OQ.ICON_SKULL       = 8 ;

OQ.ICON_STRINGS = {
  [ OQ.ICON_NONE      ] = nil,
  [ OQ.ICON_STAR      ] = OQ_STAR_ICON,
  [ OQ.ICON_CIRCLE    ] = OQ_CIRCLE_ICON,
  [ OQ.ICON_DIAMOND   ] = OQ_DIAMOND_ICON,
  [ OQ.ICON_TRIANGLE  ] = OQ_TRIANGLE_ICON,
  [ OQ.ICON_MOON      ] = OQ_MOON_ICON,
  [ OQ.ICON_SQUARE    ] = OQ_SQUARE_ICON,
  [ OQ.ICON_REDX      ] = OQ_REDX_ICON,
  [ OQ.ICON_SKULL     ] = OQ_SKULL_ICON,
} ;

OQ.ICON_COORDS = {
  [ OQ.ICON_NONE      ] = { 0.00, 0.00, 0.00, 0.00 },
  [ OQ.ICON_STAR      ] = { 0.00, 0.25, 0.00, 0.25 },
  [ OQ.ICON_CIRCLE    ] = { 0.25, 0.50, 0.00, 0.25 },
  [ OQ.ICON_DIAMOND   ] = { 0.50, 0.75, 0.00, 0.25 },
  [ OQ.ICON_TRIANGLE  ] = { 0.75, 1.00, 0.00, 0.25 },
  [ OQ.ICON_MOON      ] = { 0.00, 0.25, 0.25, 0.50 },
  [ OQ.ICON_SQUARE    ] = { 0.25, 0.50, 0.25, 0.50 },
  [ OQ.ICON_REDX      ] = { 0.50, 0.75, 0.25, 0.50 },
  [ OQ.ICON_SKULL     ] = { 0.75, 1.00, 0.25, 0.50 },
} ;

-------------------------------------------------------------------------------
local OQ_versions = 
{ [ "1.5.0"    ] = 28,
  [ "1.5.1"    ] = 29,
  [ "1.5.2"    ] = 30,
  [ "1.5.3"    ] = 31,
  [ "1.5.4"    ] = 32,
  [ "1.5.5"    ] = 33,
  [ "1.5.6"    ] = 34,
  [ "1.5.7"    ] = 35,
  [ "1.5.8"    ] = 36,
  [ "1.5.9"    ] = 37,
  [ "1.6.0"    ] = 39,
  [ "1.6.1"    ] = 40,
  [ "1.6.2"    ] = 41,
  [ "1.6.3"    ] = 42,
  [ "1.6.4"    ] = 43,
  [ "1.6.5"    ] = 44,
  [ "1.6.6"    ] = 45,
  [ "1.6.7"    ] = 46,
  [ "1.6.8"    ] = 47,
  [ "1.6.9"    ] = 48,
  [ "1.7.0"    ] = 49,
  [ "1.8.0"    ] = 50,
  [ "1.8.1"    ] = 51,
  [ "1.8.2"    ] = 52,
  [ "1.8.3"    ] = 53,
  [ "1.8.4"    ] = 54,
  [ "1.8.5"    ] = 55,
  [ "1.8.6"    ] = 56,
  [ "1.8.7"    ] = 57,
  [ "1.8.8"    ] = 58,
  [ "1.8.9"    ] = 59,
  [ "1.9.0"    ] = 60,
  [ "1.9.1"    ] =  1,
} ;

function oq.get_version_id()
  return OQ_versions[OQ_VER_STR] or 0 ;
end

function oq.get_version_str( id )
  if (id == 0) then
    return "" ;
  end
  for i,v in pairs(OQ_versions) do
    if (v == id) then
      return i ;
    end
  end
  return "" ;
end
-------------------------------------------------------------------------------
--   slash commands
-------------------------------------------------------------------------------

SLASH_OQUEUE1 = '/oqueue' ;
SLASH_OQUEUE2 = '/oq' ;
SlashCmdList["OQUEUE"] = function (msg, editbox)
  if (msg == nil) or (msg == "") then
    oq.ui_toggle() ;
    return ;
  end
  local arg1 = msg ;
  local opts = nil ;
  if (msg ~= nil) and (msg:find(" ") ~= nil) then
    arg1 = msg:sub(1,msg:find(" ")-1) ;
    opts = msg:sub(msg:find(" ")+1,-1) ;
  end
  if (oq.options[ arg1 ] ~= nil) then
    oq.options[ arg1 ]( opts ) ;
  end
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
oq.options = {} ;
function oq.hook_options()
  oq.options[ "?"           ] = oq.usage ; 
  oq.options[ "adds"        ] = oq.show_adds ;
  oq.options[ "ban"         ] = oq.ban_user ;
  oq.options[ "bnclear"     ] = oq.bn_clear ; 
  oq.options[ "check"       ] = oq.bn_force_verify ;
  oq.options[ "cp"          ] = oq.toggle_class_portraits ;
  oq.options[ "debug"       ] = oq.debug_toggle ;
  oq.options[ "dg"          ] = oq.leave_party ;  -- drop group
  oq.options[ "dp"          ] = oq.leave_party ;  -- drop party
  oq.options[ "fixui"       ] = oq.reposition_ui ;  
  oq.options[ "godark"      ] = oq.godark ;
  oq.options[ "harddrop"    ] = oq.harddrop ; 
  oq.options[ "help"        ] = oq.usage ; 
  oq.options[ "lust"        ] = oq.last_lust ;   
  oq.options[ "mbsync"      ] = oq.mbsync ;
  oq.options[ "mycrew"      ] = oq.mycrew ;
  oq.options[ "mini"        ] = oq.toggle_mini ;
  oq.options[ "now"         ] = oq.show_now ;
  oq.options[ "pnow"        ] = oq.show_now2party ;
  oq.options[ "partynow"    ] = oq.show_now2party ;
  oq.options[ "off"         ] = oq.oq_off ;
  oq.options[ "on"          ] = oq.oq_on ;
  oq.options[ "pending"     ] = oq.bn_show_pending ;
  oq.options[ "ping"        ] = oq.ping_toon ;
  oq.options[ "purge"       ] = oq.remove_OQadded_bn_friends ;
  oq.options[ "rage"        ] = oq.report_rage ;
  oq.options[ "rc"          ] = oq.start_role_check ;
  oq.options[ "refresh"     ] = oq.raid_find ;
  oq.options[ "reset"       ] = oq.data_reset ;
  oq.options[ "show"        ] = oq.show_data ;
  oq.options[ "spy"         ] = oq.battleground_spy ;
  oq.options[ "stats"       ] = oq.dump_statistics ;
  oq.options[ "threat"      ] = oq.toggle_threat_level ;  
  oq.options[ "thx"         ] = oq.special_thanks ;  
  oq.options[ "time"        ] = oq.force_time_reset ;  
  oq.options[ "timer"       ] = oq.user_timer ;  
  oq.options[ "toggle"      ] = oq.toggle_option ;  
  oq.options[ "version"     ] = oq.show_version ;
  oq.options[ "-v"          ] = oq.show_version ;
  oq.options[ "wallet"      ] = oq.show_wallet ;
  oq.options[ "who"         ] = oq.show_bn_enabled ;
  
  oq.options[ "kk"          ] = function()
oq.req_karma("player") ;
  end
  
end


function oq.toggle_mini()
  if (OQ_MinimapButton:IsVisible()) then
    OQ_MinimapButton:Hide() ;
    OQ_toon.mini_hide = true ;
    print( OQ.MINIMAP_HIDDEN ) ;
  else
    OQ_MinimapButton:Show() ;
    OQ_toon.mini_hide = nil ;
    print( OQ.MINIMAP_SHOWN ) ;
  end
end

function oq.reposition_ui()
  x = 500 ;  
  -- main ui
  local f = OQMainFrame ;
  if (not f:IsVisible()) then
    oq.ui_toggle() ;
  end  
  f:SetWidth( 800 ) ;
  f:SetHeight( 425 ) ;
  f:SetPoint("TOPLEFT", UIParent,"TOPLEFT", x, -150 ) ;
   
  -- toggle minimap button so it's on top
  OQ_MinimapButton:Show() ;
  OQ_MinimapButton:SetFrameStrata( "MEDIUM" ) ;
  OQ_MinimapButton:SetFrameLevel(50) ;

end

function oq.show_count()
  local p = nil ;
  local nLeaders = 0 ;
  local nWaiting = 0 ;
  local nMembers = 0 ;
  for i,v in pairs(oq.premades) do
    nLeaders = nLeaders + 1 ;
    nMembers = nMembers + v.stats.nMembers ;
    nWaiting = nWaiting + v.stats.nWaiting ;
  end
  print( "nLeaders: ".. tostring(nLeaders) ) ;
  print( "nMembers: ".. tostring(nMembers) ) ;
  print( "nWaiting: ".. tostring(nWaiting) ) ;
end

function oq.show_data( opt )
  if (opt == nil) or (opt == "?") then
    print( "oQueue v".. OQUEUE_VERSION .."  build ".. OQ_BUILD .." (".. tostring(OQ.REGION) ..")" ) ;
    print( " usage:  /oq show <option>" ) ;
    print( "   remove       list all the battle-tags that will be removed with 'remove now'" ) ;
    print( "   report       show battleground reports yet to be filed" ) ;
    print( "   stats        list various stats" ) ;
  elseif (opt == "remove") then
    oq.remove_OQadded_bn_friends( "show" ) ;
  elseif (opt == "btags") then
    oq.show_btags() ;
  elseif (opt == "count") then
    oq.show_count() ;
  elseif (opt == "raid") then
    oq.show_raid() ;
  elseif (opt == "stats") then
    oq.dump_statistics() ;
  elseif (opt == "frames") then
    oq.frame_report() ;  
  end
end

function oq.toggle_option( opt )
  if (opt == nil) or (opt == "?") then
    print( "oQueue v".. OQUEUE_VERSION .."  build ".. OQ_BUILD .." (".. tostring(OQ.REGION) ..")" ) ;
    print( " usage:  /oq toggle <option>" ) ;
    print( "   mini         toggle the minimap icon" ) ;    
  elseif (opt == "mini") then 
    oq.toggle_mini() ;
  end  
end

function oq.harddrop()
  oq.raid_init() ;
end

function oq.leave_party()
  oq._last_raid_token = oq.raid.raid_token ;
  if (oq.iam_raid_leader()) then
    oq.raid_disband() ;
  else
    LeaveParty() ;
    oq.raid_init() ;
  end
  oq.raid_cleanup() ;
end

function oq.ban_user( tag )
  if (tag == nil) then
    return ;
  end
  local dialog = StaticPopup_Show("OQ_BanUser", tag ) ;
  if (dialog ~= nil) then
    dialog.data2 = { flag = 3, btag = tag } ;
  end
end

function oq.usage()
  print( "oQueue v".. OQUEUE_VERSION .."  build ".. OQ_BUILD .." (".. tostring(OQ.REGION) ..")" ) ;
  print( L["usage:  /oq [command]"] ) ;
  print( L["command such as:"] ) ;
  print( L["  adds            show the list of OQ added b.net friends"] ) ;
  print( L["  ban [b-tag]     manually add battle-tag to your ban list"] ) ;
  print( L["  bnclear         clear OQ enabled battle-net associations"] ) ;
  print( L["  check           force OQ capability check"] ) ;
  print( L["  cp              toggle class portraits to normal portrait"] ) ;
  print( L["  dg              drop group.  same as /script LeaveParty()"] ) ;
  print( L["  fixui           will reposition the UI to upper left area"] ) ;
  print( L["  godark          send 'oq stop' to all your OQ enabled friends"] ) ;
  print( L["  id              show guid, id, and name of target"] ) ;
  print( L["  log [clear]     toggle log on/off or clear"] ) ;
  print( L["  lust            re-display the last lust message"] ) ;
  print( L["  mini            toggle the minimap button"] ) ;
  print( L["  mycrew [clear]  for boxers, populate the alt list"] ) ;
  print( L["  now             print the current utc time (only visible to user)"] ) ;
  print( L["  off             turn off OQ messaging"] ) ;
  print( L["  on              turn on OQ messaging"] ) ;
  print( L["  pnow            print the current utc time to party chat"] ) ;
  print( L["  pos             print your current locaiton in the world"] ) ;
  print( L["  purge           purge friends list of OQ added b.net friends"] ) ;
  print( L["  rc              start role check (OQ premade leader only)"] ) ;
  print( L["  refresh         sends out a request to refresh find-premade list"] ) ;
  print( L["  show <opt>      show various information"] ) ;
  print( L["  stats           various statistics about the player"] ) ;
  print( L["  spy [on|off]    display summary of enemy class types"] ) ;
  print( L["  toggle <opt>    toggle specific option"] ) ;
  print( L["  who             list of OQ enabled battle-net friends"] ) ;    
end

function oq.data_reset()
    oq = { my_tok = nil, ui = {}, channels = {}, premades = {}, raid = {}, waitlist = {} } ;
    OQ_data = { bn_friends = {} } ;
    oq.init_stats_data() ;
    OQ_toon = { last_tm = 0,
                auto_role = 1,
                class_portrait = 1,
                reports = {},
              } ;
    print( "oQueue data reset.  for it to take effect, type /reload" ) ;
end

function oq.debug_toggle( level )
  if (level) then
    if (level == "off") then 
      _debug = nil ; 
      print( "debug off" ) ;
    elseif (level == "on") then
      _debug = true ; 
      print( "debug on" ) ;
    elseif (tonumber(level)) then
      oq._debug_level = tonumber(level) ;
      print( "debug level: ".. tostring(oq._debug_level) ) ;
    end
  else
    if (_debug) then
      _debug = nil ; 
      print( "debug off" ) ;
    else
      _debug = true ; 
      print( "debug on" ) ;
    end
  end
end

function oq.godark()
  -- clear out bn friends
  oq.bn_clear() ;
  -- turn it off
  oq.oq_off() ;
  -- update OQ friends count
  oq.n_connections() ;
end

function oq.oq_off() 
  OQ_toon.disabled = true ;
  oq.reset_bn_custom_msg() ;
  print( OQ.DISABLED ) ;
end

function oq.oq_on() 
  OQ_toon.disabled = nil ;
  oq.init_bn_custom_msg() ;
  print( OQ.ENABLED ) ;
end

function oq.GetNumPartyMembers()
  return GetNumGroupMembers() ;
end

function oq.mycrew( arg )
  -- use the current raid/party to poulate the OQ_data.my_toons
  if (arg == "clear") then
    oq.clear_alt_list() ;
    return ;
  end
  if (not UnitInParty("player")) then
    return ;
  end
  oq.clear_alt_list() ;
  local n = GetNumGroupMembers() ;
  if (n > 0) then
    for i=1,n do
      local name = select( 1, GetRaidRosterInfo(i) ) ;
      oq.add_toon( name ) ;
    end
  else
    n = oq.GetNumPartyMembers() ;
    oq.add_toon( player_name ) ;
    for i=1,n do
      local name = GetUnitName( "party".. i ) ;
      oq.add_toon( name ) ;
    end
  end
end

function oq.timezone_reset()
  oq.__date1 = nil ;
  oq.__date2 = nil ;
end

function oq.force_time_reset() 
  print( "OQ: forcing timezone reset" ) ;
  oq.timezone_reset() ;
  oq.show_now() ;
end

local function utc_time( arg )
  if (arg == nil) then
    local now = time() ;
    if (oq.__date1 == nil) then
      oq.__date1 = date("!*t") ;
      oq.__date2 = date("!*t", now) ;
    end
    return time( oq.__date1 ) + difftime(now, time( oq.__date2 )) - (OQ_data.sk_adjust or 0) ;
    --
    -- date("!*t") leaks a table after every call.  to avoid, only call once
    -- this will cause a problem for those ppl with incorrect set timezones.
    -- whereas they will automatically pick up the timezone change now, this
    -- will force them to tell oq to re-calc the tables
    --
    --    return time(date("!*t")) + difftime(now, time(date("!*t", now) )) ;
  elseif (arg == "pure") then
    local now = time() ;
    if (oq.__date1 == nil) then
      oq.__date1 = date("!*t") ;
      oq.__date2 = date("!*t", now) ;
    end
    return time( oq.__date1 ) + difftime(now, time( oq.__date2 )) ;
  else
    return time(date("!*t")) ;
  end
end

function oq.reset_portrait( f, player, show_default )
  if (f == nil) or (f.portrait == nil) then
    return ;
  end
  if (show_default) then
    SetPortraitTexture( f.portrait, player ) ;
    f.portrait:SetTexCoord(0,1,0,1) ;
  else
    OQ_ClassPortrait( f ) ;
  end
end

function oq.toggle_class_portraits()
  if (OQ_toon.class_portrait == 1) then
    OQ_toon.class_portrait = 0 ;
  else
    OQ_toon.class_portrait = 1 ;
  end
  oq.reset_portrait( PlayerFrame      , "player", (OQ_toon.class_portrait == 0) ) ;
  oq.reset_portrait( TargetFrame      , "target", (OQ_toon.class_portrait == 0) ) ;
  oq.reset_portrait( PartyMemberFrame1, "party1", (OQ_toon.class_portrait == 0) ) ;
  oq.reset_portrait( PartyMemberFrame2, "party2", (OQ_toon.class_portrait == 0) ) ;
  oq.reset_portrait( PartyMemberFrame3, "party3", (OQ_toon.class_portrait == 0) ) ;
  oq.reset_portrait( PartyMemberFrame4, "party4", (OQ_toon.class_portrait == 0) ) ;
  oq.reset_portrait( PartyMemberFrame5, "party5", (OQ_toon.class_portrait == 0) ) ;
end

function oq.render_tm( dt )
  dt = abs(dt) ;
  if (dt >= 0) then
    local dsec, dmin, dhr, ddays, dyrs, dstr ;
    ddays = floor(dt / (24*60*60)) ;
    dt = dt % (24*60*60) ;
    dyrs = floor( ddays / 365 ) ;
    ddays = ddays % 365 ;
    dhr = floor(dt / (60*60)) ;
    dt = dt % (60*60) ;
    dmin = floor(dt / 60) ;
    dt = dt % 60 ;
    dsec = dt ;
    dstr = "" ;
    if (dyrs > 0) then
      dstr = dyrs .."y ".. ddays .."d ".. string.format("%02d:%02d:%02d", dhr, dmin, dsec ) ;
    elseif (ddays > 0) then
      dstr = ddays .."d ".. string.format("%02d:%02d:%02d", dhr, dmin, dsec ) ;
    elseif (dhr > 0) then
      dstr = string.format("%02d:%02d:%02d", dhr, dmin, dsec ) ;
    elseif (dmin > 0) then
      dstr = string.format("%02d:%02d", dmin, dsec ) ;
    else
      dstr = string.format("00:%02d", dsec ) ;
    end
    return dstr ;
  else
    return "xx:xx" ;
  end
end

function oq.show_now( arg )
  local now = utc_time( arg ) ;
  local msg = string.format( OQ.THETIMEIS, now ) ;
  print( string.format( OQ.THETIMEIS, now ) .."  ".. date("!%H:%M %d %b %Y UTC", now ) ) ;
  
  local dt = abs(OQ_data.sk_adjust or 0) ;
  if (dt > 0) or true then
    local dsec, dmin, dhr, ddays, dyrs, dstr ;
    ddays = floor(dt / (24*60*60)) ;
    dt = dt % (24*60*60) ;
    dyrs = floor( ddays / 365 ) ;
    ddays = ddays % 365 ;
    dhr = floor(dt / (60*60)) ;
    dt = dt % (60*60) ;
    dmin = floor(dt / 60) ;
    dt = dt % 60 ;
    dsec = dt ;
    dstr = "local time varies from scorekeeper by: " ;
    if (dyrs > 0) then
      dstr = dstr .." ".. dyrs .." yrs ".. ddays .." days ".. dhr ..":".. dmin ..":".. dsec ;
    elseif (ddays > 0) then
      dstr = dstr .." ".. ddays .." days ".. dhr ..":".. dmin ..":".. dsec ;
    elseif (dhr > 0) then
      dstr = dstr .." ".. dhr ..":".. dmin ..":".. dsec .." hours" ;
    elseif (dmin > 0) then
      dstr = dstr .." ".. dmin ..":".. dsec .." minutes" ;
    else
      dstr = dstr .." ".. dsec .." seconds" ;
    end
    print( dstr ) ;
  end
end

function oq.show_now2party( arg )
  local msg = string.format( OQ.THETIMEIS, utc_time( arg )) ;
  SendChatMessage( msg, "PARTY", nil ) ;  
end
-------------------------------------------------------------------------------
-- token functions
-------------------------------------------------------------------------------
local OQ_atoken = {} ;
function oq.atok_last_seen( token )
  if (token == nil) or (OQ_atoken[ token ] == nil) then
    return 0 ;
  end
  return OQ_atoken[ token ] ;
end

function oq.atok_seen( token )
  if (token ~= nil) then
    OQ_atoken[ token ] = utc_time() ;
  end
end

-- will register token as seen if ok to process
--
function oq.atok_ok2process( token )
  local last_seen = oq.atok_last_seen( token ) ;
  local now = utc_time() ;
  if ((now - last_seen) > OQ_MIN_ATOKEN_RELAY_TM) then
    oq.atok_seen( now ) ;
    return true ;
  end
end

function oq.atok_clear_old()
  local now = utc_time() ;
  for i,v in pairs(OQ_atoken) do
    if ((now - v) > OQ_MAX_ATOKEN_LIFESPAN) then
      OQ_atoken[i] = nil ;
    end
  end
end

function oq.atok_clear()
  tbl.clear( OQ_atoken ) ;
end

function oq.token_gen()
--[[
  local tm = floor( GetTime() * 1000 ) ;
  local r = random( 0, 10000 ) ;
  local token = (tm % 100000) * 10000 + r ;
  return oq.encode_mime64_5digit(token) ;
]]--
  return oq.encode_mime64_5digit( utc_time() * 10000 + random( 0, 10000 )) ;
end

function oq.is_my_token( t )
  if (OQ_data.my_tokens[t]) and (OQ_data.my_tokens[t] > utc_time()) then
    return true ;
  end
  return nil ;
end

function oq.store_my_token( t )
  if (t == nil) then
    return ;
  end
  OQ_data.my_tokens[t] = utc_time() + 8*60*60 ; -- expires in 8 hrs
end

function oq.clear_old_tokens()
  if (OQ_data.my_tokens == nil) then
    OQ_data.my_tokens = {} ;
  end
  local now = utc_time() ;
  for i,v in pairs(OQ_data.my_tokens) do
    if (v < now) then
      OQ_data.my_tokens[i] = nil ;
    end
  end
end

local OQ_recent_tokens = {} ;
local OQ_recent_keys = {} ;
local OQ_tok_cnt = 0 ;
function oq.token_list_init()
  for i=1,500 do
    OQ_recent_tokens[i] = i ;
    OQ_recent_keys[i] = i ;
  end
  OQ_tok_cnt = 501 ;
end

function oq.token_was_seen( token )
  return (OQ_recent_keys[ token ] ~= nil) ;
end

--
--  remove one from the front, push one to the back
--
function oq.token_push( token_ )
  local key = table.remove( OQ_recent_tokens, 1 ) ;
  if (OQ_recent_keys == nil) then
    OQ_recent_keys = tbl.new() ;
  end
  if (OQ_recent_tokens == nil) then
    OQ_recent_tokens = tbl.new() ;
  end
  if (key ~= nil) then
    OQ_recent_keys[ key ] = nil ;
  end

  OQ_tok_cnt = OQ_tok_cnt + 1 ;
  OQ_recent_tokens[ OQ_tok_cnt ] = token_ ;
  OQ_recent_keys  [ token_     ] = OQ_tok_cnt ;
end

-------------------------------------------------------------------------------
--   
-------------------------------------------------------------------------------
function oq.tremove_value( t, val )
  for i,v in pairs(t) do
    if (v == val) then
      tremove( t, i ) ;
      return ;
    end
  end
end

-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
local function tprint_col (tbl, indent, key )
   if not indent then indent = 0 end
   local ln = string.rep(" ", indent) ;
   for k, v in pairs(tbl) do
      if type(v) == "table" then
         formatting = string.rep(" ", indent) ;
         tprint_col(v, indent+1, k)
      elseif (k ~= "leader_rid") then
         ln = ln .." ".. k ..": ".. tostring(v) ;
      end
   end
   if (key ~= nil) then
      print( tostring(key) ..": ".. ln ) ;
   else
      print( ln ) ;
   end
end

function oq.n_rows(t)
  local n = 0 ;
  for i,v in pairs(t) do
    n = n + 1 ;
  end
  return n ;
end

function oq.n_premades()
  local nShown, nPremades = 0, 0 ;
  if (oq.tab2_raids ~= nil) then
    for n,v in pairs(oq.tab2_raids) do 
      local p = oq.premades[ v.token ] ;
      if (p ~= nil) then
        if (v._isvis) then
          nShown = nShown + 1 ;
        end
        nPremades = nPremades + 1 ;
      end
    end
  end
  return nShown, nPremades ;
end

function oq.dump_statistics()
  oq.req_karma("player") ;
  oq.gather_my_stats() ;
  
  print( "oQueue premade stats" ) ;
  print( "---" ) ;
  print( " leader stats" ) ;
  print( " -  regular bg   : ".. tostring(OQ_data.leader["bg"].nWins or 0) .." - ".. tostring(OQ_data.leader["bg"].nLosses or 0) .." over ".. tostring(OQ_data.leader["bg"].nGames or 0) .." games" ) ;
  print( " -  rated bg     : ".. tostring(OQ_data.leader["rbg"].nWins or 0) .." - ".. tostring(OQ_data.leader["rbg"].nLosses or 0) .." over ".. tostring(OQ_data.leader["rbg"].nGames or 0) .." games" ) ;
  print( " -  5Mans        : ".. tostring(OQ_data.leader["pve.5man"].nBosses) .." - ".. tostring(OQ_data.leader["pve.5man"].nWipes) .."  pts: ".. tostring(OQ_data.leader["pve.5man"].pts) ) ;
  print( " -  raids        : ".. tostring(OQ_data.leader["pve.raid"].nBosses) .." - ".. tostring(OQ_data.leader["pve.raid"].nWipes) .."  pts: ".. tostring(OQ_data.leader["pve.raid"].pts) ) ;
  print( " -  challenges   : ".. tostring(OQ_data.leader["pve.challenge"].nBosses) .." - ".. tostring(OQ_data.leader["pve.challenge"].nWipes) .."  pts: ".. tostring(OQ_data.leader["pve.challenge"].pts) ) ;
  print( " -  scenarios    : ".. tostring(OQ_data.leader["pve.scenario"].nBosses) .." - ".. tostring(OQ_data.leader["pve.scenario"].nWipes) .."  pts: ".. tostring(OQ_data.leader["pve.scenario"].pts) ) ;
  
  print( "  my win-loss      : " ) ;
  print( " -  regular bg     : ".. tostring(OQ_toon.stats["bg"].nWins or 0) .." - ".. tostring(OQ_toon.stats["bg"].nLosses or 0) .." over ".. tostring(OQ_toon.stats["bg"].nGames or 0) .." games") ;
  print( " -  rated bg       : ".. tostring(OQ_toon.stats["rbg"].nWins or 0) .." - ".. tostring(OQ_toon.stats["rbg"].nLosses or 0) .." over ".. tostring(OQ_toon.stats["rbg"].nGames or 0) .." games" ) ;
  
  print( "  my_region        : ".. tostring(OQ.REGION) ) ;
  print( "  my_realmlist     : ".. tostring(GetCVar("realmlist")) ) ;
  print( "  my_realm         : ".. tostring(player_realm)  .." (".. tostring(oq.realm_cooked(player_realm)) ..")" ) ;
  if (player_realid == nil) then
    print( "  my_btag          : ".. OQ_LILREDX_ICON .." |cFFFF8080no battle-tag assigned|r" ) ;
  else
    print( "  my_btag          : ".. tostring( player_realid ) ) ;
  end
  print( "  my_karma         : ".. tostring( player_karma ) ) ;
  print( "  my_role          : ".. tostring( OQ.ROLES[player_role] ) ) ;
  print( "  my_ilevel        : ".. oq.get_ilevel() ) ;
  print( "  my_rbg_rating    : ".. oq.get_mmr() ) ;
  print( "  my_2s_rating     : ".. oq.get_arena_rating(1) ) ;
  print( "  my_3s_rating     : ".. oq.get_arena_rating(2) ) ;
  print( "  my_5s_rating     : ".. oq.get_arena_rating(3) ) ;
  print( "  my_resil         : ".. oq.get_resil() ) ;
  print( "  my_timevariance  : ".. tostring( OQ_data.sk_adjust or 0 ) .." seconds" ) ;
  print( "  my_next_timechk  : ".. oq.render_tm( (OQ_data.sk_next_update or 0) - utc_time("pure") )) ;
  if (oq.raid.raid_token == nil) then
    print( "  my_group:  not in an OQ premade" ) ;
  else
    print( "  my_group: ".. tostring( oq.raid.type ) ..".".. tostring( oq.raid.raid_token ) .." . ".. tostring( my_group ) .." . ".. tostring( my_slot ) .."  ".. tostring(oq.raid.leader) .."-".. tostring(oq.raid.leader_realm) ) ;
    if (oq.iam_related_to_boss()) then
      print( "    --  i am related to the boss" ) ;
    end
  end
  if (_inside_bg) then
    print( " inside bg       : yes   [".. tostring(_bg_zone) ..". ".. tostring(_bg_shortname) .."]" ) ;
  else
    print( " inside bg       : no" ) ;
  end
  if (OQ_toon.disabled) then
    print( "  OQ messaging is DISABLED" ) ;
  else
    print( "  OQ messaging is ENABLED" ) ;
  end
  local nShown, nPremades = oq.n_premades() ;
  print( "  # of premades        : ".. nShown .." / ".. nPremades ) ;
  print( "  # of BN friends      : ".. select( 1, BNGetNumFriends() ) ) ;
  print( "  packets recv         : ".. oq.pkt_recv._cnt .." (".. string.format( "%5.3f", oq.pkt_recv._aps ) .." per sec)" ) ;
  print( "  packets processed    : ".. oq.pkt_processed._cnt .." (".. string.format( "%5.3f", oq.pkt_processed._aps ) .." per sec)" ) ;
  print( "  packets sent         : ".. oq.pkt_sent._cnt .." (".. string.format( "%5.3f", oq.pkt_sent._aps ) .." per sec)  ".. #oq.send_q .." q'd" ) ;
  print( "" ) ;
  
  if (_oqgeneral_lockdown) then
    if (_oqgeneral_count > 0) then
      print( "  oqgeneral #: ".. _oqgeneral_count .."   channel over capacity.  restricted" ) ;
    else
      print( "  oqgeneral #: ".. _oqgeneral_count .."   restricted" ) ;
    end
  else
    if (_oqgeneral_count > MAX_OQGENERAL_TALKERS) then
      print( "  oqgeneral #: ".. _oqgeneral_count .."   channel over capacity.  no restrictions" ) ;
    else
      print( "  oqgeneral #: ".. _oqgeneral_count .."   no restrictions" ) ;
    end
  end
  print( "---" ) ;
end

function oq.show_member(m)
  print( "-- [".. tostring(m.name) .."][".. tostring(m.realm) .."]" ) ;
end

function oq.show_adds()
  local ntotal, nonline = BNGetNumFriends() ;
  local cnt = 0 ;
  print( "---  OQ added friends" ) ;
  for friendId=1,ntotal do
    local f = { BNGetFriendInfo( friendId ) } ;
    local presenceID = f[1] ;
    local givenName  = f[2] ;
    local btag       = f[3] ;
    local client     = f[7] ;
    local online     = f[8] ;
    local noteText   = f[13] ;
    if (noteText ~= nil) and ((noteText:find( "OQ," ) == 1) or (noteText:find( "REMOVE OQ" ) == 1)) then
      print( presenceID ..".  ".. givenName .." ".. btag .."   [".. noteText .."]" ) ;
      cnt = cnt + 1 ;
    elseif ((noteText == nil) or (noteText == "")) and oq.in_btag_cache( tag ) then
      print( presenceID ..".  ".. givenName .." ".. btag .."   [".. noteText .."]" ) ;
      cnt = cnt + 1 ;
    end
  end  
  print( "---  total :  ".. cnt ) ;
end

function oq.show_bn_enabled() 
  local cnt = 0 ;

  oq.bn_force_verify() ;
  print( "--[ OQ enabled ]--" ) ;
  for i,v in pairs(OQ_data.bn_friends) do
    if (v.isOnline and (v.oq_enabled or v.sk_enabled)) then
      print( tostring(v.presenceID) ..".  ".. tostring(v.toonName) .."-".. tostring(v.realm) ) ;
      cnt = cnt + 1 ;
    end
  end
  print( cnt .." bn friends OQ enabled" ) ;
  print( tostring( oq.n_channel_members( "OQgeneral" ) ) .." OQ enabled locals" ) ;
  
  oq.n_connections() ;  
end

function oq.raid_init()
  oq.raid = tbl.new() ;
  oq.raid.group = tbl.new() ;
  for i = 1,8 do
    oq.raid.group[i] = tbl.new() ;
    oq.raid.group[i].member = tbl.new() ;
    for j=1,5 do
      oq.raid.group[i].member[j] = tbl.new() ;
      oq.raid.group[i].member[j].flags = 0 ;
      oq.raid.group[i].member[j].bg = tbl.new() ;
      oq.raid.group[i].member[j].bg[1] = tbl.new() ;
      oq.raid.group[i].member[j].bg[2] = tbl.new() ;
    end
  end
  oq.raid.raid_token = nil ;
  oq.raid.type = OQ.TYPE_BG ;
  oq.waitlist  = tbl.new() ;
  oq.pending   = tbl.new() ;
  my_group     = 0 ;
  my_slot      = 0 ;
  
  oq.procs_no_raid() ;
end

function oq.channel_isregistered( chan_name )
  local n = strlower( chan_name ) ;
  return (oq.channels[ n ]) ;
end

function oq.buildChannelList(...)
   local tbl = {}
   for i = 1, select("#", ...), 2 do
      local id, name = select(i, ...)
      tbl[id] = strlower(name)
   end
   return tbl
end

function oq.channel_join( chan_name, pword )
  local n = strlower( chan_name ) ;

  JoinTemporaryChannel( n, pword ) ;
  local id, chname = GetChannelName( n ) ;

  oq.channels[ n ]       = {} ;
  oq.channels[ n ].id    = id ;
  oq.channels[ n ].pword = pword ;
end

function oq.hook_roster_update(chan_name)
  local n = strlower( chan_name ) ;
  local nchannels = GetNumDisplayChannels() ;
  for i=1,nchannels do
    local name, header, collapsed, channelNumber, count, active, category, 
          voiceEnabled, voiceActive = GetChannelDisplayInfo(i) ;
    if (name ~= nil) and (strlower(name) == n) then
      _oqgeneral_id = i ;
      SetSelectedDisplayChannel( _oqgeneral_id ) ;
      return true ;
    end
  end
end

local _names = {} ;
function oq.check_oqgeneral_lockdown()
  local n, index = oq.n_channel_members( "oqgeneral" ) ;
  _oqgeneral_count = n ;
  if (n < MAX_OQGENERAL_TALKERS) or (n == 0) then
    -- no restrictions
    _oqgeneral_lockdown = (n == 0) ;
    return ;
  end
   
  local old_chan_ndx = GetSelectedDisplayChannel() ;
  SetSelectedDisplayChannel( index ) ;
  --  local index = GetSelectedDisplayChannel()
  local count = select(5, GetChannelDisplayInfo(index))
  local activeCount = 0
  tbl.clear( _names ) ;
  for i=1,count do
    local n = select(1, GetChannelRosterInfo(index, i))
    if n then
      table.insert(_names, n) ;
    end
  end
  -- sort
  table.sort( _names ) ;
  -- determine player position in list
  count = 0 ;
  for i,v in pairs(_names) do
    count = count + 1 ;
    if (v == player_name) or (count > MAX_OQGENERAL_TALKERS) then
      _oqgeneral_lockdown = (count > MAX_OQGENERAL_TALKERS) ;
      break ;
    end
  end
   -- if position > max talkers, lockdown
  SetSelectedDisplayChannel( old_chan_ndx ) ;
end

function oq.n_channel_members( chan_name )
  local n = strlower( chan_name ) ;  
  local nchannels = GetNumDisplayChannels() ;
  for i=1,nchannels do
    local name, header, collapsed, channelNumber, count, active, category, voiceEnabled, voiceActive = GetChannelDisplayInfo(i) ;
      
    if (name ~= nil) and (n == strlower(name)) then
      return count or 0, i ;
    end
  end
  return 0, 0 ;
end

function oq.channel_leave( chan_name )
  local n = strlower( chan_name ) ;
  LeaveChannelByName( n ) ;
  oq.channels[ n ] = nil ;
end

function oq.channel_say( chan_name, msg )
  local n = strlower( chan_name ) ;
  if ((n ~= nil) and (oq.channels[n] ~= nil)) then
    SendChatMessage( msg, "CHANNEL", nil, oq.channels[ n ].id ) ;
    oq.pkt_sent:inc() ;
  end
end

function oq.join_oq_general()
  if (oq._banned) or (OQ_data.auto_join_oqgeneral == 0) then
    return ;
  end
  oq.channel_join( "OQGeneral" ) ;
end

function oq.oqgeneral_join()
  if (oq._banned) or (OQ_data.auto_join_oqgeneral == 0) then
    return ;
  end
  oq.channel_join( "OQGeneral" ) ;
  oq.timer( "hook_roster_update"   ,  5, oq.hook_roster_update      , true, "OQGeneral" ) ; -- will repeat until channel joined
  oq.timer( "chk_OQGeneralLockdown", 30, oq.check_oqgeneral_lockdown, true ) ; -- will check capacity every 30 seconds
end

function oq.oqgeneral_leave()
  _oqgeneral_lockdown = true ; -- lock the door.  the restriction will life once joined and cleared
  oq.channel_leave( "OQGeneral" ) ;
  oq.timer( "chk_OQGeneralLockdown", 0, nil ) ;
end

function oq.channel_general( msg ) 
  if (_oqgeneral_lockdown) then
    return ; -- too many ppl in oqgeneral, voluntary mute engaged
  end
  oq.channel_say( "OQGeneral", msg ) ;
end

function oq.iam_in_a_party()
  if (GetNumGroupMembers() > 0) then
    return true ;
  end
  return nil ;
end

function oq.is_oqueue_msg( msg )
  if (msg:sub(1,#OQ_MSGHEADER) == OQ_MSGHEADER) or 
     (msg:sub(1,#OQSK_HEADER) == OQSK_HEADER) then
     return true ;
  end
  return nil ;
end

function oq.BNSendFriendInvite( id, msg, note, name_, realm_ )
  if (id == nil) or (id == player_realid) or (id == "") then
    return ;
  end
  local pid, is_online = oq.is_bnfriend( id, name_, realm_ ) ;
  if (pid ~= nil) then
    return ; -- already friended
  end
  if (msg ~= nil) and (#msg > 127) then
    msg = msg:sub(1,127) ;
  end
  BNSendFriendInvite( id, msg ) ;
  oq.cache_btag( id, note ) ;
  oq.pkt_sent:inc() ;
end

function oq.SendAddonMessage( channel, msg, type, to_name )
  if (msg == nil) then
    return ;
  end
  if (#msg > 254) then
    msg = msg:sub(1,254) ;
  end
  if (type == "PARTY") and ((oq.raid.type == OQ.TYPE_RBG) or (oq.raid.type == OQ.TYPE_RAID)) then
    oq.BNSendQ_push( SendAddonMessage, channel, msg, "INSTANCE_CHAT", nil ) ;
    oq.pkt_sent:inc() ;
  else
    if (type == "INSTANCE_CHAT") then
      SendAddonMessage( channel, msg, type, to_name ) ;
      oq.pkt_sent:inc() ;
    elseif (string.find(msg, ",p8,") == nil) then
      oq.BNSendQ_push( SendAddonMessage, channel, msg, type, to_name ) ;
      oq.pkt_sent:inc() ;
    end
  end  
end

function oq.channel_party( msg ) 
  if (msg == nil) then
    return ;
  end
  if (oq.iam_in_a_party()) then
    oq.SendAddonMessage( "OQ", msg, "PARTY" ) ;
  end
end

--------------------------------------------------------------------------
--  communications
--------------------------------------------------------------------------
--[[
    http://www.wowpedia.org/API_GetCombatRating
    
    CR_WEAPON_SKILL = 1;
    CR_DEFENSE_SKILL = 2;
    CR_DODGE = 3;
    CR_PARRY = 4;
    CR_BLOCK = 5;
    CR_HIT_MELEE = 6;
    CR_HIT_RANGED = 7;
    CR_HIT_SPELL = 8;
    CR_CRIT_MELEE = 9;
    CR_CRIT_RANGED = 10;
    CR_CRIT_SPELL = 11;
    CR_HIT_TAKEN_MELEE = 12;
    CR_HIT_TAKEN_RANGED = 13;
    CR_HIT_TAKEN_SPELL = 14;
    COMBAT_RATING_RESILIENCE_CRIT_TAKEN = 15;
    COMBAT_RATING_RESILIENCE_PLAYER_DAMAGE_TAKEN = 16;
    CR_CRIT_TAKEN_SPELL = 17;
    CR_HASTE_MELEE = 18;
    CR_HASTE_RANGED = 19;
    CR_HASTE_SPELL = 20;
    CR_WEAPON_SKILL_MAINHAND = 21;
    CR_WEAPON_SKILL_OFFHAND = 22;
    CR_WEAPON_SKILL_RANGED = 23;
    CR_EXPERTISE = 24;
    CR_ARMOR_PENETRATION = 25;
    CR_MASTERY = 26; 
    CR_PVP_POWER = 27; 
]]
function oq.get_pvppower()
  return (GetCombatRating(27) or 0) ;
end

function oq.on_player_mmr_change()
  oq.get_mmr() ;
end

function oq.get_best_mmr( type ) 
  if (type == OQ.TYPE_ARENA) then
    local m = 0 ;
    for i=1,3 do
      m = max( m, oq.get_arena_rating(i) ) ;
    end
    return m ;
  else
    return oq.get_mmr() ;
  end
end

function oq.get_mmr()
  return select( 1, GetPersonalRatedInfo(4) ) or 0 ;
end

function oq.get_arena_rating(type)
  return select( 1, GetPersonalRatedInfo(type) ) or 0 ;
end

function oq.my_seat()
  return my_group, my_slot ;
end

function oq.get_spell_power()
  local pow = 0 ;
  for i=1,7 do
    pow = max( pow, GetSpellBonusDamage(i) ) ;
  end
  return pow ;
end

function oq.get_spell_crit()
  -- taken from: http://www.wowwiki.com/API_GetSpellCritChance
  local minCrit = GetSpellCritChance(2);
  for i=1,7 do
    minCrit = min(minCrit, GetSpellCritChance(i));
  end
  return minCrit ;
end

function oq.get_hks()
  local hks = GetStatistic(588) or 0 ;
  if (hks == "--") then
    hks = 0 ;
  end
  return floor(hks / 1000) ;  
end

function oq.get_resil()
  return (GetCombatRating(16) or 0) ;
end

function oq.debug_report( ... )
  if (_debug) then
    print( ... ) ;
  end
end

function oq.get_ilevel()
  return floor( select( 2, GetAverageItemLevel() )) ;
end

function oq.iam_party_leader() 
  if (oq.iam_in_a_party()) then
    return ((my_group ~= 0) and (my_slot == 1)) ;
  else
    return (my_slot == 1) ;
  end
end

function oq.iam_alone()
  if (oq._inside_instance and oq._entered_alone) then
    return true ;
  end
  local n = 0 ;
  for i=1,5 do
    local m = oq.raid.group[1].member[i] ;
    if ((m.name) and (m.name ~= "-")) then
      n = n + 1 ;
    end
  end
  return (n == 1) ;
end

function oq.iam_raid_leader() 
  return ((oq.raid.leader ~= nil) and (player_name == oq.raid.leader)) ;
end

function oq.is_raid()
  if (oq.raid.type == OQ.TYPE_RBG) or (oq.raid.type == OQ.TYPE_RAID) then
    return true ;
  end
  return nil ;
end

function oq.find_bgroup( realm )
  for bgroup,realms in pairs(OQ.BGROUPS) do
    for i,r in pairs(realms) do
      if (realm == r) then
        return bgroup ;
      end
    end
  end
  return nil ;
end

function oq.is_in_raid( name )
  for i,grp in pairs(oq.raid.group) do
    for j,mem in pairs(grp.member) do
      local n = mem.name ;
      if ((n) and (n ~= "") and (n ~= "-")) then
        if ((mem.realm) and (mem.realm ~= player_realm)) then
          n = n .."-".. mem.realm ;
        end
        if (name == n) then
          return true ;
        end
      end
    end
  end
  return nil ;
end

function oq.mark_currency()
  -- clear the wallet
  tbl.clear( OQ_toon.player_wallet ) ;
   
  -- mark hks  
  OQ_toon.player_wallet[ "hks"   ] = GetStatistic(588) or 0 ; 
  
  -- mark mmr
  OQ_toon.player_wallet[ "mmr"   ] = oq.get_mmr() or 0 ;
  
end


function oq.bg_cleanup()
  -- clean up structs no longer needed after bg
  if (_flags) then
    for i,v in pairs(_flags) do
      tbl.delete( v ) ;
    end
    _flags = tbl.delete( _flags ) ;
  end

  if (_enemy) then
    for i,v in pairs(_enemy) do
      tbl.delete( v ) ;
    end
    _enemy = tbl.delete( _enemy ) ;
  end
end


function oq.UnitSetRole( target, role )
  if (InCombatLockdown()) then
    -- cannot change while in combat.  comeback in 3 seconds to try again
    oq.timer_oneshot( 3, oq.UnitSetRole, target, role ) ;
  else
    UnitSetRole( target, role ) ;
  end
end

function oq.warning_no_role()
  local class, spec, spec_id = oq.get_spec() ;
  
  print( OQ_LILREDX_ICON .."  WARNING:  player_role unknown.  This may be a language support issue." ) ;
  print( OQ_LILREDX_ICON .."  WARNING:  If you believe oQueue does not support your language," ) ;
  print( OQ_LILREDX_ICON .."  WARNING:  please inform tiny on wow.publicvent.org : 4135 " ) ;
  print( OQ_LILREDX_ICON .."  locale: ".. GetLocale() ) ;
  print( OQ_LILREDX_ICON .."  class: ".. tostring(class) ) ;
  print( OQ_LILREDX_ICON .."  spec: ".. tostring(spec) ) ;
end

function oq.get_spec()
  local class = select(2, UnitClass("player")) ;
  local primaryTalentTree = GetSpecialization() ;
  local spec = nil ;
  local spec_id = 0 ;
  if (primaryTalentTree) then
    local id, name, description, icon, background, role = GetSpecializationInfo(primaryTalentTree) ;
    spec = name ;
    spec_id = id ;
  end
  return class, spec, spec_id ;
end

function oq.get_role()
   local class, spec, spec_id = oq.get_spec() ;
   if (spec == nil) then
     return "None" ;
   end
   if (OQ.CLASS_SPEC[ spec_id ]) then
     return OQ.CLASS_SPEC[ spec_id ].spy ;
   end
   return "None" ;
--   return OQ.BG_ROLES[ class ][ spec ] or "None" ;
end

function oq.get_player_role()
  local role = oq.get_role() ;
  local role_id = 1 ;
  -- 1  dps
  -- 2  healer
  -- 3  none 
  -- 4  tank
  if (role == "Healer") then
    role_id = 2 ;
  elseif (role == "Tank") then
    role_id = 4 ;
  end
  return role_id ;
end

function oq.auto_set_role()
  if (OQ_toon.auto_role == 0) or (InCombatLockdown()) then
    return ;
  end
  
  local role = oq.get_role() ;
  local role_id = 1 ;
  -- 1  dps
  -- 2  healer
  -- 3  none 
  -- 4  tank
  if (role == "Healer") then
    role_id = 2 ;
  elseif (role == "Tank") then
    role_id = 4 ;
  end
  if (role_id ~= player_role) then
    player_role = role_id ;
    -- insure UI update
    oq.set_role( my_group, my_slot, player_role ) ;
  end
  oq.UnitSetRole( "player", OQ.ROLES[ player_role ] ) ;
end


function oq.calc_pkt_stats()
  if (oq.pkt_recv == nil) or (oq.pkt_processed == nil) or (oq.pkt_sent == nil) or (oq.send_q == nil) then
    return ;
  end
  oq.tab5_oq_pktrecv     :SetText( string.format( "%7.2f", oq.pkt_recv._aps ) ) ;
  oq.tab5_oq_pktprocessed:SetText( string.format( "%7.2f", oq.pkt_processed._aps ) ) ;
  oq.tab5_oq_pktsent     :SetText( string.format( "%7.2f", oq.pkt_sent._aps ) ) ;
  if (#oq.send_q > 20) then  -- more then 1 sec of pkts in the queue
    oq.tab5_oq_send_queuesz:SetText( string.format("(|cFFFF3131%d|r)", #oq.send_q ) ) ;
  elseif (#oq.send_q > 5) then
    oq.tab5_oq_send_queuesz:SetText( string.format("(|cFFFFD331%d|r)", #oq.send_q ) ) ;
  else
    oq.tab5_oq_send_queuesz:SetText( "" ) ;
  end
end


function oq.on_world_map_change()
  -- check map
  if (not _map_open) and (WorldMapFrame:IsVisible()) then
    _map_open = true ;
  elseif _map_open and not WorldMapFrame:IsVisible() then
    _map_open = nil ;
    -- map closing ... open the UI if it was open
    if (_ui_open) then
      oq.ui:Show() ;
    end
  end
end


function oq.pairsByKeys(t, f)
  if (t == nil) then
    return nil ;
  end
   local a = tbl.new() ;
   for n in pairs(t) do 
     table.insert(a, n) 
   end
   table.sort(a, f)
   local i = 0      -- iterator variable
   local iter = function ()   -- iterator function
      i = i + 1
      if a[i] == nil then return nil
      else return a[i], t[a[i]]
      end
   end
   return iter
end

function oq.cleanup_bnfriends()
  for i,v in pairs(OQ_data.bn_friends) do
    if (v.realm == nil) or (v.realm == "") then
      OQ_data.bn_friends[i] = nil ;
    end
  end
end

function oq.clear_sk_ignore()
  local sk = strlower(OQ.SK_NAME) ;
  if (player_realm ~= OQ.SK_REALM) then
    sk = sk .."-".. strlower(OQ.SK_REALM) ;
  end
  local n = GetNumIgnores() ;
  for i=1,n do
    local ignored = strlower( GetIgnoreName(i) ) ;
    if (sk == ignored) then
      DelIgnore( sk ) ;
      return ;
    end
  end
end

function oq.send_to_scorekeeper( msg )
  oq.clear_sk_ignore() ;
  local pid, online = oq.is_bnfriend(OQ.SK_BTAG) ;
  if (pid ~= nil) then
    if (online) then
      oq.BNSendWhisper( pid, msg, OQ.SK_NAME, OQ.SK_REALM ) ;
      return ;
    else
      -- no way to leave a note... should resend when no reply recv'd
      return ;
    end
  end

  if (player_realm == OQ.SK_REALM) and (player_faction == "H") then
    oq.SendAddonMessage( "OQSK", msg, "WHISPER", OQ.SK_NAME ) ;
    return ;
  end
  oq.BNSendFriendInvite( OQ.SK_BTAG, msg ) ;
end

function oq.submit_report( str, tops, bg, crc, bg_end_tm )
  if (str == nil) then
    return ;
  end
  
  local submit_token = "S".. oq.token_gen() ;
  oq.token_push( submit_token ) ;

  if (OQ_toon.reports == nil) then
    OQ_toon.reports = {} ;
  end
  OQ_toon.reports[submit_token] = { tok = submit_token, last_tm = utc_time(), report = str } ;
  OQ_toon.reports[submit_token].tops = copyTable( tops ) ;
  OQ_toon.reports[submit_token].bg = bg ;
  OQ_toon.reports[submit_token].crc = crc ;
  OQ_toon.reports[submit_token].end_tm = bg_end_tm ;
end


function oq.submit_btag_info()
  local now = utc_time() ;
  if (OQ_data.btag_submittal_tm ~= nil) and (OQ_data.btag_submittal_tm > now) then
    return ;
  end
  local f = oq.submit_btag ;
  if (OQ_data.ok2submit_tag ~= nil) and (OQ_data.ok2submit_tag == 0) then
    f = oq.submit_still_kickin ; -- not submitting for mesh, just saying user still here
  end
  if (f() ~= nil) then
    OQ_data.btag_submittal_tm = now + OQ_BTAG_SUBMIT_INTERVAL ;
  end
end

function oq.send_my_premade_info()
  if ((not oq.iam_raid_leader()) or OQ_toon.disabled) then
    return ;
  end

  -- announce new raid on main channel
  local nMembers, avg_resil, avg_ilevel = oq.calc_raid_stats() ;
  local nWaiting = oq.n_waiting() ;
  local now      = utc_time() ;
  
  oq.raid.pdata     = oq.get_pdata() ;
  oq.raid.leader_xp = oq.get_leader_experience() ;

  if (player_realm == nil) then
    player_realm = oq.GetRealmName() ;
  end

  local raid = oq.premades[ oq.raid.raid_token ] ;
  local enc_data = oq.encode_data( "abc123", player_name, player_realm, player_realid ) ;
  if (raid ~= nil) then
    local tmp = nil ;
    raid.stats, tmp = copyTable( OQ_data.stats ) ; -- make sure to copy stats
    tbl.delete( tmp ) ;
  end
  oq._my_group = 1 ;
  oq.process_premade_info( oq.raid.raid_token, oq.encode_name( oq.raid.name ), oq.raid.faction, 
                           oq.raid.level_range, oq.raid.min_ilevel, oq.raid.min_resil, oq.raid.min_mmr, enc_data, oq.encode_bg( oq.raid.bgs ),
                           nMembers, 1, now, 0 , nWaiting, oq.raid.has_pword, oq.raid.is_realm_specific, 
                           oq.raid.type, oq.raid.pdata, oq.raid.leader_xp, player_karma ) ;
  oq._my_group = nil ;

  if (raid == nil) then
    -- would have just been created, ok2send
    local tmp = nil ;
    
    raid = oq.premades[ oq.raid.raid_token ] ;
    raid.stats, tmp = copyTable( OQ_data.stats ) ; -- make sure to copy stats
    tbl.delete( tmp ) ;
  elseif (raid.next_advert > now) then
    return ;
  end
  
  if (player_realm == nil) then
    player_realm = oq.GetRealmName() ;
  end
  raid.leader         = player_name ;
  raid.leader_realm   = player_realm ;
  raid.leader_rid     = player_realid ;
  raid.last_seen      = now ;
  raid.next_advert    = now + OQ_SEC_BETWEEN_PROMO ;
  
  local ad_text = oq.raid.bgs ;
    
  local stat = 
  0 ;
  
  local is_realm_specific = nil ;
  local is_source = 1 ;

  -- on_premade
  local is_restricted = _oqgeneral_lockdown ;
  _oqgeneral_lockdown = nil ; -- this allows the group leader to advertise on their own realm
  oq.announce( "p8,".. 
               oq.raid.raid_token ..",".. 
               oq.encode_name( oq.raid.name ) ..",".. 
               oq.encode_premade_info( oq.raid.raid_token, stat, now, oq.raid.has_pword, is_realm_specific, is_source, player_karma ) ..","..
               enc_data ..","..
               oq.encode_bg( ad_text ) ..","..
               oq.raid.type ..","..
               oq.raid.pdata ..","..
               oq.get_leader_experience() ..","..
               oq.encode_mime64_1digit( oq.raid.subtype )
             ) ;
  _oqgeneral_lockdown = is_restricted ; -- this allows the group leader to advertise on their own realm
end

function oq.advertise_my_raid()
  if ((not oq.iam_raid_leader()) or (oq.raid.raid_token == nil)) then
    return ;
  end
  oq._ad_ticker = (oq._ad_ticker or 0) + 1 ;
  if ((oq._ad_ticker % 2) == 0) then
    if (not _inside_bg) then
      -- this will produce premade ads every 30 seconds when not in a bg and every 15 seconds when inside
      return ;
    end
  end
  
  if (not _inside_bg) then
    -- send the raid token to everyone in the party
    oq.party_announce( "party_update,".. oq.raid.raid_token ) ;
  end
  -- even if inside a bg, the leader will continue to send premade info
  oq.send_my_premade_info() ;
end

function oq.numeric_sanity( n )
  if (n == nil) or (n == "") or (tostring(n) == "-1.#IND") then
    return 0 ;
  end
  return tonumber( n or 0 ) or 0 ;
end

function oq.nActiveGroups()
  if (oq.raid.type ~= OQ.TYPE_BG) then
    return 1 ;
  end
  local n = 0 ;
  for i=1,8 do
    if (oq.raid.group[i].member[1].realid ~= nil) then
      n = n + 1 ;
    end
  end
  return n ;
end

-- bnet conversation only used for regular bgs
-- only started when the number of groups exceeds 3
function oq.add_to_conversation( pid )
  if (not oq.iam_raid_leader()) or (oq.raid.type ~= OQ.TYPE_BG) then
    return ;
  end
  if (oq.nActiveGroups() < 3) and (oq._hConversation == nil) then
    -- no conversation yet
    return ;
  end
--[[
issue #1: multiple accounts under one bnet
issue #2: must have 3 ppl minimum to start
issue #3: what if 3rd person leaves?
issue #4: if 2nd person leaves, conversation closes?  have to continually recreate

print( "max in a channel:  ".. BNGetMaxPlayersInConversation() ) ;
print( "max # conversations: ".. BNGetMaxNumConversations () ) ;

if (thistle_pid ~= 0) then
   print( "attempting to create conversation" ) ;
   --   BNCreateConversation( thistle_pid, 0 ) ;
end

for i=1, BNGetMaxNumConversations() do
   if ( BNGetConversationInfo(i) == "conversation" ) then
      print( "# in channel: ".. tostring(BNGetNumConversationMembers( i ))) ;
      BNSendConversationMessage( i, "test msg" );
      --      BNInviteToConversation( i, snot_pid );
      --      BNInviteToConversation( i, snot2_pid );
   end
end
]]--
end

function oq.show_raid()
  print( "raid_name: ".. tostring(oq.raid.name) .."  token(".. tostring(oq.raid.raid_token) ..")" ) ;
  print( "leader: ".. tostring(oq.raid.leader) .."-".. tostring(oq.raid.leader_realm) .."  btag(".. tostring(oq.raid.leader_rid) ..")" ) ;
  for i=1,8 do
    local str = " ".. tostring(i) ..". " ;
    if (oq.raid.group[i]) then
      local g = oq.raid.group[i] ;
      if (g.member) then
        for j=1,5 do
          local m = g.member[j] ;
          if (m) then
            if (m.name) then
              str = str .."(".. tostring(j) ..": ".. tostring(m.class) ..".".. tostring(m.name) .."-".. tostring(m.realm_id) .."^".. tostring(m.realid) ..") " ;
            else
              str = str .."(".. tostring(j) ..": .) " ;
            end
          else
            str = str .."(".. tostring(j) ..": nil) " ;
          end
        end
      else
        str = str .."  nil+" ;
      end
    else
      str = str .."  nil" ;
    end
    print( str ) ;
  end
  print( "--" ) ;
end

function oq.raid_create()
  if (oq.raid.raid_token ~= nil) then
    print( OQ.STILL_IN_PREMADE ) ;
    return ;
  end
  -- check information to make sure it's all filled in

  -- generate token
  oq.raid.raid_token = "G".. oq.token_gen() ;
  if (not oq.valid_rid( player_realid )) then
    message( OQ.BAD_REALID .." ".. tostring(player_realid) ) ;
    return ;
  end
  
  if (player_level < 10) then
    message( OQ.MSG_CANNOTCREATE_TOOLOW ) ;
    return ;
  end

  OQ_data.realid = player_realid ;

  if (player_realm == nil) then
    player_realm = oq.GetRealmName() ;
  end
  -- set raid info
  my_group                 = 1 ;
  my_slot                  = 1 ;
  oq.raid.name             = oq.rtrim( oq.tab3_raid_name:GetText() ) ;
  oq.raid.leader           = player_name ;
  oq.raid.leader_class     = player_class ;
  oq.raid.leader_realm     = player_realm ;
  oq.raid.leader_rid       = player_realid ;
  oq.raid.level_range      = oq.tab3_level_range ;
  oq.raid.faction          = player_faction ; 
  oq.raid.min_ilevel       = oq.numeric_sanity( oq.tab3_min_ilevel:GetText() ) ;
  oq.raid.min_resil        = oq.numeric_sanity( oq.tab3_min_resil:GetText() ) ;
  oq.raid.min_mmr          = oq.numeric_sanity( oq.tab3_min_mmr:GetText() ) ;
  oq.raid.notes            = (oq.tab3_notes.str or "") ;
  oq.raid.bgs              = string.gsub( oq.tab3_bgs:GetText() or ".", ",", ";" ) ;
  oq.raid.pword            = oq.tab3_pword:GetText() or "" ;
  oq.raid.leader_xp        = oq.get_leader_experience() ;
  
  local m = { level     = player_level, 
              faction   = player_faction, 
              resil     = oq.get_resil(), 
              ilevel    = oq.get_ilevel(), 
              spec_type = player_role, 
--              arena2s   = oq.get_arena_rating(1),
--              arena3s   = oq.get_arena_rating(2),
--              arena5s   = oq.get_arena_rating(3),
--              mmr       = oq.get_mmr()
              mmr       = oq.get_best_mmr( oq.raid.type ) 
            } ;
  if (oq.is_qualified( m ) == nil) then
    oq.raid_cleanup() ;
    StaticPopup_Show("OQ_DoNotQualifyPremade") ;
    tbl.delete( m ) ;
    return ;
  end
  m = tbl.delete( m ) ; -- cleanup

  if (oq.raid == nil) or (oq.raid.type == nil) then
    oq.set_premade_type( OQ.TYPE_BG ) ;
  else
    oq.set_premade_type( oq.raid.type ) ;
  end

  if (oq.raid.pword == nil) or (oq.raid.pword == "") then
    oq.raid.has_pword = nil ;
  else
    oq.raid.has_pword = true ;
  end
  
  OQ_data.stats.start_tm   = utc_time() ;
  OQ_data.stats.bg_start   = 0 ; -- place holder - time() of bg start
  OQ_data.stats.bg_end     = 0 ; -- place holder - time() of bg end

  oq.raid.notes      = oq.raid.notes or "" ;
  oq.raid.bgs        = oq.raid.bgs or "" ;
  
  -- enable premade leader only controls
  oq.ui_raidleader() ;

  oq.set_group_lead( 1, player_name, player_realm, player_class, player_realid ) ;
  oq.raid.group[1].member[1].resil  = player_resil ;
  oq.raid.group[1].member[1].ilevel = player_ilevel ;
  oq.raid.group[1].member[1].level  = player_level ;

  -- update tab_1
  oq.tab1_name :SetText( oq.raid.name ) ;
  oq.tab1_notes:SetText( oq.raid.notes ) ;

  oq.update_tab1_stats() ;
  oq.get_group_hp() ;
  
  -- remove myself from other waitlists
  oq.clear_pending() ;

  -- assign slots to the party members
  local enc_data = oq.encode_data( "abc123", oq.raid.leader, oq.raid.leader_realm, oq.raid.leader_rid ) ;
  oq.party_assign_slots( my_group, enc_data ) ;
  
  -- activate in-raid only procs
  oq.procs_join_raid() ;

  -- tell the world 
  oq._ad_ticker = 0 ;
  oq.advertise_my_raid() ;
  return 1 ;
end

-- if same realm, will whisper
-- if real-id friend, will bnwhisper
-- if not same realm and not friend, will bnfriendinvite with msg in note
--
function oq.realid_msg( to_name, to_realm, real_id, msg ) 
  if (msg == nil) then
    return ;
  end
  local rc = 0 ;
  if ((to_name == nil) or (to_name == "-") or (to_realm == nil)) then
    return ;
  end
  if ((to_name == player_name) and (to_realm == player_realm)) then
    -- sending to myself?
    return ;
  end
  if (not oq.well_formed_msg( msg )) then
      local msg_tok = "W".. oq.token_gen() ;
      oq.token_push( msg_tok ) ;
      msg = "OQ,".. 
            OQ_VER ..",".. 
            msg_tok ..","..
            OQ_TTL ..",".. 
            msg ;
  end
        
  if (to_realm == player_realm) then
    oq.SendAddonMessage( "OQ", msg, "WHISPER", to_name ) ;
    return ;
  end

  local pid, online = oq.is_bnfriend(real_id, to_name, to_realm) ;
  if (pid ~= nil) then
    if (pid > 0) then
      oq.BNSendWhisper( pid, msg, to_name, to_realm ) ;
      return ;
    else
      -- no way to leave a note... should resend when no reply recv'd
      return ;
    end
  end

  oq.BNSendFriendInvite( real_id, msg ) ;
end

function oq.bnbackflow( msg, to_pid )
  if (_sender_pid ~= to_pid) then
    return nil ;
  end
  -- ie: "OQ,0A,P477389297,G17613410,name,1,3,Tinymasher,Magtheridon"
  local tok = msg:sub(7,16) ;
  if (_msg_token ~= tok) then
    return nil ;
  end
  return true ;
end

function oq.iknow_scorekeeper()
  for i,v in pairs(OQ_data.bn_friends) do
    if ((v.presenceID ~= 0) and v.isOnline and v.sk_enabled) then
      return v.presenceID ;
    end
  end
  return nil ;
end

function oq.bn_ok2send( msg, pid )
  if (oq.bnbackflow( msg, pid )) then
    return nil ;
  end
  for i,v in pairs(OQ_data.bn_friends) do
    if ((v.presenceID == pid) and v.isOnline and v.oq_enabled) then
      return true ;
    end
  end
  return nil ;
end

function oq.well_formed_msg( m )
  if (m == nil) then
    return nil ;
  end
  local str = OQ_MSGHEADER .."".. OQ_VER .."," ;
  if (m:sub(1,#str) == str) then
    return true ;
  end
  str = OQSK_HEADER ..",".. OQSK_VER .."," ;
  if (m:sub(1,#str) == str) then
    return true ;
  end
  return nil ;
end

function oq.BNSendQ_push( func_, pid_, msg_, name_, realm_ )
  if (pid_ == 0) or (msg_ == nil) or (OQ_toon.disabled) then
    return ;
  end
  if (oq.send_q == nil) then
    oq.send_q = tbl.new() ;
  end
  -- pkt recycling
  if (oq.__msgpktq == nil) then
    oq.__msgpktq = tbl.new() ;
  end
  local t = next( oq.__msgpktq ) ;
  if (t) then
    oq.__msgpktq[t] = nil ;
  else
    oq._nMsgPackets = (oq._nMsgPackets or 0) + 1 ;
    t = tbl.new() ;
    t.__id = oq._nMsgPackets ;
  end
  t.func  = func_ ;
  t.pid   = pid_ ;
  t.msg   = msg_ ;
  t.name  = name_ ;
  t.realm = realm_ ;
  t.ts    = utc_time() ;
  table.insert( oq.send_q, t ) ;  
end

function oq.BNSendQ_pop() 
  if (oq.send_q == nil) or (#oq.send_q == 0) then
    return ;
  end
  local now = utc_time() ;
  local t = nil ;
  repeat
    t = table.remove( oq.send_q, 1 ) ;
  until (t == nil) or ((now - t.ts) < 2.0) ;
  if (t == nil) then
    return ;
  end
  -- have an entry... process
  t.func( t.pid, t.msg, t.name, t.realm ) ;
  
  -- recycle pkt holder
  if (oq.__msgpktq  == nil) then
    oq.__msgpktq = tbl.new() ;
  end
  oq.__msgpktq[t] = true ;
end

function oq.BNSendWhisper( pid, msg, name, realm )
  oq.BNSendQ_push( oq.BNSendWhisper_now, pid, msg, name, realm ) ;
end

function oq.BNSendWhisper_now( pid, msg, name, realm )
  if (pid == 0) or (msg == nil) or (OQ_toon.disabled) then
    return ;
  end
  if (name == nil) or (realm == nil) or (msg:find( ",".. OQ_FLD_TO ) ~= nil) then
    if (#msg > 254) then
      msg = msg:sub(1,254) ;
    end
    BNSendWhisper( pid, msg ) ;
    oq.pkt_sent:inc() ;
    return ;
  end
  if (player_realm == nil) then
    player_realm = oq.GetRealmName() ;
  end
  if (#msg > 254) then
    msg = msg:sub(1,254) ;
  end
  BNSendWhisper( pid, msg ) ;  
  oq.pkt_sent:inc() ;
end

function oq.get_field( m, fld )
  if (m == nil) or (fld == nil) then
    return nil ;
  end
  -- not found, leave
  local p1 = m:find( fld ) ;
  if (p1 == nil) then
    return nil ;
  end
  
  -- find end, either the next ',' or eos
  local p2 = m:find( ",", p1 ) ;
  if (p2 == nil) then
    p2 = -1 ;
  else
    p2 = p2 - 1 ;
  end
  return m:sub( p1 + #fld, p2 ) ;
end

-- takes name-realm and returns name,realm
-- if there is no realm, player_realm assumed
--
function oq.crack_name( n )
  if (n == nil) then
    return nil, nil ;
  end
  if (player_realm == nil) then
    player_realm = oq.GetRealmName() ;
  end
  local name = n ;
  local realm = player_realm ;
  local p = n:find("-") ;
  if (p) then
    name  = n:sub( 1, p-1 ) ;
    realm = n:sub( p+1, -1 ) ;
  end
  return name, realm ;
end

function oq.is_number(s)
  if (s == nil) then
    return nil ;
  end
  if (type(s) == "number") then
    return true ;
  end
  if (tonumber(s) ~= nil) then
    return true ;
  end
  return nil ;
end

function oq.space_it( s ) 
   local x = string.find( s:sub(2,-1), OQ.PATTERN_CAPS ) ;
   if (x == nil) or (s:sub(x,x) == "'") then
      return s ;
   end
   return s:sub( 1, x ) .." ".. s:sub( x+1, -1 ) ;
end

function oq.realm_cooked(realm)
  if (realm == nil) or (realm == "-") or (realm == "nil") or (realm == "n/a") or (realm == "") then
    return 0 ;
  end
  if (oq.is_number(realm)) then
    return realm ;
  end
  if (OQ.SHORT_BGROUPS[ realm ] ~= nil) then
    return OQ.SHORT_BGROUPS[ realm ] ;
  end
  local r = realm ;
  if (OQ.REALMNAMES_SPECIAL[ realm ] ~= nil) then
    r = OQ.REALMNAMES_SPECIAL[ realm ] ;
  elseif (OQ.REALMNAMES_SPECIAL[ strlower( realm ) ] ~= nil) then
    r = OQ.REALMNAMES_SPECIAL[ strlower(realm) ] ;
  end
  
  if (OQ.SHORT_BGROUPS[ r ] == nil) then
    -- for some reason, realms like "Bleeding Hollow" will come from blizz as "BleedingHollow".. sometimes
    r = oq.space_it( r ) ; 
    if (OQ.SHORT_BGROUPS[ r ] == nil) then
      print( OQ_REDX_ICON .." unable to locate realm id.  realm[".. tostring(realm) .."]" ) ;
      print( OQ_REDX_ICON .." please report this to tiny on wow.publicvent.org : 4135" ) ;
      return 0 ;
    end
  end
 
  return OQ.SHORT_BGROUPS[ r ] ;
end

function oq.realm_uncooked(realm)
  if (oq.is_number(realm)) then
    realm = OQ.SHORT_BGROUPS[ tonumber(realm) ] ;
  elseif (realm == "nil") then
    realm = nil ;
  end
  return realm ;
end

--  local m, name_, realm_ = oq.crack_bn_msg( msg ) ;
function oq.crack_bn_msg( msg )
  local  p = msg:find( ",".. OQ_FLD_TO ) ;
  if (p == nil) then
    return msg, nil, nil, nil ;
  end
   
  local m, name, realm, from ;
  m     = msg:sub( 1, p - 1 ) ;
  name  = oq.get_field( msg, OQ_FLD_TO ) ;
  realm = oq.get_field( msg, OQ_FLD_REALM ) ;
  realm = oq.realm_uncooked(realm) ;
  from  = oq.get_field( msg, OQ_FLD_FROM ) ;
  local from_name, from_realm = oq.crack_name( from ) ;
  from_realm = oq.realm_uncooked(from_realm) ;
  return m, name, realm, from ;
end

function oq.whisper_msg( to_name, to_realm, msg, immediate ) 
  if (msg == nil) then
    return ;
  end
  local rc = 0 ;
  if ((to_name == nil) or (to_name == "-")) then
    return ;
  end
  if ((to_name == player_name) and (to_realm == player_realm)) then
    return ;
  end
  if (not oq.well_formed_msg( msg )) then
      local msg_tok = "W".. oq.token_gen() ;
      oq.token_push( msg_tok ) ;
      msg = "OQ,".. 
            OQ_VER ..",".. 
            msg_tok ..","..
            OQ_TTL ..",".. 
            msg ;
  end
  if (to_realm == player_realm) then
    if ((oq._sender == nil) or (oq._sender ~= to_name)) then
      if (immediate) then
        SendAddonMessage( "OQ", msg, "WHISPER", to_name ) ;
        oq.pkt_sent:inc() ;
      else
        oq.SendAddonMessage( "OQ", msg, "WHISPER", to_name ) ;
      end
    end
    return ;
  elseif (to_realm ~= nil) then
    -- check to see if we have BN access
    local presenceID = oq.bnpresence( to_name .."-".. to_realm ) ;
    if (presenceID == 0) then
      local msg_sent = nil ;
      -- send to real-id list for ppl not in the raid (hoping they will forward to their local OQGeneral channel)
      return ;
    else
      if (immediate) then
        oq.BNSendWhisper_now( presenceID, msg, to_name, to_realm ) ;
      else
        oq.BNSendWhisper( presenceID, msg, to_name, to_realm ) ;
      end
    end
  end
end

function oq.whisper_party_leader( msg ) 
  if ((my_group <= 0) or (oq.raid.group[my_group].member[1].name == nil) or (msg == nil)) then
    return ;
  end
  if ((oq.raid.leader == nil) or (oq.raid.leader_realm == nil)) then
    return ;
  end
  local lead = oq.raid.group[my_group].member[1] ;
  local name = lead.name ;
  if (lead.realm ~= player_realm) then
    name = name .."-".. lead.realm ;
  end
  -- make sure the msg is well formed
  if (not oq.well_formed_msg( msg )) then
      local msg_tok = "W".. oq.token_gen() ;
      oq.token_push( msg_tok ) ;
      msg = "OQ,".. 
            OQ_VER ..",".. 
            msg_tok ..","..
            OQ_TTL ..",".. 
            msg ;
  end
  oq.SendAddonMessage( "OQ", msg, "WHISPER", name ) ;
end

function oq.whisper_raid_leader( msg ) 
  if (msg == nil) then
    return ;
  end

  if ((oq.raid.leader == nil) or (oq.raid.leader_realm == nil)) then
    return ;
  end
  -- make sure the msg is well formed
  if (not oq.well_formed_msg( msg )) then
      local msg_tok = "W".. oq.token_gen() ;
      oq.token_push( msg_tok ) ;
      msg = "OQ,".. 
            OQ_VER ..",".. 
            msg_tok ..","..
            OQ_TTL ..",".. 
            msg ;
  end
  oq.whisper_msg( oq.raid.leader, oq.raid.leader_realm, msg, true ) ; 
end

function oq.send_invite_accept( raid_token, group_id, slot, name, class, realm, realid, req_token ) 
  -- the 'W' stands for 'whisper' and should not be echo'd far and wide
  local msg_tok = "W".. oq.token_gen() ;
  oq.token_push( msg_tok ) ;

  local enc_data = oq.encode_data( "abc123", player_name, player_realm, player_realid ) ;
  local m = "OQ,".. 
            OQ_VER ..",".. 
            msg_tok ..","..
            OQ_TTL ..",".. 
            "invite_accepted,".. 
            raid_token ..",".. 
            group_id ..","..
            slot ..","..
            class ..","..
            enc_data ..","..
            req_token ;

  oq.whisper_raid_leader( m ) ;
end

function oq.check_for_dead_group()
  if ((oq.raid.raid_token == nil) or _inside_bg or (not oq.iam_raid_leader())) then
    return ;
  end
  if (oq.raid.type == OQ.TYPE_RBG) or (oq.raid.type == OQ.TYPE_RAID) then
    oq.assign_raid_seats() ;
    return ;
  end
  local now = utc_time() ;
  
  if (not oq.iam_raid_leader()) then
    -- group 1 cannot lag out
    if (my_group > 1) and ((now - oq.raid._last_lag) >= OQ_GROUP_TIMEOUT) then
      -- group leader lost conn or just left
      oq.quit_raid_now() ;
    end
    return ;
  end  
  
  -- remove a group if its been more end OQ_GROUP_TIMEOUT since last ping response
  for i=2,8 do
    if (oq.raid.group[i]) and (oq.raid.group[i].member) then
      local grp  = oq.raid.group[i] ;
      local lead = grp.member[1] ;
      if (lead.name) and (lead.name ~= "-") then 
        if (grp._last_ping ~= nil) and ((now - grp._last_ping) >= OQ_GROUP_TIMEOUT) then
          oq.remove_group( i ) ;
        elseif (grp._last_ping == nil) then
          grp._last_ping = now ;
        end
      end
    end
  end
  -- ping all leaders
  oq.raid_ping() ;
end

function oq.check_my_role( changedPlayer, changedBy, oldRole, newRole ) 
  if (changedPlayer == player_name) then
    local role = OQ.ROLES[ newRole ] ;
    if (role ~= player_role) then  
      player_role = role ;
    end
    -- insure UI update
    oq.set_role( my_group, my_slot, role ) ;
  end
end

function oq.brief_player( slot, name )
  if (not oq.iam_party_leader() or (my_group == 0) or (my_slot ~= 1)) then
    return ;
  end
  local enc_data = oq.encode_data( "abc123", oq.raid.leader, oq.raid.leader_realm, oq.raid.leader_rid ) ;
  oq.party_announce( "party_join,".. 
                      my_group ..","..
                      oq.encode_name( oq.raid.name ) ..",".. 
                      oq.raid.leader_class ..",".. 
                      enc_data ..",".. 
                      oq.raid.raid_token  ..",".. 
                      oq.encode_note( oq.raid.notes )
                   ) ;
  oq.party_announce( "party_slot,".. 
                     name ..","..
                     my_group ..","..
                     slot ..",".. 
                     (oq.raid.type or OQ.TYPE_BG)
                   ) ;
end

function oq.set_member_stats_offline( m ) 
  if (m == nil) or (m.stats == nil) then
    return ;
  end
  --  m.flags must set to 0 for offline
  m.stats = m.stats:sub(1,6) .."A".. m.stats:sub(8,-1) ;
end

function oq.find_group_member( name )
  if (not oq.iam_party_leader() or (my_group == 0) or (my_slot ~= 1) or _inside_bg) then
    return ;
  end
  for i=2,5 do
    -- check the members of my party to see if they are online
    local m = oq.raid.group[ my_group ].member[ i ] ;
    if (m.name and (m.name == name)) then
      return m ;
    end
  end  
  return nil ;
end

function oq.remove_one_mesh_node()
  local ntotal, nonline = BNGetNumFriends() ;
  local now = utc_time() ;
  local rc = nil ;
  local option = "silent" ;
  for i=ntotal,1,-1 do
    tbl.fill( _f, BNGetFriendInfo( i ) ) ;

    local presenceID = _f[1] ;
    local givenName  = _f[2] ;
    local btag       = _f[3] ;
    local noteText   = _f[13] or "" ;
    -- remove this friend from OQ_data if noted
    if (noteText == "REMOVE OQ") or (noteText == "OQ,mesh node") then
      rc = oq.remove_friend_by_pid( presenceID, btag, givenName, option, "group member" ) ;
    elseif (noteText == "OQ,leader") and (oq.raid.raid_token == nil) then
      rc = oq.remove_friend_by_pid( presenceID, btag, givenName, option, "group leader" ) ;
    elseif ((noteText == "") and oq.in_btag_cache( btag )) then
      rc = oq.remove_friend_by_pid( presenceID, btag, givenName, option, "mesh auto-add" ) ;
    end
    if (rc ~= nil) then
      break ;
    end
  end  
  if (rc ~= nil) then
    print( OQ_DIAMOND_ICON .." ".. string.format( L["NOTICE:  You've exceeded the cap before the cap(%s).  removed: %s"], OQ.BNET_CAPB4THECAP, tostring(_f[3]) )) ;
  end
  return rc ;
end

function oq.bntoons()
  local now = utc_time() ;
  if (next_bn_check > now) then
    return ;
  end
  next_bn_check = now + 5 ; -- refresh presence ids every 5 seconds (was 30, but the numbers were getting re-issued more frequently then that)
  if (OQ_data.bn_friends == nil) then
    OQ_data.bn_friends = {} ;
  end
  if (oq._bnet_friends == nil) then
    oq._bnet_friends = tbl.new() ;
  end
  local ntotal, nonline = BNGetNumFriends() ;
  if (ntotal > OQ.BNET_CAPB4THECAP) then
    -- remove one
    if (oq.remove_one_mesh_node()) then
      next_bn_check = now + 2 ; -- force recheck next time thru
      return ;
    else
      if (oq._warning_001 == nil) or ((now - oq._warning_001) > 120) then
        print( OQ_LILSKULL_ICON .." ".. string.format( L["WARNING:  Your battle.net friends list has %s friends."], tostring(ntotal) )) ;
        print( OQ_LILSKULL_ICON .." ".. string.format( L["WARNING:  You've exceeded the cap before the cap(%s)"], OQ.BNET_CAPB4THECAP )) ;
        print( OQ_LILSKULL_ICON .." ".. string.format( L["WARNING:  No mesh nodes available for removal.  Please trim your b.net friends list"] )) ;
      end
      oq._warning_001 = now ;
    end
  end
  
  for i,v in pairs(OQ_data.bn_friends) do
    v.presenceID = 0 ;
    v.isOnline   = nil ;
    v.oq_enabled = nil ;
  end
  local p_faction = 0 ; -- 0 == horde, 1 == alliance, -1 == offline
  if (player_faction == "A") then
    p_faction = 1 ;
  end

  for friendId=ntotal,1,-1 do
    tbl.fill( _f, BNGetFriendInfo( friendId ) ) ;
    if (_f[3]) then
      _f[3] = strlower(_f[3]) ;
    end
    
    local presenceID = _f[1] ;
    local givenName  = _f[2] ;
--    local surName    = _f[3] ;
    local client     = _f[7] ;
    local online     = _f[8] ;
    local broadcast  = _f[12] ;
    if ((_f[4] == true) and (_f[3]) and (oq._bnet_friends[_f[3]] == nil)) then
      -- new bnet friend
      if (oq._bnet_friends_initialized) and (ntotal >= OQ.BNET_CAPB4THECAP) then
        -- new bnet friend... already max'd at 98.  this is the cap before the cap
        -- wow will issue an assert at some point over 98 bnet friends
--        print( OQ_LILSKULL_ICON .." WARNING: You've exceeded the cap before the cap(".. OQ.BNET_CAPB4THECAP ..")." ) ;
      end
      oq._bnet_friends[_f[3]] = true ;
    end
    
    if ((_f[4] == true) and (_f[3]) and oq.is_banned( _f[3], true )) then -- will only remove if on your LOCAL oq ban list
      print( OQ_LILSKULL_ICON .." ".. string.format( L["Found oQ banned b.tag on your friends list.  removing: %s"], tostring(_f[3]) )) ;
      BNRemoveFriend( presenceID ) ; 
    else
      local nToons = BNGetNumFriendToons( friendId ) ;
      if (nToons > 0) and online then
        for toonIndx=1,nToons do
          tbl.fill( _toon, BNGetFriendToonInfo( friendId, toonIndx ) ) ;
          local toonName    = _toon[2] ;
          local toon_client = _toon[3] ;
          local realmName   = _toon[4] ;
          local toon_pid    = _toon[16] ;
          local faction     = 1 ;
          if (_toon[6] == "Horde") then
            faction = 0 ;
          end

          if (faction == p_faction) and (toon_client == "WoW") then
            local name = toonName .."-".. realmName ;
            local friend = OQ_data.bn_friends[ name ] ;
            if (friend == nil) then
              OQ_data.bn_friends[ name ] = tbl.new() ;
              friend = OQ_data.bn_friends[ name ] ;
            end
            friend.isOnline   = true ;
            friend.toonName   = toonName ;
            friend.realm      = realmName ;
            friend.presenceID = toon_pid ;
            friend.oq_enabled = nil ;
            if (broadcast ~= nil) and (broadcast:sub(1, #OQ_BNHEADER ) == OQ_BNHEADER) then
              friend.oq_enabled = true ;
            end
            if (broadcast ~= nil) and (broadcast:sub(1, #OQ_SKHEADER ) == OQ_SKHEADER) then
              friend.sk_enabled = true ;
            end          
          end
        end
      end  
    end
  end  
  
  -- clear out those that didn't update
  for i,v in pairs(OQ_data.bn_friends) do
    if (v.presenceID == 0) then
      OQ_data.bn_friends[i] = tbl.delete( v ) ;
    end
  end

  -- update ui elements  
  oq._bnet_friends_initialized = true ;
  oq.n_connections() ;
end

function oq.is_toon_friended( name, realm )
  local ntotal, nonline = BNGetNumFriends() ;
  for friendId=1,ntotal do
    tbl.fill( _f, BNGetFriendInfo( friendId ) ) ;
    local client     = _f[7] ;
    local online     = _f[8] ;
    local nToons = BNGetNumFriendToons( friendId ) ;
    if (nToons > 0) and online and (client == "WoW") then
      for toonIndx=1,nToons do
        tbl.fill( _toon, BNGetFriendToonInfo( friendId, toonIndx ) ) ;
        local toonName   = _toon[2] ;
        local realmName  = _toon[4] ;
        if (name == toonName) and (realm == realmName) then
          return 1 ;
        end
      end
    end
  end
  return nil ;
end

function oq.get_toon_pid( friendId, name_, realm_ )
  if (name_ == nil) or (realm_ == nil) then
    return 0 ;
  end
  local nToons = BNGetNumFriendToons( friendId ) ;
  if (nToons > 0) then
    for toonIndx=1,nToons do
      tbl.fill( _toon, BNGetFriendToonInfo( friendId, toonIndx ) ) ;
      if (_toon[3] == "WoW") and (_toon[2]) and (strlower(_toon[2]) == name_) and (_toon[4]) and (strlower(_toon[4]) == realm_) then
        return _toon[16] ;
      end
    end
  end
  return 0 ;
end

function oq.is_bnfriend(btag_, name_, realm_) 
  if (btag_ == nil) then
    return nil, nil ;
  end
  btag_  = strlower( btag_ ) ; -- just to make sure
  name_  = strlower( name_ or "" ) ;
  realm_ = strlower( realm_ or "" ) ;
  local ntotal, nonline = BNGetNumFriends() ;
  for friendId=1,ntotal do
    tbl.fill( _f, BNGetFriendInfo( friendId ) ) ;
    
    local presenceID = _f[1] ;
    local btag       = _f[3] ;
    local client     = _f[7] ;
    local online     = _f[8] ;
    if (btag) and (btag_ == strlower(btag)) then
      if online then
        local pid = oq.get_toon_pid( friendId, name_, realm_ ) ;
        if (pid ~= 0) then
          return pid, true ;
        elseif (client == "WoW") then
          return presenceID, true ;
        else
          return 0, nil ;
        end
      else
        return 0, nil ;
      end
    end
  end
  return nil, nil ;
end

function oq.get_nConnections()
  local cnt = 0 ;
  
  oq.bntoons() ;
  for name,v in pairs(OQ_data.bn_friends) do
    if (v.isOnline and (v.presenceID ~= 0) and v.oq_enabled) then
      cnt = cnt + 1 ;
    end
  end
  
  -- update the label on tab 5
  local nlocals = oq.n_channel_members( "OQgeneral" ) ;
  if (nlocals > 0) then
    nlocals = nlocals - 1 ; -- subtract player
  end
  local ntotal, nonline = BNGetNumFriends() ;
  return nlocals, cnt, ntotal ;
end

function oq.n_connections()
  local nOQlocals, nOQfriends, nBNfriends = oq.get_nConnections() ;
  if (oq.loaded) then
    oq.tab2_nfriends:SetText( string.format( OQ.BNET_FRIENDS, nBNfriends ) ) ; 
    oq.tab2_connection:SetText( string.format( OQ.CONNECTIONS, nOQlocals, nOQfriends )) ;
  end
end

function oq.bnpresence( name )
  oq.bntoons() ;
  name = strlower(name) ; -- make sure
  for i,v in pairs(OQ_data.bn_friends) do
    if (name == strlower(i)) then
      if (not v.isOnline) or ((not v.oq_enabled) and (not v.sk_enabled)) then
        return 0 ;
      else
        return v.presenceID or 0 ;
      end
    end
  end
  return 0 ;
  
--  local friend = OQ_data.bn_friends[ name ] ;
--  if (friend == nil) or ((not friend.oq_enabled) and (not friend.sk_enabled)) or (not friend.isOnline) then
--    return 0 ;
--  end
--  return friend.presenceID or 0 ;
end

function oq.mbsync_toons( to_name )
  for ndx,friend in pairs( OQ_data.bn_friends ) do
    if ((friend.presenceID ~= 0) and friend.isOnline and friend.oq_enabled) then
      local m = "OQ,".. 
                OQ_VER ..",".. 
                "W1,"..
                OQ_TTL ..","..
                "mbox_bn_enable,".. 
                friend.toonName ..","..
                tostring(oq.realm_cooked( friend.realm )) ..","..
                tostring(1) ;
      oq.whisper_msg( to_name, player_realm, m ) ;
    end
  end
end

function oq.mbsync_single( toonName, toonRealm ) 
  for i,v in pairs(OQ_toon.my_toons) do
    local m = "OQ,".. 
              OQ_VER ..",".. 
              "W1,"..
              OQ_TTL ..","..
              "mbox_bn_enable,".. 
              toonName ..","..
              tostring(oq.realm_cooked( toonRealm )) ..","..
              tostring(1) ;
    oq.whisper_msg( v.name, player_realm, m ) ;
  end
end

function oq.mbsync()
  for i,v in pairs(OQ_toon.my_toons) do
    oq.mbsync_toons( v.name ) ;
  end
end

function oq.on_mbox_bn_enable( name, realm, is_enabled )
  oq.bntoons() ;
  if (is_enabled == "0") then
    is_enabled = nil ;
  else
    is_enabled = true ;
  end
  realm = oq.realm_uncooked(realm) ;
  local friend = OQ_data.bn_friends[ name .."-".. realm ] ;
  if (friend == nil) then
    OQ_data.bn_friends[ name .."-".. realm ] = {} ;
    friend = OQ_data.bn_friends[ name .."-".. realm ] ;
    friend.isOnline      = nil ;
    friend.toonName      = name ;
    friend.realm         = realm ;
    friend.presenceID    = 0 ;
    return ;
  end
  friend.oq_enabled    = is_enabled ;
end

-- notify multi-box toons on same b-net that the toon is bn-enabled
--
function oq.mbnotify_bn_enable( name, realm, is_enabled ) 
  if (OQ_toon.my_toons == nil) or (#OQ_toon.my_toons == 0) then
    return ;
  end

  local m = "OQ,".. 
            OQ_VER ..",".. 
            "W1,"..
            OQ_TTL ..","..
            "mbox_bn_enable,".. 
            name ..","..
            tostring(oq.realm_cooked( realm )) ..","..
            (is_enabled or 1) ;

  for i,v in pairs(OQ_toon.my_toons) do
    oq.whisper_msg( v.name, player_realm, m ) ;
  end
end

-- returns first pid of a toon on the desired realm
function oq.bnpresence_realm( realm ) 
  if (realm == nil) then
    return nil ;
  end
  for i,v in pairs(OQ_data.bn_friends) do
    if (v.realm == realm) and (v.oq_enabled) and (v.isOnline) then
      return v.pid ;
    end
  end
  return 0 ;
end

function oq.bn_echo_msg( name, realm, msg )
  local pid = oq.bnpresence( name .."-".. realm ) ;
  if (pid == 0) then
    return ;
  end
  if (oq.bn_ok2send( msg, pid )) then
    oq.BNSendWhisper( pid, msg, name, realm ) ;
  end
end

function oq.bn_echo_raid( msg )
  if (oq.raid.raid_token == nil) then
    return ;
  end
  for i=1,8 do
    for j=1,5 do
      if (oq.raid.group[i].member) then
        local m = oq.raid.group[i].member[j] ;
        if (m) and (m.name) and (m.realm) and (m.realm ~= player_realm) then
          oq.bn_echo_msg( m.name, m.realm, msg ) ;
        end
      end
    end
  end
end

function oq.check_pending_invites()
  if ((oq.pending_invites == nil) or _inside_bg) then
    return ;
  end
  
  for name,v in pairs(oq.pending_invites) do
    local friend = OQ_data.bn_friends[ name ] ;
    if (friend ~= nil) then
      if (not friend.oq_enabled) then
        oq.mbnotify_bn_enable( friend.toonName, friend.realm, 1 ) ; 
      end
      friend.oq_enabled = true ; -- they got on the invite-list, must be enabled
      InviteUnit( name ) ;
      oq.timer_oneshot( 2.0, oq.brief_group_members ) ;  
      oq.pending_invites[ name ] = nil ;
    end
  end
end

function oq.bn_check_online()
  next_bn_check = 0 ; -- force check
  oq.bntoons() ; 
  oq.n_connections() ; -- should update the connection info on the find-premade tab
end

function oq.set_bn_enabled( pid ) 
  -- find author in OQ_data.bn_friends and set him oq_enabled
  -- lot of work per msg.  how to reduce?  (another table??)
  -- 
  oq.bntoons() ;
  if (OQ_data.bn_friends == nil) then
    return ;
  end
  
  for name,friend in pairs(OQ_data.bn_friends) do
    if (friend.presenceID == pid) then
      if (not friend.oq_enabled) then 
        oq.mbnotify_bn_enable( friend.toonName, friend.realm, 1 ) ;      
      end
      friend.oq_enabled = true ;
    end
  end
end

function oq.bn_clear()
  tbl.clear( OQ_data.bn_friends ) ;
  next_bn_check = 0 ;
  oq.bntoons() ; -- have lost all OQ enabled friends
end

function oq.bn_force_verify()
  next_bn_check = 0 ; -- force the check
  oq.bntoons() ;  
end

function oq.remove_friend_by_pid( pid, btag, givenName, option, why )
  if (option == "show") or (option == "list") then
    print( OQ_DIAMOND_ICON .."  ".. tostring(btag or givenName) .."  (".. tostring(why) ..")" ) ;
    return nil ;
  end
  if (option ~= "silent") then
    print( OQ_DIAMOND_ICON .."  removing ".. btag or givenName .."  (".. tostring(why) ..")" ) ;
  end
  if (OQ_data.bn_friends ~= nil) then
    for n,friend in pairs(OQ_data.bn_friends) do
      if (friend.presenceID == pid) then
        tbl.clear( OQ_data.bn_friends[ n ] ) ;
      end
    end
  end
  BNSetFriendNote( pid, "" ) ;
  BNRemoveFriend( pid ) ;
  return 1 ;
end

local _btags = nil ;
local _btag_ids = nil ;

function oq.show_btags() 
  if (_btags == nil) then
    _btags = tbl.new() ;
  end
  if (_btag_ids == nil) then
    _btag_ids = tbl.new() ;
  end
  local ntotal, nonline = BNGetNumFriends() ;
  tbl.clear( _btags ) ;
  tbl.clear( _btag_ids ) ;
  for i=1,ntotal do
    tbl.fill( _f, BNGetFriendInfo( i ) ) ;

    if (_f[3] ~= nil) then
      _btags[_f[3]] = tbl.new() ;
      _btags[_f[3]].name = _f[2] ;
      _btags[_f[3]].note = _f[13] or "" ;
      table.insert( _btag_ids, _f[3] ) ;
    end
  end  
  table.sort( _btag_ids ) ;  -- names have embedded codes making it impossible to sort by name
  for i,v in pairs(_btag_ids) do
    print( tostring(v) .."  |cFFFFFF00".. tostring(_btags[v].name) .."|r  ".. tostring(_btags[v].note) ) ;
  end
  
  -- cleanup
  for i,v in pairs(_btags) do
    tbl.delete( v ) ;
  end
  _btags = tbl.delete( _btags ) ;
  _btag_ids = tbl.delete( _btag_ids ) ;
end

function oq.dead_token( name, noteText )
  if (noteText:find("OQ,G") == nil) then
    return nil ;
  end 
  if (oq.raid.raid_token == nil) then
    return true ; 
  end
  local token = noteText:sub(4,-1) ;
  if (token == oq.raid.raid_token) then
    return nil ; -- not dead yet
  end
  return true ; -- dead token
end

function oq.remove_OQadded_bn_friends( option )
  local ntotal, nonline = BNGetNumFriends() ;
  local now = utc_time() ;
  local removal_text = "REMOVE ".. OQ_HEADER ;
  for i=ntotal,1,-1 do
    tbl.fill( _f, BNGetFriendInfo( i ) ) ;

    local presenceID = _f[1] ;
    local givenName  = _f[2] ;
    local btag       = _f[3] ;
    local noteText   = _f[13] or "" ;
    -- remove this friend from OQ_data if noted
    if (noteText == "REMOVE OQ") or (noteText == "OQ,mesh node") or oq.dead_token(givenName, noteText) then
      oq.remove_friend_by_pid( presenceID, btag, givenName, option, "group member" ) ;
    elseif (noteText == "OQ,leader") and (oq.raid.raid_token == nil) then
      oq.remove_friend_by_pid( presenceID, btag, givenName, option, "group leader" ) ;
    elseif ((noteText == "") and oq.in_btag_cache( btag )) then
      oq.remove_friend_by_pid( presenceID, btag, givenName, option, "mesh auto-add" ) ;
    end
  end  
  if (option ~= "show") and (option ~= "list") then
    oq.clear_btag_cache() ; -- clear the btag cache so it can start fresh
  end
  oq.bn_check_online() ;
end

function oq.is_enabled(toonName, realm)
  local n = toonName .."-".. realm ;
  if (OQ_data.bn_friends[ n ] == nil) then
    return nil ;
  end
  return OQ_data.bn_friends[ n ].oq_enabled ;
end

function oq.bn_show_pending()
  if (oq.pending_invites == nil) then
    print( "pending list is empty" ) ;
    oq.pending_invites = tbl.new() ;
  else
    print( "pending ---" ) ;
    for i,v in pairs(oq.pending_invites) do
      print( i .." raid( ".. i ..".".. v.gid ..".".. v.slot ..") ".. v.rid ) ;
    end
    print( "--- total: ".. #oq.pending_invites ) ;
  end

  if (oq.waitlist == nil) then
    print( "wait list is empty" ) ;
    oq.waitlist = tbl.new() ;
  else  
    print( "waiting ---" ) ;
    for i,v in pairs(oq.waitlist) do
      print( "[".. i .."] [".. v.name .."-".. v.realm .."] [".. v.realid .."]" ) ;
    end
    print( "--- total: ".. #oq.waitlist ) ;
  end
end

function oq.announce( msg, to_name, to_realm )
  if ((msg == nil) or OQ_toon.disabled) then
    return ;
  end
  if (to_name ~= nil) then
    if (to_realm == player_realm) then
      local msg_tok = "W".. oq.token_gen() ;
      oq.token_push( msg_tok ) ;
      m = "OQ,".. OQ_VER ..",".. msg_tok ..",".. OQ_TTL ..",".. msg ;
      oq.SendAddonMessage( "OQ", m, "WHISPER", to_name ) ;
      return ;
    end
    -- try to go direct if pid exists
    local pid = oq.bnpresence( to_name .."-".. to_realm ) ;
    if (pid ~= 0) then
      local msg_tok = "W".. oq.token_gen() ;
      oq.token_push( msg_tok ) ;
      m = "OQ,".. OQ_VER ..",".. msg_tok ..",".. OQ_TTL ..",".. msg ;
      oq.BNSendWhisper( pid, m, to_name, to_realm ) ;
      return ;
    end
    -- if i have a bn-friend on the target realm, bnsend it to them and return
    pid = oq.bnpresence_realm( to_realm ) ;
    if (pid ~= 0) then
      local msg_tok = "A".. oq.token_gen() ;
      oq.token_push( msg_tok ) ;
      m = "OQ,".. OQ_VER ..",".. msg_tok ..",".. OQ_TTL ..",".. msg ;
      oq.BNSendWhisper( pid, m, to_name, to_realm ) ;
      return ;
    end

    msg = msg ..",".. OQ_FLD_TO .."".. to_name ..",".. OQ_FLD_REALM .."".. tostring(oq.realm_cooked( to_realm )) ;
  end
  local msg_tok = "A".. oq.token_gen() ;
  oq.token_push( msg_tok ) ;

  local m = "OQ,".. OQ_VER ..",".. msg_tok ..",".. OQ_TTL ..",".. msg ;

  -- send to raid (which sends to local channel and real-id ppl in the raid)
  oq.announce_relay( m ) ;
end

--
-- message relays
--
function oq.announce_relay( m )
  if (OQ_toon.disabled) then
    return ;
  end
  -- send to general channel
  if (_inc_channel ~= "oqgeneral") and (oq._banned == nil) then
    oq.channel_general( m ) ;
  end

  -- send to raid channels
  if (oq.raid.raid_token ~= nil) then
    oq.raid_announce_relay( m ) ;
  end

  -- send to real-id list for ppl not in the raid (hoping they will forward to their local OQGeneral channel)
  if (_dest_realm == nil) or (_dest_realm ~= player_realm) then
    oq.bnfriends_relay( m ) ;
  end
end

local _tags   = {} ;
local _realms = {} ;
function oq.bnfriends_relay( m )
  oq.bntoons() ; -- just incase the information has changed 
  if (OQ_data.bn_friends == nil) then
    return ;
  end
  local dt = 0.1 ;
  tbl.clear( _tags ) ;
  tbl.clear( _realms ) ;
  local cnt = 1 ;
  for i,v in pairs(OQ_data.bn_friends) do
    if (v.isOnline and v.oq_enabled and v.toonName and v.realm and (v.realm ~= player_realm) and (_realms[v.realm] == nil)) then
      _tags[cnt] = v ;
      cnt = cnt + 1 ;
      _realms[v.realm] = true ;
    end
  end
  if (cnt <= OQ_MAX_RELAY_REALMS) then
    for i,v in pairs(_tags) do
      oq.BNSendWhisper( v.presenceID, m, v.toonName, v.realm ) ;
    end
  else
    tbl.clear( _names ) ;
    for i=1,OQ_MAX_RELAY_REALMS do
      local ndx = random(1,cnt) ;
      local v = _tags[ndx] ;
      if (v ~= nil) and (v.toonName ~= nil) and (_names[v.toonName] == nil) then 
        _names[v.toonName] = true ;
        oq.BNSendWhisper( v.presenceID, m, v.toonName, v.realm ) ;
      end
    end
  end
end

--
--  send to local OQRaid channel then to real-id friends in the raid
--
function oq.raid_announce( msg, msg_tok )
  if (oq.raid.raid_token == nil) then
    -- no raid token means not in a raid
    return ;
  end

  if (msg_tok == nil) then
    -- the 'R' stands for 'raid' and should not be echo'd far and wide
    msg_tok = "R".. oq.token_gen() ;
    oq.token_push( msg_tok ) ;
  end

  local m = "OQ,".. OQ_VER ..",".. msg_tok ..",".. oq.raid.raid_token ..",".. msg ;
  oq.raid_announce_relay( m ) ;
--  oq.bn_echo_raid( m ) ;
end

function oq.raid_announce_relay( m )
  -- if we get here then the message must have come from OUTSIDE the raid/party
  -- 
  if (_inside_bg) then
    oq.SendAddonMessage( "OQ", m, "INSTANCE_CHAT" ) ;
  elseif (oq.raid.type == OQ.TYPE_RBG) or (oq.raid.type == OQ.TYPE_RAID) then
    oq.SendAddonMessage( "OQ", m, "RAID" ) ;
    return ;
  end  
  if (oq.iam_raid_leader() == true) then
    -- send to party leaders
    if (oq.raid.group) then
      for i=1,8 do
        if (oq.raid.group[i]) and (oq.raid.group[i].member) then
          local lead = oq.raid.group[i].member[1] ;
          if ((lead) and (lead.name) and (lead.name ~= "-") and (lead.name ~= player_name) and (lead.realm)) then
            oq.whisper_msg( lead.name, lead.realm, m ) ;
          end
        end
      end
    end
  elseif (oq.iam_party_leader() == true) then
    -- send to raid_leader
    oq.whisper_raid_leader( m ) ;
  else
  end
  -- send to my own party
  oq.channel_party( m ) ;
end

function oq.raid_announce_member( group_id, slot, name, realm, class ) 
  if ((name == nil) or (name == "-")) then
    return ;
  end
  oq.raid_announce( "member,".. group_id ..",".. slot ..",".. tostring(class) ..",".. tostring(name) ..",".. tostring(oq.realm_cooked( realm )) ) ;
end

function oq.party_announce( msg )
  if (oq.raid.raid_token == nil) or (not oq.iam_in_a_party()) then
    return ;
  end
  -- the 'P' stands for 'party' and should not be echo'd far and wide
  msg_tok = "P".. oq.token_gen() ;
  oq.token_push( msg_tok ) ;

  local m = "OQ,".. OQ_VER ..",".. msg_tok ..",".. oq.raid.raid_token ..",".. msg ;
  
  -- send to party channel
  oq.channel_party( m ) ;
end

function oq.bg_announce( msg )
  local m = "OQ,".. 
            OQ_VER ..",".. 
            "W1,"..
            OQ_TTL ..",".. 
            msg ;
  -- this should send to both parties and instance groups and fail silently if either isn't valid
  SendAddonMessage( "OQ", m, "PARTY" ) ;
  oq.pkt_sent:inc() ;
  SendAddonMessage( "OQ", m, "INSTANCE_CHAT" ) ;
  oq.pkt_sent:inc() ;
end

function oq.send_to_group_leads( m ) 
  if (oq.iam_raid_leader()) then  
    for i=2,8 do
      local grp = oq.raid.group[i] ;
      if ((grp.member) and (grp.member[1].name) and (grp.member[1].name ~= "-") and (grp.member[1].realm)) then
        oq.whisper_msg( grp.member[1].name, grp.member[1].realm, m ) ;
      end
    end
  end
end

function oq.boss_announce( msg )
  if (not oq.iam_raid_leader() and not oq.iam_party_leader()) then  
    if (oq.raid.type ~= OQ.TYPE_RBG) and (oq.raid.type ~= OQ.TYPE_RAID) then
      return ;
    end
  end

  -- the 'B' stands for 'bosses' and should not be echo'd 
  local msg_tok = "B".. oq.token_gen() ;
  oq.token_push( msg_tok ) ;

  local m = "OQ,".. OQ_VER ..",".. msg_tok ..",".. oq.raid.raid_token ..",".. msg ;
  
  if (oq.raid.type == OQ.TYPE_RBG) or (oq.raid.type == OQ.TYPE_RAID) then
    if (_inside_bg) then
      oq.SendAddonMessage( "OQ", m, "INSTANCE_CHAT" ) ;
    else
      oq.SendAddonMessage( "OQ", m, "RAID" ) ;
    end
    return ;
  end  
  -- send to bosses
  if (oq.iam_raid_leader()) then  
    oq.send_to_group_leads( m ) ;
  elseif (oq.iam_party_leader()) then
    oq.whisper_raid_leader( m ) ;
  end
end

--
--  ONLY sent by raid leader
--
function oq.raid_disband()
  if (oq.iam_raid_leader()) then
    local token = oq.token_gen() ;
    oq.token_push( token ) ;
    oq.announce( "disband,".. oq.raid.raid_token ..",".. token  ) ;
    oq.tab3_radio_buttons_clear() ; -- clear premade type
    oq.on_disband( oq.raid.raid_token, token, true ) ;
  end
end

function oq.raid_find()
  local now = utc_time() ;
  if ((_last_find_tm + 8) > now) then
    return ; -- too soon.  no more then 1 find per 8 seconds
  end
  _last_find_tm = now ;

  local subtok = string.format( "%04d", utc_time() % 10000 ) ;
  oq.announce( "find,"..
               oq.my_tok .."".. subtok ..","..
               player_faction ..","..
               oq.get_player_level_range() ..","..
               player_realm
             ) ;
end

function oq.raid_join( ndx, bg_type )
  oq.raid_announce( "join,".. ndx ..",".. bg_type ) ;
end

function oq.raid_leave( ndx )
  oq.raid_announce( "leave,".. ndx ) ;
end

function oq.raid_ping()
  local msg_tok = "B".. oq.token_gen() ;
  oq.token_push( msg_tok ) ;
  local m = "OQ,".. OQ_VER ..",".. msg_tok ..",".. oq.raid.raid_token ..",ping,".. oq.my_tok ..",".. GetTime()*1000 ;
--  oq.boss_announce( "ping,".. oq.my_tok ..",".. GetTime()*1000 ) ;
  for i=2,8 do
    local grp = oq.raid.group[i] ;
    if ((grp.member) and (grp.member[1].name) and (grp.member[1].name ~= "-") and (grp.member[1].realm)) then
      oq.whisper_msg( grp.member[1].name, grp.member[1].realm, m, true ) ;
    end
  end
end

function oq.raid_ping_ack( tok, tm )
  oq._sender = nil ; -- must nil to allow send
  if (my_group == 0) then
    local name = _from ;
    local realm = nil ;
    if (_from:find("-")) then
      name  = _from:sub( 1, _from:find("-")-1 ) ;
      realm = _from:sub( _from:find("-")+1, -1 ) ;
      realm = oq.realm_uncooked(realm) ;
    end
    local msg = "ping_ack,".. tok ..",".. tm ..",".. (my_group or 0) ;
    oq.whisper_msg( name, realm, msg ) ;
  else
    local m = "ping_ack,".. tok ..",".. tm ..",".. (my_group or 0) ;
--    oq.boss_announce( "ping_ack,".. tok ..",".. tm ..",".. (my_group or 0) ) ;
    oq.whisper_raid_leader( m ) ;
  end
end

function oq.ping_toon( toon )
  local name = toon ;
  local realm = player_realm ;
  if (toon:find("-")) then
    name = toon:sub( 1, toon:find("-")-1 ) ;
    realm = toon:sub( toon:find("-")+1, -1 ) ;
    realm = oq.realm_uncooked(realm) ;
  end
  oq.whisper_msg( name, realm, "ping,".. oq.my_tok ..",".. GetTime()*1000 ) ;
end

function oq.remove_all_premades()
  tbl.clear( oq.premades ) ;
  for i,v in pairs(oq.tab2_raids) do
    v:Hide() ;
    v:SetParent(nil) ; -- remove from parent's child list
    oq.tab2_raids[i] = nil ; -- erased, but not cleaned up... should be reclaimed
  end
  oq.reshuffle_premades() ;
end

function oq.remove_dead_premades()
  local now = utc_time() ;
  _source = "cleanup" ;
  for i,v in pairs(oq.premades) do
    -- don't remove my own premade
    if (v.raid_token ~= oq.raid.raid_token) then
      -- time since last update 
      if ((now - v.tm) > OQ_PREMADE_STAT_LIFETIME) then
        oq.remove_premade( i ) ;
      end
    end
  end
  _source = nil ;
end

function oq.remove_premade( token )
  if (oq.premades[ token ] ~= nil) then
    -- hold onto the token & b-tag combo incase the user wants to ban the group lead
    if (oq.old_raids == nil) then
      oq.old_raids = {} ;
    end
    if (oq.old_raids[token] == nil) and (oq.premades[token].leader_rid ~= nil) then
      oq.old_raids[token] = { btag = oq.premades[token].leader_rid } ;
    end
    oq.premades[ token ] = tbl.delete( oq.premades[ token ] ) ;
  end
  
  local reshuffle = nil ;
  for i,v in pairs(oq.tab2_raids) do
    if (v.token == token) then
      reshuffle = true ;
      v:Hide() ;
      v:SetParent(nil) ; -- remove the frame from it's parent
      oq.tab2_raids[i] = nil ;   -- erased, but not cleaned up... should be reclaimed
      break ;
    end
  end

  if (reshuffle) then
    oq.reshuffle_premades() ;
  end
end

function oq.compare_premades(a,b)
  if (a == nil) then
    return false ;
  elseif (b == nil) then
    return true ;
  end
  local v1 = oq.tab2_raids[a] ;
  local v2 = oq.tab2_raids[b] ;
  local p1 = oq.premades[ v1.raid_token ] ;
  local p2 = oq.premades[ v2.raid_token ] ;
  if (oq.premade_sort_ascending == nil) then
    p1 = oq.premades[ v2.raid_token ] ;
    p2 = oq.premades[ v1.raid_token ] ;
  end
  if (p1 == nil) then
    return false ;
  elseif (p2 == nil) then
    return true ;
  end
  if (oq.premade_sort == "name") then
    return (strlower(p1.name) < strlower(p2.name)) ;
  end
  if (oq.premade_sort == "lead") then
    return (p1.leader < p2.leader) ;
  end
  if (oq.premade_sort == "level") then
    return (p1.level_range < p2.level_range) ;
  end
  if (oq.premade_sort == "ilevel") then
    return (p1.min_ilevel < p2.min_ilevel) ;
  end
  if (oq.premade_sort == "resil") then
    return (p1.min_resil < p2.min_resil) ;
  end
  if (oq.premade_sort == "mmr") then
    return (p1.min_mmr < p2.min_mmr) ;
  end
  return true ;
end

function oq.qualified( token )
  if (token == nil) then
    return false ;
  end
  local p = oq.premades[ token ] ;
  if (p == nil) then
    return false ;
  end
  if (oq.get_player_level_id() ~= OQ.SHORT_LEVEL_RANGE[p.level_range]) then
    return false ;
  end
  if (oq.get_ilevel() < p.min_ilevel) then
    return false ;
  end
  if (oq.get_resil() < p.min_resil) then
    return false ;
  end
  if (oq.get_best_mmr(p.type) < p.min_mmr) then
    return false ;
  end
  return true ;
end

function oq.premades_of_type( filter_type )
  local nPremades = 0 ;
  if (oq.tab2_raids == nil) then
    return 0 ;
  end
  for n,v in pairs(oq.tab2_raids) do 
    local p = oq.premades[ v.token ] ;
    if (p ~= nil) then
      if ((OQ_data.premade_filter_qualified == 1) and (oq.qualified(p.raid_token))) or (OQ_data.premade_filter_qualified == 0) then
        if ((filter_type == OQ.TYPE_NONE) or (p.type == filter_type)) and oq.pass_filter(p) then
          nPremades = nPremades + 1 ;
        end
      end
    end
  end
  return nPremades ;
end

local _items = {} ;
function oq.reshuffle_premades() 
  local x, y, cx, cy ;
  x  = 15 ;
  y  = 10 ;
  cy = 25 ;
  cx = oq.tab2_list:GetWidth() - 2*x ;

  tbl.clear( _items ) ;
  for n,v in pairs(oq.tab2_raids) do 
    v._isvis = nil ;
    if (OQ_data.premade_filter_qualified == 1) and (not oq.qualified(v.raid_token)) then
      v:Hide() ;
    else
      local p = oq.premades[ v.raid_token ] ;
      if (p ~= nil) and ((OQ_data.premade_filter_type == OQ.TYPE_NONE) or (p.type == OQ_data.premade_filter_type)) and oq.pass_filter(p) then
        v:Show() ;
        v._isvis = true ; 
        local btag = strlower(p.leader_rid) ;
        table.insert(_items, n) ;        
      else
        v:Hide() ;
      end
    end
  end
  oq._npremades = 0 ; 
  table.sort(_items, oq.compare_premades) ;
  for i,v in pairs(_items) do
    oq.setpos( oq.tab2_raids[v], x, y, cx, cy ) ;
    y = y + cy + 1 ;
    oq._npremades = oq._npremades + 1 ;
  end

  oq.tab2_list:SetHeight( max( 15*(cy+2), y + (4*(cy+2)) ) ) ;
  oq.trim_big_list( oq.tab2_scroller ) ;
  oq.update_premade_count() ;
end

function oq.n_waiting()
  local n = 0 ;
  if (oq.tab7_waitlist ~= nil) then
    for i,v in pairs(oq.tab7_waitlist) do
      n = n + v.nMembers ;
    end
  end
  return n ;
end

function oq.find_premade_entry( raid_token )
  local n = 0 ;
  if (oq.tab2_raids ~= nil) then
    for i,v in pairs(oq.tab2_raids) do
      if (v.raid_token == raid_token) then
        return v ;
      end
    end
  end
end

--
-- ban list
-- 
function oq.create_ban_listitem( parent, x, y, cx, cy, btag, reason, ts )
  oq.nthings = (oq.nthings or 0) + 1 ;
  local n = "Banned".. oq.nthings ;
  local f = oq.panel( parent, n, x, y, cx, cy ) ;
  
  f.texture:SetTexture( 0.0, 0.0, 0.0, 1 ) ;

  local x2 = 0 ;
  f.remove_but = oq.button( f, x2, 2,  23, cy-2, "x", function(self) oq.remove_banlist_item( self:GetParent().btag:GetText() ) ; end ) ;
  x2 = x2 + 40 ;
  f.ts   = oq.label ( f, x2, 2, 130, cy, tostring(date("%H:%M %d-%b-%Y", ts)) ) ;
--  f.ts:SetFont(OQ.FONT, 10, "") ;
  f.ts:SetFont(OQ.FONT_FIXED, 9, "") ;
  f.ts:SetTextColor( 1,1,1 ) ;
  x2 = x2 + 130 + 8 ;
  f.btag   = oq.label ( f, x2, 2, 125, cy, btag ) ;
  f.btag:SetFont(OQ.FONT, 10, "") ;
  x2 = x2 + 125 + 4 ;
  f.reason = oq.label ( f, x2, 2, 450, cy, reason ) ;
  f.reason:SetFont(OQ.FONT, 10, "") ;
  f.reason:SetTextColor( 0.9, 0.9, 0.9 ) ;
  f._ts = ts ;
  f:Show() ;
  return f ;         
end

function oq.populate_ban_list() 
  if (OQ_data.banned == nil) then
    OQ_data.banned = {} ;
  end
  local x, y, cx, cy ;
  x = 1 ;
  y = 1 ;
  cx = 200 ;
  cy = 22 ;
  for i,v in pairs(OQ_data.banned) do
    local f = oq.create_ban_listitem( oq.tab6_list, x, y, cx, cy, i, v.reason, v.ts ) ;
    table.insert( oq.tab6_banlist, f ) ;
    y = y + cy ;
  end
  oq.reshuffle_banlist() ;  
end

function oq.compare_banlist( a, b )
  if (a == nil) then
    return false ;
  elseif (b == nil) then
    return true ;
  end
  local v1 = oq.tab6_banlist[a] ;
  local v2 = oq.tab6_banlist[b] ;
  if (oq.banlist_sort_ascending == nil) then
    v1 = oq.tab6_banlist[b] ;
    v2 = oq.tab6_banlist[a] ;
  end

  if (oq.banlist_sort == "ts") then
    return (v1._ts < v2._ts) ;
  end
  if (oq.banlist_sort == "reason") then
  return (strlower(v1.reason:GetText()) < strlower(v2.reason:GetText())) ;
  end
  -- default sort: btag
  return (strlower(v1.btag:GetText()) < strlower(v2.btag:GetText())) ;
end

function oq.sort_banlist( col )
  local order = oq.banlist_sort_ascending ;
  if (oq.banlist_sort ~= col) then
    order = true ;
  else
    if (order) then
      order = nil ;
    else
      order = true ;
    end
  end
  oq.banlist_sort = col ;
  oq.banlist_sort_ascending = order ;
  oq.reshuffle_banlist() ;
end

function oq.reshuffle_banlist() 
  local x, y, cx, cy, n ;
  x  = 20 ;
  y  = 10 ;
  cy = 25 ;
  cx = oq.tab6_list:GetWidth() - 2*x ;

  tbl.clear( _items ) ;
  for n,v in pairs(oq.tab6_banlist) do 
    if (n ~= nil) then 
      table.insert(_items, n) ; 
    end
  end
  table.sort(_items, oq.compare_banlist) ;
  oq._nbanlist = 0 ;
  for i,v in pairs(_items) do
    oq.setpos( oq.tab6_banlist[v], x, y, cx, cy ) ;
    y = y + cy + 2 ;
    oq._nbanlist = oq._nbanlist + 1 ;
  end
  
  oq.tab6_list:SetHeight( max( 15*(cy+2), y + (4*(cy+2)) ) ) ;
end

function oq.remove_all_banlist()
  oq.ban_clearall() ;
  for i,v in pairs(oq.tab6_banlist) do
    v:Hide() ;
    v:SetParent(nil) ;
    oq.tab6_banlist[i] = nil ; -- erased, but not cleaned up... should be reclaimed
  end
  oq.reshuffle_banlist() ;
end

function oq.remove_banlist_item( btag )
  local reshuffle = nil ;
  for i,v in pairs(oq.tab6_banlist) do
    if (v.btag:GetText() == btag) then
      reshuffle = true ;
      v:Hide() ;
      v:SetParent(nil) ;
      oq.tab6_banlist[i] = nil ; -- erased, but not cleaned up... should be reclaimed
      break ;
    end
  end

  if (reshuffle) then
    oq.reshuffle_banlist() ;
  end

  oq.ban_remove( btag ) ;
end

function oq.is_lessthan( a, b )
   if (a == nil) then
      return true ;
   end
   return ((a or 0) < (b or 0)) ;
end
--
-- wait list
--
function oq.compare_waitlist(a,b)
  if (a == nil) then
    return false ;
  elseif (b == nil) then
    return true ;
  end
  local v1 = oq.tab7_waitlist[a] ;
  local v2 = oq.tab7_waitlist[b] ;
  local p1 = oq.waitlist[ v1.token ] ;
  local p2 = oq.waitlist[ v2.token ] ;
  if (oq.waitlist_sort_ascending == nil) then
    v1 = oq.tab7_waitlist[b] ;
    v2 = oq.tab7_waitlist[a] ;
    p1 = oq.waitlist[ v1.token ] ;
    p2 = oq.waitlist[ v2.token ] ;
  end
  if (p1 == nil) then
    return false ;
  elseif (p2 == nil) then
    return true ;
  end
  
  if (oq.waitlist_sort == "bgrp") then
    return (strlower(oq.find_bgroup(p1.realm)) < strlower(oq.find_bgroup(p2.realm))) ;
  end
  if (oq.waitlist_sort == "name") then
    return (strlower(p1.name) < strlower(p2.name)) ;
  end
  if (oq.waitlist_sort == "rlm") then
    return (strlower(p1.realm) < strlower(p2.realm)) ;
  end
  if (oq.waitlist_sort == "level") then
    return (p1.level < p2.level) ;
  end
  if (oq.waitlist_sort == "ilevel") then
    return oq.is_lessthan(p1.ilevel, p2.ilevel) ;
  end
  if (oq.waitlist_sort == "resil") then
    return oq.is_lessthan(p1.resil, p2.resil) ;
  end
  if (oq.waitlist_sort == "mmr") then
    return oq.is_lessthan(p1.mmr, p2.mmr) ;
  end
  if (oq.waitlist_sort == "power") then
    return oq.is_lessthan(p1.pvppower, p2.pvppower) ;
  end
  if (oq.waitlist_sort == "haste") then
    return oq.is_lessthan(p1.haste, p2.haste) ;
  end
  if (oq.waitlist_sort == "mastery") then
    return oq.is_lessthan(p1.mastery, p2.mastery) ;
  end
  if (oq.waitlist_sort == "hit") then
    return oq.is_lessthan(p1.hit, p2.hit) ;
  end
  if (oq.waitlist_sort == "time") then
    return oq.is_lessthan(p1.create_tm, p2.create_tm) ;
  end
  return true ;
end

function oq.reshuffle_waitlist() 
  local x, y, cx, cy, n ;
  x  = 6 ;
  y  = 10 ;
  cy = 25 ;
  cx = oq.tab7_list:GetWidth() - 2*x ;
  n  = 0 ;

  tbl.clear( _items ) ;
  for n,v in pairs(oq.tab7_waitlist) do 
    local btag = strlower(oq.waitlist[v.token].realid) ;
    table.insert(_items, n) ;     
  end
  oq._nwaitlist = 0 ;
 
  table.sort(_items, oq.compare_waitlist) ;
  for i,v in pairs(_items) do
    oq.setpos( oq.tab7_waitlist[v], x, y, cx, cy ) ;
    y = y + cy + 2 ;
    n = n + oq.tab7_waitlist[v].nMembers ;
    oq._nwaitlist = oq._nwaitlist + 1 ;
  end
    
  oq.tab7_list:SetHeight( max( 15*(cy+2), y + (4*(cy+2)) ) ) ;
  
  if (n > 0) then
    OQMainFrameTab6:SetText( string.format( OQ.TAB_WAITLISTN, n ) ) ;
  else
    OQMainFrameTab6:SetText( OQ.TAB_WAITLIST ) ;
  end
end

function oq.remove_all_waitlist()
  tbl.clear( oq.waitlist ) ;
  for i,v in pairs(oq.tab7_waitlist) do
    v:Hide() ;
    v:SetParent(nil) ;
    oq.tab7_waitlist[i] = nil ; -- erased, but not cleaned up... should be reclaimed
  end
  oq.reshuffle_waitlist() ;
end

function oq.send_removed_notice( token ) 
  local r = oq.waitlist[ token ] ;
  if (r ~= nil) then
    oq.timer_oneshot( 1, oq.realid_msg, r.name, r.realm, r.realid, 
                      OQ_MSGHEADER .."".. 
                      OQ_VER ..","..
                      "W1,"..
                      "0,"..
                      "removed_from_waitlist,"..
                      oq.raid.raid_token ..","..
                      token
                    ) ;
  end
end

function oq.reject_all_waitlist()
  for i,v in pairs(oq.tab7_waitlist) do
    oq.send_removed_notice( v.token ) ;
  end
  oq.remove_all_waitlist() ;
end

function oq.remove_waitlist( token )
  local reshuffle = nil ;
  for i,v in pairs(oq.tab7_waitlist) do
    if (v.token == token) then
      reshuffle = true ;
      v:Hide() ;
      v:SetParent(nil) ;
      oq.tab7_waitlist[i] = nil ; -- erased, but not cleaned up... should be reclaimed
      break ;
    end
  end

  if (reshuffle) then
    oq.reshuffle_waitlist() ;
  end

  -- now tell the remote user he has been removed
  oq.send_removed_notice( token ) ;
  
  -- clean up the waitlist  
  if (oq.waitlist[ token ] ~= nil) then
    oq.waitlist[ token ] = nil ;
  end
end

function oq.on_removed_from_waitlist( raid_token, req_token )
  -- set the premade button from 'pending' back to 'waitlist'
  local f = oq.find_premade_entry( raid_token ) ;
  if (f ~= nil) then
    f.req_but:SetText( OQ.BUT_WAITLIST ) ;
    f.req_but:SetBackdropColor( 0.5, 0.5, 0.5, 1 ) ;
    f.pending = nil ;
    if (oq.raid.raid_token == nil) then
      -- sad sound if no group and leaving wait list
      PlaySound( "igQuestFailed" ) ;
    end
  end
  
  -- remove from oq.pending
  oq.pending[ raid_token ] = tbl.delete( oq.pending[ raid_token ] ) ;
end

function oq.on_leave_waitlist( raid_token, req_token )
  if (raid_token ~= oq.raid.raid_token) then
    -- not for me
    return ;
  end
  oq.remove_waitlist( req_token ) ;  
end

function oq.send_leave_waitlist( raid_token )
  if (raid_token == nil) then
    return ;
  end
  local now = utc_time() ;
  local req = oq.pending[ raid_token ] ;
  local raid = oq.premades[ raid_token ] ;
  if (req == nil) or (raid == nil) or (req.next_msg_tm > now) or (req.req_token == nil) then
    return ;
  end
  req.next_msg_tm = now + 5 ;
  
  if (raid_token == oq.raid.raid_token) then
    -- i've joined the raid.  just remove the entry
    oq.pending[ raid_token ] = tbl.delete( oq.pending[ raid_token ] ) ;
    local f = oq.find_premade_entry( raid_token ) ;
    if (f ~= nil) then
      f.req_but:SetText( OQ.BUT_WAITLIST ) ;
      f.req_but:SetBackdropColor( 0.5, 0.5, 0.5, 1 ) ;
      f.pending = nil ;
      if (oq.raid.raid_token == nil) then
        -- sad sound if no group and leaving wait list
        PlaySound( "igQuestFailed" ) ;
      end
    end
  else
    oq.realid_msg( raid.leader, raid.leader_realm, raid.leader_rid, 
                   OQ_MSGHEADER .."".. 
                   OQ_VER ..","..
                   "W1,"..
                   "0,"..
                   "leave_waitlist,"..                 
                   raid_token ..","..
                   req.req_token 
                 ) ;
  end
end

--
-- this is called to remove the player from all waitlists they may have put themselves on
--
function oq.clear_pending()
  for raid_token,req in pairs( oq.pending ) do
    oq.send_leave_waitlist( raid_token ) ;
  end
end

function oq.check_and_send_request( raid_token )
  local in_party = (oq.GetNumPartyMembers() > 0) ;
  local raid  = oq.premades[ raid_token ] ;
  if (raid == nil) then
    return ;
  end
  if (in_party and not UnitIsGroupLeader("player")) then
    StaticPopup_Show("OQ_NotPartyLead", nil, nil, ndx ) ;
    return ;
  end
  if (in_party and (raid.type ~= OQ.TYPE_BG)) then
    StaticPopup_Show("OQ_NoPartyWaitlists", nil, nil, ndx ) ;
    return ;
  end
  if (oq.raid.raid_token ~= nil) then
    if (my_group == 1) and (my_slot == 1) then
      StaticPopup_Show("OQ_NoWaitlistWhilePremadeLead", nil, nil, ndx ) ;
    else
      StaticPopup_Show("OQ_NoWaitlistWhilePremade", nil, nil, ndx ) ;
    end
    return ;
  end
  
  if (raid ~= nil) then
    if (raid.has_pword ~= nil) then
      PlaySoundFile( "Sound\\interface\\KeyRingOpen.wav" ) ;
      local dialog = StaticPopup_Show("OQ_EnterPword") ;
      dialog.data = raid_token ;
    else
      oq.send_req_waitlist( raid_token, "" ) ;
    end
  end
end

function oq.send_req_waitlist( raid_token, pword ) 
  local in_party = (oq.GetNumPartyMembers() > 0) ;
  
  local now = utc_time() ;
  local req = oq.pending[ raid_token ] ;
  if (req == nil) then
    oq.pending[ raid_token ] = tbl.new() ;
    req = oq.pending[ raid_token ] ;
  elseif (req.next_msg_tm) and (req.next_msg_tm > now) then
    -- too soon for resend. no more then once every 5 seconds
    return ;
  end
  req.next_msg_tm = now + 5 ;

  local req_token = req.req_token ;

  if (req_token == nil) then
    req_token = "Q".. oq.token_gen() ;
    req.req_token = req_token ;
    oq.store_my_token( req_token ) ;
  end

  oq.gather_my_stats() ;
  local flags = OQ.FLAG_ONLINE ;
  local raid  = oq.premades[ raid_token ] ;
  _dest_realm = raid.leader_realm ;
  
  if (raid == nil) then
    return ;
  end
  oq.raid.type = raid.type ;
  
  if (player_realm ~= _dest_realm) and (not oq.valid_rid( player_realid )) then
    message( OQ.BAD_REALID .." ".. tostring(player_realid) ) ;
    return ;
  end

  if (in_party) then
    -- must be party leader.  
    local party_avg_ilevel = 0 ;
    local party_avg_resil  = 0 ;  
    local mmr              = oq.get_best_mmr(raid.type) ;
    local pvppower         = oq.get_pvppower() ;
    local stats = oq.encode_short_stats( player_level, player_faction, player_class, party_avg_resil, party_avg_ilevel, player_role, mmr, pvppower, 0 ) ;
    local enc_data = oq.encode_data( "abc123", player_name, player_realm, player_realid ) ;
    oq.realid_msg( raid.leader, raid.leader_realm, raid.leader_rid, 
                   OQ_MSGHEADER .."".. 
                   OQ_VER ..","..
                   "W1,"..
                   "0,"..
                   "ri,"..                 
                   raid_token ..","..
                   tostring(raid.type or 0) ..","..
                   tostring(oq.GetNumPartyMembers()) ..","..
                   req_token ..","..
                   enc_data ..","..
                   stats ..","..
                   oq.encode_pword( pword ) 
                 ) ;
  else
    local mmr                  = oq.get_best_mmr(raid.type) ;
    local pvppower             = oq.get_pvppower() ;
    local class, spec, spec_id = oq.get_spec() ;
    local stats = oq.encode_my_stats( 0, 0, 0, 'A', 'A' ) ;
    local enc_data = oq.encode_data( "abc123", player_name, player_realm, player_realid ) ;

    oq.realid_msg( raid.leader, raid.leader_realm, raid.leader_rid, 
                   OQ_MSGHEADER .."".. 
                   OQ_VER ..","..
                   "W1,"..
                   "0,"..
                   "ri,"..                 
                   raid_token ..","..
                   tostring(raid.type or 0) ..","..
                   "1,"..
                   req_token ..","..
                   enc_data ..","..
                   stats ..","..
                   oq.encode_pword( pword ) 
                 ) ;
  end
end

-------------------------------------------------------------------------------
--   
-------------------------------------------------------------------------------
function oq.bg_name( tid )
  for i,v in pairs(OQ.BG_NAMES) do
    if (v.type_id == tid) then
      return i ;
    end
  end
end

function oq.bg_type_id( name ) 
  if (name == nil) then
    return -1 ;
  end
  if (OQ.BG_NAMES[ name ] == nil) then
    return -2 ;
  end
  return OQ.BG_NAMES[ name ].type_id ;
end

function oq.get_player_level_id() 
  player_level = UnitLevel("player") ; -- the level could have changed since the group was formed
  if (player_level == 90) then
    return OQ.SHORT_LEVEL_RANGE[ "90" ] ;
  elseif (player_level < 10) then
    return OQ.SHORT_LEVEL_RANGE[ "unavailable" ] ;
  end
  local minlevel = floor( player_level / 5) * 5 ;
  local maxlevel = floor((player_level + 5) / 5) * 5 - 1 ;
  return OQ.SHORT_LEVEL_RANGE[ string.format( "%d - %d", minlevel, maxlevel ) ] ;
end

function oq.get_player_level_range() 
  player_level = UnitLevel("player") ; -- the level could have changed since the group was formed
  if (player_level == 90) then
    return 90, 90 ;
  elseif (player_level < 10) then
    return 0,0 ;
  end
  local minlevel, maxlevel ;

  minlevel = floor(player_level / 5) * 5 ;
  maxlevel = floor((player_level + 5) / 5) * 5 - 1 ;

  return minlevel, maxlevel ;
end

function oq.nVisible( type )
  if (type == "banlist") then
    return oq._nbanlist or 0 ;
  elseif (type == "waitlist") then
    return oq._nwaitlist or 0 ;
  elseif (type == "premades") then
    return oq._npremades or 0 ;
  end
  return 0 ;
end

function OQ_ModScrollBar_Update(f)
  local nItems = max( 14, oq.nVisible(f._type) ) ;
  FauxScrollFrame_Update( f, nItems, 5, 25 ) ;
end

function oq.show_version()
  print( "oQueue v".. OQUEUE_VERSION .."  build ".. OQ_BUILD .." (".. tostring(OQ.REGION) ..")".. tostring(OQ_SPECIAL_TAG or "") ) ;
  
  if (player_level > 20) and (oq.get_role() == "None") then
    oq.warning_no_role() ;
  end
end

function oq.hint( button, txt, show )
  if (not show) or (txt == nil) or (txt == "") then
    -- clear & hide the tooltip
    oq.gen_tooltip_hide() ;
    return ;
  end
  oq.gen_tooltip_set( button, txt ) ;
end

function oq.normalize_static_button_height()
  if (HonorFrameSoloQueueButton) then
    if (not HonorFrameSoloQueueButton:IsVisible()) then
      oq.reset_button( HonorFrameSoloQueueButton ) ;
    end
    HonorFrameSoloQueueButton:Show() ;
  end
  if (HonorFrameGroupQueueButton) then
    if (not HonorFrameGroupQueueButton:IsVisible()) then
      oq.reset_button( HonorFrameGroupQueueButton ) ;
    end
    HonorFrameGroupQueueButton:Show() ;
  end

  if (PVPReadyDialogEnterBattleButton and (not PVPReadyDialogEnterBattleButton:IsVisible())) then
    oq.reset_button( PVPReadyDialogEnterBattleButton ) ;
  end
  if (PVPReadyDialogLeaveQueueButton and (not PVPReadyDialogLeaveQueueButton:IsVisible())) then
    oq.reset_button( PVPReadyDialogLeaveQueueButton ) ;
  end
end

function oq.create_alt_listitem( parent, x, y, cx, cy, name )
  oq.nthings = (oq.nthings or 0) + 1 ;
  local n = "Alt".. oq.nthings ;
  local f = oq.panel( parent, n, x, y, cx, cy ) ;

  f.name = name ;
  f.texture:SetTexture( 0.0, 0.0, 0.0, 1 ) ;

  local x2 = 1 ;
  f.remove_but = oq.button( f, x2, 2,  18, cy-2, "x", function(self) oq.remove_alt_listitem( self:GetParent().name ) ; end ) ;
  x2 = x2 + 18+4 ;
  f.toonName  = oq.label( f, x2, 2, 150, cy, name ) ;
  f:Show() ;
  return f ;         
end

function oq.clear_alt_list()
  for i,v in pairs(oq.tab5_alts) do
    v:Hide() ;
    v:SetParent(nil) ;
    oq.tab5_alts[i] = nil ;   -- erased, but not cleaned up... should be reclaimed
  end
  tbl.clear( OQ_toon.my_toons ) ;
end

function oq.remove_alt_listitem( name )
  local reshuffle = nil ;
  for i,v in pairs(oq.tab5_alts) do
    if (v.name == name) then
      reshuffle = true ;
      v:Hide() ;
      v:SetParent(nil) ;
      oq.tab5_alts[i] = nil ;   -- erased, but not cleaned up... should be reclaimed
      break ;
    end
  end
  
  for i,v in pairs(OQ_toon.my_toons) do
    if (v.name == name) then
      OQ_toon.my_toons[i] = nil ;
      break ;
    end
  end

  if (reshuffle) then
    oq.reshuffle_alts() ;
  end
end

function oq.reshuffle_alts() 
  if (oq.tab5_alts == nil) then
    oq.tab5_alts = {} ;
    return ;
  end
    
  local x, y, cx, cy ;
  x  = 20 ;
  y  = 10 ;
  cy = 20 ;
  cx = oq.tab5_list:GetWidth() - 2*x ;
  for i,v in pairs(oq.tab5_alts) do
    oq.setpos( v, x, y, cx, cy ) ;
    y = y + cy + 2 ;
  end
  
  oq.tab5_list:SetHeight( max( 6*(cy+2), y + (1*(cy+2)) ) ) ;
end

function oq.add_toon( toonName ) 
  if (toonName == nil) or (toonName == "") then
    return ;
  end
  if (OQ_toon.my_toons == nil) then
    OQ_toon.my_toons = {} ;
  end
  for i,v in pairs(OQ_toon.my_toons) do
    if (v.name == toonName) then
      return ;
    end
  end

  local d = { name = toonName ; }
  table.insert( OQ_toon.my_toons, d ) ;
  
  -- now update ui
  local f = oq.create_alt_listitem( oq.tab5_list, 1, 1, 200, 22, toonName ) ;
  f.toonName:SetText( toonName ) ;
  table.insert( oq.tab5_alts, f ) ;
  oq.reshuffle_alts() ;  
end

function oq.populate_alt_list() 
  if (OQ_toon.my_toons == nil) then
    OQ_toon.my_toons = {} ;
  end
  local x, y, cx, cy ;
  x = 1 ;
  y = 1 ;
  cx = 200 ;
  cy = 22 ;
  for i,v in pairs(OQ_toon.my_toons) do
    local f = oq.create_alt_listitem( oq.tab5_list, x, y, cx, cy, v.name ) ;
    f.toonName:SetText( v.name ) ;
    y = y + cy ;
    table.insert( oq.tab5_alts, f ) ;
  end
  oq.reshuffle_alts() ;  
end

function oq.populate_waitlist()
  local x, y, cy ;
  x  = 2 ;
  cy = 25 ;
  y  = 10 ;
  for req_token,v in pairs(oq.waitlist) do
    if (v) and (v.name) then
      local f = oq.insert_waitlist_item( x, y, req_token, v.n_members, v.name, v.realm, v ) ;
      table.insert( oq.tab7_waitlist, f ) ;
      y = y + cy ;
    else
      oq.waitlist[ req_token ] = tbl.delete( oq.waitlist[ req_token ] ) ;
    end
  end
  oq.reshuffle_waitlist() ;
end

--------------------------------------------------------------------------
--
--------------------------------------------------------------------------


function oq.getpos( f, p ) 
  if (f == nil) or (f:GetLeft() == nil) then
    return { left = 0, top = 0, width = 10, height = 10 } ;
  end
  if (p == nil) then
    p = tbl.new() ;
  end
  p.left   = ceil( f:GetLeft  () - 0.5 ) ;
  p.top    = ceil( f:GetTop   () - 0.5 ) ;
  p.width  = ceil( f:GetWidth () - 0.5 ) ;
  p.height = ceil( f:GetHeight() - 0.5 ) ;
  if (f:GetParent() ~= UIParent) then
    p.left = ceil( p.left - f:GetParent():GetLeft() - 0.5 ) ;
    p.top  = ceil( p.top  - f:GetParent():GetTop()  - 0.5 ) ;
  end
  p.top = abs( p.top ) ;
  return p ;
end

function oq.center( f ) 
  local x = ceil( ((GetScreenWidth ()-f:GetWidth ())/2) - 0.5) ;
  local y = ceil( ((GetScreenHeight()-f:GetHeight())/2) - 0.5) ;
  f:SetPoint("TOPLEFT",UIParent,"TOPLEFT", x, -1 * y)
  return f ;
end

function oq.make_big( f )
  if (_inside_bg) or (f == nil) then
    return ;
  end
  f._was_vis = f:IsVisible() ;
  if (not f:IsVisible()) then
    f:Show() ;
  end
  if (f._is_big) then
    return ;
  end
  f._is_big          = true ;
  f._original_pos    = oq.getpos( f, f._original_pos) ;
  f._original_level  = f:GetFrameLevel() ;
  f:SetFrameLevel( 99 ) ;
  f:ClearAllPoints() ;
  if (f:IsEnabled()) then
    f._original_enable = 1 ;
  else
    f._original_enable = 0 ;
  end
  f:Enable() ;
  oq.center( oq.setpos( f, 100, 100, 300, 300 ) ) ;
  
end

function oq.reset_button( f )
  if (not f._is_big) then
    return ;
  end
  if (f._original_pos ~= nil) then
    local o = f._original_pos ;
    oq.setpos( f, o.left, o.top, o.width, o.height ) ;
  end
  if (f._original_level) then
    f:SetFrameLevel( f._original_level ) ;
  end
  if (f._was_vis) then
    f:Show() ;
  else
    f:Hide() ;
  end
  if (f._original_enable == 0) then
    f:Disable() ;
  else
    f:Enable() ;
  end
  f:SetScript("PostClick", function(self) end ) ;
  f._is_big = nil ;
end

function oq.quit_raid() 
  if (not _inside_bg) then
    local dialog = StaticPopup_Show("OQ_QuitRaidConfirm") ;
  end
end

function oq.raid_cleanup_slot( i, j )
  if (j == 1) then
    oq.raid.group[i]._last_ping     = nil ;
    oq.raid.group[i]._names         = nil ;
    oq.raid.group[i]._stats         = nil ;
    oq.raid.group[i].member[1].lag  = nil ;   
  end
  oq.set_group_member( i, j, nil, nil, "XX", nil, "0", "0" ) ;
  oq.set_role( i, j, OQ.ROLES["NONE"] ) ;
end

function oq.ui_raidleader()  
  oq.tab1_quit_button:SetText( OQ.DISBAND_PREMADE ) ;
  oq.tab1_readycheck_button:Show() ;
  OQMainFrameTab6:Show() ;
end

function oq.ui_player()
  if (oq.raid.raid_token) and (oq.iam_raid_leader()) then
    oq.ui_raidleader() ;
    return ;
  end

  oq.tab1_quit_button:SetText( OQ.LEAVE_PREMADE ) ;
  oq.tab1_readycheck_button:Hide() ;
  OQMainFrameTab6:Hide() ;
end

function oq.raid_cleanup()
  -- leave party
  if (oq.iam_in_a_party()) then
    oq._error_ignore_tm  = GetTime() + 5 ;
    -- not leaving party... allowing the user to control leaving group
--    LeaveParty() ;
  end

  for i=1,8 do
    for j=1,5 do
      oq.raid_cleanup_slot( i, j ) ;
    end
  end
  oq.tab3_create_but:SetText( OQ.CREATE_BUTTON ) ;
  oq.tab1_name :SetText( "" ) ;
  oq.tab1_notes:SetText( "" ) ;
  oq.tab1_raid_stats:SetText( "" ) ;

  -- update status 
  if (oq._last_raid_token == nil) then
    oq._last_raid_token = oq.raid.raid_token ;
  end
  local raid = oq.premades[ oq._last_raid_token ] ;
  if (raid ~= nil) then
    local s = raid.stats ;
    local line = oq.find_premade_entry( oq._last_raid_token ) ;
    if (line ~= nil) then
      if (s.status == 2) then -- if inside, disable the waitlist button
        line.req_but:Disable() ;
      else
        line.req_but:Enable() ;
      end
    end  
  end
  
  -- clear settings
  tbl.clear( oq.raid ) ;
  oq.raid.group = tbl.new() ;
  for i=1,8 do
    oq.raid.group[i] = tbl.new() ;
    oq.raid.group[i].member = tbl.new() ;
    for j=1,5 do
      oq.raid.group[i].member[j] = tbl.new() ;
      oq.raid.group[i].member[j].flags = 0 ;
      oq.raid.group[i].member[j].charm = 0 ;
      oq.raid.group[i].member[j].check = OQ.FLAG_CLEAR ;
      oq.raid.group[i].member[j].bg = tbl.new() ;
      for k=1,2 do
        oq.raid.group[i].member[j].bg[k] = tbl.new() ;
        oq.raid.group[i].member[j].bg[k].start_tm   = 0 ;
        oq.raid.group[i].member[j].bg[k].queue_ts   = 0 ;
        oq.raid.group[i].member[j].bg[k].confirm_tm = 0 ;
        oq.raid.group[i].member[j].bg[k].status     = "0" ;
      end
    end
  end

  tbl.clear( oq.waitlist ) ;
  my_group      = 0 ;
  my_slot       = 0 ;

  -- remove raid-only procs
--  oq.set_premade_type( OQ.TYPE_BG ) ;
  oq.procs_no_raid() ;
  
  oq.ui_player() ;
  
  -- reset buttons
  PVPReadyDialogEnterBattleButton:Show() ;
  PVPReadyDialogLeaveQueueButton :Show() ;
  PVPReadyDialogEnterBattleButton:Enable() ;
  PVPReadyDialogLeaveQueueButton :Enable() ;
end

function oq.quit_raid_now() 
  -- 
  -- clear out raid settings
  --
  oq.raid_announce( "leave_slot,".. my_group ..",".. my_slot ) ;
  oq.raid_disband() ;  -- only triggers if i am raid leader

  -- clean up raid tab
  oq.raid_cleanup() ;
  oq.remove_all_waitlist() ;
end

function oq.accept_group_leader( req_token, group_id )
  local r = oq.waitlist[ req_token ] ;
  if (r == nil) then
    print( "unable to locate req_token ".. req_token ..".  invite failed" ) ;
    return ;
  end

  oq.set_group_member( group_id, 1, r.name, r.realm, r.class, r.realid ) ;
end

function oq.InviteUnit( name, realm )
  if (realm == nil) or (realm == player_realm) then
    InviteUnit( name ) ;
  else
    InviteUnit( name .."-".. realm ) ;
  end
end

local _ninvites = 0 ;
function oq.invite_group_leader( req_token, group_id )
  local r = oq.waitlist[ req_token ] ;  
  if (r == nil) then
    -- wasn't my request
    return ;
  end

  -- the 'W' stands for 'whisper' and should not be echo'd far and wide
  local msg_tok = "W".. oq.token_gen() ;
  oq.token_push( msg_tok ) ;
  local enc_data = oq.encode_data( "abc123", oq.raid.leader, oq.raid.leader_realm, oq.raid.leader_rid ) ;
  local msg = "invite_group_lead,"..  
              req_token ..",".. 
              group_id ..",".. 
              oq.encode_name( oq.raid.name ) ..",".. 
              oq.raid.leader_class  ..",".. 
              enc_data ..",".. 
              oq.raid.raid_token ..","..
              oq.encode_note( oq.raid.notes ) ;

  -- if i'm already b-net friends or the player is on my realm, just send msg
  local pid = oq.bnpresence( r.name .."-".. r.realm ) ;
  if (pid ~= 0) or (player_realm == r.realm) then
    oq.realid_msg( r.name, r.realm, r.realid, msg ) ;
    oq.remove_waitlist( req_token ) ;
    return ;
  end
  
  -- if reaches here, player is not b-net friend or not on realm... must b-net friend then invite
  if (oq.iam_raid_leader() and (player_realm ~= r.realm)) then
    oq.bn_realfriend_invite( r.name, r.realm, r.realid, "#tok:".. req_token ..",#lead" ) ;
  end

  _ninvites = _ninvites + 1 ;
  oq.timer( "invite_to_group".. _ninvites, 2, oq.timer_invite_group, true, req_token, msg, true ) ;
end

function oq.timer_invite_group( req_token, msg, is_lead )
  local r = oq.waitlist[ req_token ] ;
  if (r == nil) then
    return true ; -- this will remove the timer
  end
  next_bn_check = 0 ; -- force the refresh
  local pid, online = oq.is_bnfriend( r.realid, r.name, r.realm ) ;
  if (pid == nil) then
    -- not friended yet
    if (r.attempts == nil) then
      r.attempts = 1 ;
    else
      r.attempts = r.attempts + 1 ;
    end
    if (r.attempts > 8) then
      print( "B.net has not friended ".. r.name .."-".. r.realm .." (".. tostring(r.realid) ..").  Giving up." ) ;
      return true ; -- this will remove the timer
    end
    return ;
  end

  oq.realid_msg( r.name, r.realm, r.realid, msg ) ;
  if (not is_lead) then
    oq.InviteUnit( r.name, r.realm ) ;
  end
  oq.remove_waitlist( req_token ) ;
  return true ; -- this will remove the timer
end

function oq.is_in_group( name, realm )
  local n = name ;
  if (realm ~= player_realm) then
    n = n .."-".. realm ;
  end
  return UnitInParty( n ) ;
end

function oq.timer_invite_group_member( name, realm, rid_, msg, group_id, slot_, req_token_ )
  if (oq.is_in_group( name, realm )) then
    oq.pending_invites[ name .."-".. realm ] = nil ;
    return ;
  end
  next_bn_check = 0 ; -- force the refresh
  local pid = oq.bnpresence( name .."-".. realm ) ;
  if (pid == 0) then
    -- not friended yet
    local r = oq.pending_invites[ name .."-".. realm ] ;
    if (r == nil) then
      -- table leak when deleted
      oq.pending_invites[ name .."-".. realm ] = { raid_tok = oq.raid.raid_token, gid = group_id, slot = slot_, rid = rid_, req_token = req_token_ } ;
      r = oq.pending_invites[ name .."-".. realm ] ;
    end
    if (r.attempts == nil) then
      r.attempts = 1 ;
    else
      r.attempts = r.attempts + 1 ;
    end
    if (r.attempts == 5) then
      oq.bn_realfriend_invite( name, realm, rid_, "#tok:".. req_token_ ..",#grp:".. group_id ..",#nam:".. player_name .."-".. tostring(oq.realm_cooked(player_realm)) ) ; 
    elseif (r.attempts > 8) then
      print( "B.net has not friended ".. name .."-".. realm .." (".. tostring(rid_) ..").  Giving up." ) ;
      oq.pending_invites[ name .."-".. realm ] = nil ;
      return true ; -- this will remove the timer
    end
    return ;
  end
  
  oq.realid_msg( name, realm, rid_, msg ) ;
  oq.timer_oneshot( 1.5, oq.InviteUnit, name, realm ) ;
  oq.timer_oneshot( 3.5, oq.brief_group_members ) ;  
  oq.pending_invites[ name .."-".. realm ] = nil ;
  return true ; -- this will remove the timer
end

function oq.find_first_available_slot( p ) 
  if (p ~= nil) then
    -- check to see if player already assigned a slot
    for i=1,8 do
      for j=1,5 do
        if ((oq.raid.group[i].member[j].name == p.name) and (oq.raid.group[i].member[j].realm == p.realm)) then
          oq.raid.group[i].member[j].charm = 0 ; 
          oq.raid.group[i].member[j].check = OQ.FLAG_CLEAR ;
          return i, j ;
        end
      end
    end
  end
  for i=1,8 do
    for j=1,5 do
      if ((oq.raid.group[i].member[j].name == nil) or (oq.raid.group[i].member[j].name == "-")) then
        oq.raid.group[i].member[j].name  = p.name  ; -- reserve spot so we don't get overlap due to slow messaging
        oq.raid.group[i].member[j].realm = p.realm ; 
        oq.raid.group[i].member[j].class = "XX" ; 
        oq.raid.group[i].member[j].charm = 0 ; 
        oq.raid.group[i].member[j].check = OQ.FLAG_CLEAR ;
        return i, j ;
      end
    end
  end
  return 0, 0 ;
end

function oq.find_first_available_group( p ) 
  if (p ~= nil) then
    -- check to see if player already assigned a slot
    for i=1,8 do
      if ((oq.raid.group[i].member[1].name == p.name) and (oq.raid.group[i].member[1].realm == p.realm)) then
        return i ;
      end
    end
  end
  for i=1,8 do
    if ((oq.raid.group[i].member[1].name == nil) or (oq.raid.group[i].member[1].name == "-")) then
      return i ;
    end
  end
  return 0, 0 ;
end

function oq.group_invite_slot( req_token, group_id, slot ) 
  if (not oq.iam_raid_leader()) then
    -- not possible
    return ;
  end
  --
  -- slot will NOT be 1
  --
  local r = oq.waitlist[ req_token ] ;
  
  if (r == nil) then
    oq.remove_waitlist( req_token ) ;
    return ;    
  end
  if (r.realid == nil) then
    oq.remove_waitlist( req_token ) ;
    return ;    
  end
  
  group_id = tonumber( group_id ) ;
  slot     = tonumber( slot ) ;
  
  if ((oq.raid.type ~= OQ.TYPE_RBG) and (oq.raid.type ~= OQ.TYPE_RAID) and (group_id ~= my_group)) then
    -- proxy_invite needed
    oq.proxy_invite( group_id, slot, r.name, r.realm, r.realid, req_token ) ;
    oq.timer( "brief_leader", 1.5, oq.brief_group_lead, nil, group_id ) ;
    oq.remove_waitlist( req_token ) ;
    return ;
  end
  
  -- the 'W' stands for 'whisper' and should not be echo'd far and wide
  local msg_tok = "W".. oq.token_gen() ;
  local g_leader_rid = oq.raid.group[ group_id ].member[1].realid ;
  if (g_leader_rid == nil) then
    g_leader_rid = OQ_NOEMAIL ;
  end

  oq.token_push( msg_tok ) ;
  local enc_data = oq.encode_data( "abc123", oq.raid.leader, oq.raid.leader_realm, oq.raid.leader_rid ) ;
  local msg = "invite_group,"..  
              req_token ..",".. 
              group_id ..",".. 
              slot ..",".. 
              oq.encode_name( oq.raid.name ) ..",".. 
              oq.raid.leader_class  ..",".. 
              enc_data ..",".. 
              oq.raid.raid_token ..","..
              oq.encode_note( oq.raid.notes ) ;

  -- if i'm already b-net friends or the player is on my realm, just send msg
--  local pid = oq.bnpresence( r.name .."-".. r.realm ) ;
  local pid, online = oq.is_bnfriend( r.realid, r.name, r.realm ) ;
  if ((pid ~= nil) and (pid ~= 0)) or (player_realm == r.realm) then
    oq.realid_msg( r.name, r.realm, r.realid, msg ) ;
    oq.InviteUnit( r.name, r.realm ) ;
    oq.remove_waitlist( req_token ) ;
    return ;
  end
  -- if reaches here, player is not b-net friend or not on realm... must b-net friend then invite
  oq.bn_realfriend_invite( r.name, r.realm, r.realid, "#tok:".. req_token ..",#grp:".. my_group ..",#nam:".. player_name .."-".. tostring(oq.realm_cooked(player_realm)) ) ; 

  _ninvites = _ninvites + 1 ;
  oq.timer( "invite_to_group".. _ninvites, 2, oq.timer_invite_group, true, req_token, msg ) ;
end

function oq.group_invite_first_slot_in( req_token, group_id ) 
  if (not oq.iam_raid_leader()) then
    -- not possible
    return ;
  end
  local r = oq.waitlist[ req_token ] ;
  
  group_id = tonumber( group_id ) ;
  local slot = oq.first_slot_in_group( group_id ) ;
  if (slot == 0) then
    print( "[oq.group_invite_first_slot_in]  no slots available" ) ;
    return ;
  end
  if (slot == 1) then
    oq.invite_group_leader( req_token, group_id ) ;
  else
    oq.group_invite_slot( req_token, group_id, slot ) ;
  end
end

function oq.group_invite_first_available( req_token ) 
  if (not oq.iam_raid_leader()) then
    -- not possible
    return ;
  end
  local r = oq.waitlist[ req_token ] ;
  
  local group_id, slot = oq.find_first_available_slot( r ) ;
  if (group_id == 0) then
    print( "[oq.group_invite_first_available]  no slots available" ) ;
    return ;
  end
  if (slot == 1) then
    oq.invite_group_leader( req_token, group_id ) ;
  else
    oq.group_invite_slot( req_token, group_id, slot ) ;
  end
end

function oq.group_invite_party( req_token ) 
  local r = oq.waitlist[ req_token ] ;

  local group_id = oq.find_first_available_group( r ) ;
  if (group_id == 0) then
    print( "[oq.group_invite_party]  no empty groups available" ) ;
    return ;
  end

  -- if i'm raid leader, all group leaders must be real-id friends if not on the same realm
  if (oq.iam_raid_leader() and (player_realm ~= r.realm)) then
    oq.realid_msg( r.name, r.realm, r.realid, "#tok:".. req_token ..",#lead" ) ;
  end

  -- the 'W' stands for 'whisper' and should not be echo'd far and wide
  local msg_tok = "W".. oq.token_gen() ;
  oq.token_push( msg_tok ) ;
  local enc_data = oq.encode_data( "abc123", oq.raid.leader, oq.raid.leader_realm, oq.raid.leader_rid ) ;
  local msg = "invite_group_lead,"..  
              req_token ..",".. 
              group_id ..",".. 
              oq.encode_name( oq.raid.name ) ..",".. 
              oq.raid.leader_class  ..",".. 
              enc_data ..",".. 
              oq.raid.raid_token ..","..
              oq.encode_note( oq.raid.notes ) ;

  local m = "OQ,".. OQ_VER ..",".. msg_tok ..",0,".. msg ;
  -- do not call direct, as the bnfriend invite may not be completed yet
  oq.timer_oneshot( 3.5, oq.realid_msg, r.name, r.realm, r.realid, m ) ;
  oq.timer_oneshot( 4.0, oq.brief_group_lead, group_id ) ;

  oq.remove_waitlist( req_token ) ;
end

function oq.make_dropdown_03( button, req_token)
  oq.menu_create()  
  for i=1,8 do
    if ((oq.raid.group[i].member[1] == nil) or (oq.raid.group[i].member[1].name == nil) or (oq.raid.group[i].member[1].name == "-")) then
      oq.menu_add( "group ".. i, 
                   tostring(i), 
                   req_token, 
                   nil, 
                   function(self,arg1,arg2) oq.invite_group_leader( arg2, arg1 ) ; return true ; end
                 ) ;

    end
  end
  oq.menu_show( button, "TOPLEFT", 2, -25, "BOTTOMLEFT", button:GetWidth()+10 ) ;
end

function oq.first_slot_in_group( g_id )
  if (g_id < 1) or (g_id > 8) then
    return ;
  end
  for i=1,5 do
    local mem = oq.raid.group[g_id].member[i] ;
    if ((mem == nil) or (mem.name == nil) or (mem.name == "-")) then
      mem.charm = 0 ;
      mem.check = OQ.FLAG_CLEAR ;
      return i ;
    end
  end
end

function oq.make_dropdown_04( button, req_token )
  oq.menu_create()  
  for i=1,8 do
    local slot = oq.first_slot_in_group( i ) ;
    if (slot) then
      oq.menu_add( "group ".. i, 
                   tostring(i), 
                   req_token, 
                   nil, 
                   function(self,arg1,arg2) oq.group_invite_first_slot_in( arg2, arg1 ) ; return true ; end
                 ) ;
    end
  end
  oq.menu_show( button, "TOPLEFT", 2, -25, "BOTTOMLEFT", button:GetWidth()+10 ) ;
end

--
-- name to whisper.  could be real-id, could be on leader's realm
--
function oq.on_remove( g_id, slot )
  -- remove from cell
  g_id = tonumber( g_id ) ;
  slot = tonumber( slot ) ;
  if ((my_group == g_id) and (my_slot == slot)) then
    -- remove myself
    oq.quit_raid_now() ;
    if (slot ~= 1) then
      LeaveParty() ;
    end
  elseif ((my_group == g_id) and (my_slot == 1)) then
    -- OQ leader asking me, the group lead, to kick someone
    local mem = oq.raid.group[g_id].member[slot] ;
    local n = mem.name ;
    if (player_realm ~= mem.realm) then
      n = n .."-".. mem.realm ;
    end
    -- requires a hardware event since 3.3.5... won't work and would produce a lua violation error
--      UninviteUnit( n ) ;
  elseif (slot == 1) then
    -- removing group lead, which removes entire group
    oq.on_remove_group( g_id ) ;
  end
end

function oq.on_remove_group( g_id )
  -- msg ok, remove group
  g_id = tonumber(g_id) ;
  if (my_group == g_id) then
    -- leave raid
    oq.quit_raid_now() ;
  else
    -- clear out group
    for i=1,5 do
      oq.raid_cleanup_slot( g_id, i ) ;
    end
  end  
end

function oq.on_new_lead( raid_token, name, realm, rid ) 
  if (raid_token == nil) or (raid_token ~= oq.raid.raid_token) then
    return ;
  end
  if (name == player_name) then
    -- i am the new oq leader
  elseif (my_slot == 1) then
    -- send real-id request if needed
  end
  -- update oq leader info
  oq.raid.leader       = name ;
  oq.raid.leader_realm = realm ;
  oq.raid.leader_rid   = rid ;
end

function oq.new_oq_leader( name, realm, rid ) 
  oq.raid_announce( "new_lead,"..
                    oq.raid.raid_token ..","..
                    name ..","..  
                    realm ..","..  
                    tostring(rid or "")
                  ) ;
end

function oq.remove_member( g_id, slot ) 
  if (not oq.iam_raid_leader()) then
    return ;
  end
  oq.raid_announce( "remove,"..
                    g_id ..","..
                    slot 
                  ) ;
  if (oq.raid.type == OQ.TYPE_RBG) or (oq.raid.type == OQ.TYPE_RAID) then
    local m = oq.raid.group[ g_id ].member[ slot ] ;
    local n = m.name ;
    if (m.realm ~= player_realm) then
      n = n .."-".. m.realm ;
    end
    UninviteUnit( n ) ;
  end
  -- incase the slot if a group lead that is offline
  oq.on_remove( g_id, slot ) ;
end

function oq.member_left( g_id, slot ) 
  oq.raid_cleanup_slot( g_id, slot ) ;
end

function oq.group_left( g_id )
  oq.on_remove_group( g_id ) ;
end

function oq.remove_group( g_id ) 
  if (not oq.iam_raid_leader()) then
    return ;
  end
  -- cannot remove main group; disband raid to remove the main group
  if (g_id == 1) then
    return ;
  end
  oq.raid_announce( "remove_group,".. g_id ) ;
  oq.on_remove_group( g_id ) ;
end

function oq.on_classdot_enter( self )
  local gid  = self.gid ;
  local slot = self.slot ;
  if (gid == nil) or (slot == nil) then
    return ;
  end
  if (oq.raid.group[gid] == nil) or (oq.raid.group[gid].member[slot] == nil) then
    return ;
  end
  --
  -- generate tooltip 
  -- 
  local m = oq.raid.group[gid].member[slot] ;
  if ((m == nil) or (m.name == nil) or (m.name == "-")) then
    return ;
  end
  oq.tooltip_set2( self, m, nil, ((gid == 1) and (slot == 1)) ) ;
end

function oq.on_classdot_exit( self )
  oq.tooltip_hide() ;
end

function oq.on_ladderdot_enter( self )
  local gid  = self.gid ;
  local slot = self.slot ;
print( "[on_ladderdot_enter] ".. gid .." . ".. slot ) ;
  --
  -- generate tooltip 
  -- 
  local m = oq.raid.group[gid].member[slot] ;
  if ((m == nil) or (m.name == nil) or (m.name == "-")) then
    return ;
  end
  oq.tooltip_set2( self, m ) ;
end

function oq.on_ladderdot_exit( self )
  oq.tooltip_hide() ;
end

function oq.btag_link( desc, name, realm, btag ) 
  local str = "|cFF808080".. 
              desc ..
              "|r |Hbtag:".. 
              tostring(strlower(btag or "")) ..
              ":".. utc_time() ..
              "|h".. 
              tostring(name or "") .."-".. tostring(realm or "") ..
              "|h" ;
  return str ;
end

function oq.btag_link2( desc, name, realm, btag )
  local str = "|Hbtag:".. 
              tostring(strlower(btag)) ..
              ":".. utc_time() ..
              "|h".. 
              tostring(name) .."-".. tostring(realm) ..
              " |cFF808080"..
              desc ..
              "|r |h" ;
  return str ;
end

function oq.on_btag( name, realm_id, rid )
  _ok2relay = 1 ;
  realm_id = tonumber(realm_id) ;
  local loname = strlower(name) ;
  local realm  = oq.realm_uncooked(realm_id) ;
  for i=1,8 do
   if (oq.raid.group[i]) then
      for j=1,5 do
        if (oq.raid.group[i].member) then
          local p = oq.raid.group[i].member[j] ;
          p.name, p.realm_id, p.realm = oq.name_sanity( p.name, p.realm_id ) ;
          
          if (p) and (p.name) and (strlower(p.name) == loname) and (p.realm_id) and (p.realm_id == realm_id) and (rid) then
            p.name, p.realm_id, p.realm = oq.name_sanity( name, realm_id ) ;
            p.realid   = strlower(rid) ;
            return ;
          end
--          if (p) and (p.name) and (p.name == name) and (p.realm) and (p.realm == realm) and (p.realid ~= rid) and (rid) then
--            oq.set_group_member( i, j, p.name, p.realm, p.class, strlower(rid), "0", "0" ) ;
--            return ;
--          end
        end
      end
    end
  end
end

function oq.send_my_btag_to_raid()
  if (my_group == 0) or (my_slot == 0) then
    return ;
  end
  if (player_realid == nil) then
    oq.get_battle_tag() ;
  end
  if (player_realm == nil) then
    player_realm = oq.GetRealmName() ;
  end
  if ((player_realid == nil) or (player_realm == nil)) then
    return ;
  end
  oq.raid_announce( "btag,".. player_name ..",".. oq.realm_cooked(player_realm) ..",".. player_realid ) ;
end

function oq.on_need_btag( name, realm )
  _ok2relay = 1 ;
  if (name == player_name) and (realm == player_realm) and (player_realid ~= nil) then
    oq._sender = nil ; -- clear to allow it to be sent
    oq.raid_announce( "btag,".. player_name ..",".. oq.realm_cooked(player_realm) ..",".. player_realid ) ;
  end
end

function oq.on_classdot_promote( g_id, slot )
  -- promote to group lead
  local m1 = oq.raid.group[g_id].member[1] ;
  local m2 = oq.raid.group[g_id].member[slot] ;
  local req_token = "Q".. oq.token_gen() ;
  oq.token_push( req_token ) ;  -- hang onto it for return
  if (m2.realid == nil) or (m2.realid == "") then
    print( OQ_REDX_ICON .."".. OQ.NOBTAG_01 ) ;
    print( OQ_REDX_ICON .."".. OQ.NOBTAG_02 ) ;
    return ;
  end

  if (g_id == 1) then
    -- push as new oq-leader
    oq.new_oq_leader( m2.name, m2.realm, m2.realid ) ;
    -- need to manually push the promote
    oq.raid_announce( "promote,"..
                      g_id ..","..  
                      m2.name ..","..
                      m2.realm ..","..
                      tostring(m2.realid) ..","..
                      tostring(m2.realm) ..","..
                      req_token
                    ) ;
    oq.on_promote( g_id, m2.name, m2.realm, m2.realid, m2.realm, req_token ) ;
    oq.ui_player() ;
  else
    oq.raid_announce( "promote,"..
                      g_id ..","..  
                      m2.name ..","..
                      m2.realm ..","..
                      player_realid ..","..
                      player_realm ..","..
                      req_token
                    ) ;
  end
  -- update info
  oq.set_group_lead( g_id, m2.name, m2.realm, m2.class, m2.realid ) ;
  oq.set_name      ( g_id, slot, m1.name, m1.realm, m1.class, m1.realid ) ;
end

function oq.is_my_toon( name, realm )
  if (realm ~= player_realm) then
    return nil ;
  end
  name = strlower(name) ;
  for i,v in pairs(OQ_toon.my_toons) do
    if (name == strlower(v.name)) then
      return true ;
    end
  end
  return nil ;
end

function oq.on_classdot_menu_select( g_id, slot, action ) 
  if (action == "promote") then
    local p = oq.raid.group[g_id].member[slot] ;
    if (oq.is_my_toon( p.name, p.realm )) then
      p.realid = player_realid ;
    end
    if (p.realid == nil) or (p.realid == "") then
      -- delay to allow btag to be delivered
      oq.timer_oneshot( 2, oq.on_classdot_promote, g_id, slot ) ;
    else
      oq.on_classdot_promote( g_id, slot ) ;
    end
  elseif (action == "ban") then
    local m = oq.raid.group[ tonumber(g_id) ].member[ tonumber(slot) ] ;
    local dialog = StaticPopup_Show("OQ_BanUser", m.realid) ;
    if (dialog ~= nil) then
      dialog.data2 = { flag = 1, gid = g_id, slot_ = slot } ;
    end
  elseif (action == "upvote") then
    oq.karma_vote( g_id, slot, 1 ) ;
  elseif (action == "dnvote") then
    oq.karma_vote( g_id, slot, -1 ) ;
  elseif (action == "kick") then
    oq.remove_member( g_id, slot ) ;
  end
end

OQ.karma_up = "|TInterface\\BUTTONS\\UI-Scrollbar-ScrollUpButton-Up.blp:22:22:0:0:20:24:0:18:0:18|t";
OQ.karma_dn = "|TInterface\\BUTTONS\\UI-Scrollbar-ScrollDownButton-Up.blp:22:22:0:0:20:24:0:18:0:18|t";

local _dropdown_options = { { val = "promote", f = 0x10, msg = OQ.DD_PROMOTE }, 
                    { val = "spacer" , f = 0x10, msg = "---------------", notClickable = 1 },
                    { val = 1        , f = 0x04, msg = OQ_STAR_ICON       .."  ".. OQ.DD_STAR     },
                    { val = 2        , f = 0x04, msg = OQ_CIRCLE_ICON     .."  ".. OQ.DD_CIRCLE   },
                    { val = 3        , f = 0x04, msg = OQ_BIGDIAMOND_ICON .."  ".. OQ.DD_DIAMOND  },
                    { val = 4        , f = 0x04, msg = OQ_TRIANGLE_ICON   .."  ".. OQ.DD_TRIANGLE },
                    { val = 5        , f = 0x04, msg = OQ_MOON_ICON       .."  ".. OQ.DD_MOON     },
                    { val = 6        , f = 0x04, msg = OQ_SQUARE_ICON     .."  ".. OQ.DD_SQUARE   },
                    { val = 7        , f = 0x04, msg = OQ_REDX_ICON       .."  ".. OQ.DD_REDX     },
                    { val = 8        , f = 0x04, msg = OQ_SKULL_ICON      .."  ".. OQ.DD_SKULL    },
                    { val = 0        , f = 0x04, msg = OQ.DD_NONE },
                    { val = "spacer2", f = 0x20, msg = "---------------", notClickable = 1 },
                    { val = "upvote" , f = 0x08, msg = OQ.TT_KARMA ..":  ".. OQ.karma_up .."  ".. OQ.UP    },
                    { val = "dnvote" , f = 0x08, msg = OQ.TT_KARMA ..":  ".. OQ.karma_dn .."  ".. OQ.DOWN  },
                    { val = "spacer3", f = 0x08, msg = "---------------", notClickable = 1 },
                    { val = "kick"   , f = 0x20, msg = OQ.DD_KICK }, 
                    { val = "ban"    , f = 0x08, msg = OQ.DD_BAN }, 
                  } ;
function oq.make_classdot_dropdown(cell)
  local options = _dropdown_options ;
  local mask = 0x01 ; -- member
  if (my_slot == 1) then  
    mask = mask + 0x02 ;  -- group leader
  end
  if (my_group == 1) and (my_slot == 1) then
    mask = mask + 0x04 ; -- oq leader
    if (cell.slot ~= 1) then
      mask = mask + 0x10 ;  -- NOT group leader
    end
    if (my_group ~= cell.gid) or (my_slot ~= cell.slot) then
      mask = mask + 0x20 ; -- i'm OQ leader but not clicking on my cell
    end
  end  
  if (my_group ~= cell.gid) or (my_slot ~= cell.slot) then
    mask = mask + 0x08 ; -- not my cell
  end

  oq.menu_create()  
  for i,v in pairs(options) do
    if (oq.is_set( v.f, mask )) then
      local func = nil ;
      if (v.notClickable == nil) then
        func = function(self,arg1,arg2) oq.on_classdot_menu_select( arg2.gid, arg2.slot, arg1 ) ; return true ; end ;
      end
      oq.menu_add( v.msg, v.val, cell, nil, func ) ;
    end
  end  
  oq.menu_show( cell, "TOPLEFT", 30, -25, "BOTTOMLEFT", 160 ) ;

  local p = oq.raid.group[cell.gid].member[cell.slot] ;
  if ((p.realid == nil) or (p.realid == "")) and (p.name ~= nil) and (p.realm ~= nil) then
    oq._sender = nil ;
    oq.raid_announce( "need_btag,"..
                      p.name ..","..
                      p.realm 
                    ) ;
  end
end

function oq.cell_occupied( g_id, slot )
  if (oq.raid.group[ g_id ] == nil) or (oq.raid.group[ g_id ].member[slot] == nil) then
    return nil ;
  end
  local m = oq.raid.group[ g_id ].member[ slot ] ;
  if ((m == nil) or (m.name == nil) or (m.name == "") or (m.name == "-")) then
    return nil ;
  end
  return true ;
end

function oq.my_cell( gid, slot )
  return ((my_group == gid) and (my_slot == slot)) ;
end

function oq.on_classdot_click( cell, frame ) 
  if (oq.iam_raid_leader() and oq.cell_occupied( cell.gid, cell.slot )) then
    cell:SetPoint("Center", UIParent, "Center") ;
    oq.make_classdot_dropdown(cell) ;
    cell:SetHeight(cell.cy) ; -- forcing hieght; EasyMenu seems to resize the cell for some reason
  elseif oq.cell_occupied( cell.gid, cell.slot ) and not oq.my_cell(cell.gid, cell.slot) then
    cell:SetPoint("Center", UIParent, "Center") ;
    oq.make_classdot_dropdown(cell) ;
    cell:SetHeight(cell.cy) ; -- forcing hieght; EasyMenu seems to resize the cell for some reason
  end
end

function oq.create_class_dot( parent, x, y, cx, cy ) 
  oq.nthings = (oq.nthings or 0) + 1 ;
  local n = "DotRegion".. oq.nthings ;
  local f = oq.panel( parent, n, x, y, cx, cy ) ;
  local val = 5 ;

  f.cy = cy ;

  f.gid  = 0 ;
  f.slot = 0 ;
  n = "DotTexture".. oq.nthings ;
  f.texture:SetAllPoints(f) ;
  f.texture:SetTexture( 0.2, 0.2, 0.0, 1 ) ;

  -- deserter 
  f.status = f:CreateTexture(n .. "Deserter", "OVERLAY" ) ;
  f.status:SetPoint("TOPLEFT", f,"TOPLEFT", 2, -3) ;
  f.status:SetPoint("BOTTOMRIGHT", f,"BOTTOMRIGHT", -2, 3) ;
  f.status:SetTexture( nil ) ;

  -- class
  f.class = f:CreateTexture(n .. "Class", "OVERLAY" ) ;
  f.class:SetPoint("TOPLEFT", f,"CENTER", -8, -8) ;
  f.class:SetPoint("BOTTOMRIGHT", f,"CENTER", 8, 8) ;
  f.class:SetTexture( nil ) ;

  -- role
  f.role = f:CreateTexture(n .. "Role", "OVERLAY" ) ;
  f.role:SetPoint("TOPLEFT", f,"BOTTOMRIGHT", -14, 14) ;
  f.role:SetPoint("BOTTOMRIGHT", f,"BOTTOMRIGHT", 4, -4) ;
  f.role:SetTexture( nil ) ;
  
  -- add tooltip event handler 
  --
  f:SetScript("OnEnter", function(self, ...) oq.on_classdot_enter(self) ; end ) ;
  f:SetScript("OnLeave", function(self, ...) oq.on_classdot_exit (self) ; end ) ;

--  f:SetScript( "OnMouseDown", function(self, frame)  
  f:SetScript( "OnMouseUp", function(self, frame)  
                                oq.on_classdot_click( self, frame ) ;
                              end  
             ) ;

  oq.moveto( f, x, y ) ;
  f:SetSize( cx, cy ) ;
  f:Show() ;
  return f ;
end

function oq.create_dungeon_dot( parent, x, y, cx, cy ) 
  oq.nthings = (oq.nthings or 0) + 1 ;
  local n = "DotRegion".. oq.nthings ;
  local f = oq.panel( parent, n, x, y, cx, cy ) ;
  local val = 5 ;

  f.cy = cy ;

  f.gid  = 0 ;
  f.slot = 0 ;
  n = "DotTexture".. oq.nthings ;
  f.texture:SetAllPoints(f) ;
  f.texture:SetTexture( 0.2, 0.2, 0.0, 1 ) ;

  -- status
  f.status = f:CreateTexture(n .. "Deserter", "OVERLAY" ) ;
  f.status:SetPoint("TOPLEFT", f,"BOTTOMRIGHT", -25, 16) ;
  f.status:SetPoint("BOTTOMRIGHT", f,"BOTTOMRIGHT", -1, -8) ;

  f.status:SetTexture( nil ) ;

  -- class
  f.class = f:CreateTexture(n .. "Class", "OVERLAY" ) ;
  f.class:SetPoint("TOPLEFT", f,"TOPLEFT", -17, -12) ;
  f.class:SetPoint("BOTTOMRIGHT", f,"TOPLEFT", -1, -28) ;
  f.class:SetTexture( nil ) ;

  -- role
  f.role = f:CreateTexture(n .. "Role", "OVERLAY" ) ;
  f.role:SetPoint("TOPLEFT", f,"BOTTOMLEFT", 1, 14) ;
  f.role:SetPoint("BOTTOMRIGHT", f,"BOTTOMLEFT", 17, -4) ;
  f.role:SetTexture( nil ) ;
  
  -- add tooltip event handler 
  --
  f:SetScript("OnEnter", function(self, ...) oq.on_classdot_enter(self) ; end ) ;
  f:SetScript("OnLeave", function(self, ...) oq.on_classdot_exit (self) ; end ) ;

  f:SetScript( "OnMouseDown", function(self, frame)  
                                oq.on_classdot_click( self, frame ) ;
                              end  
             ) ;

  oq.moveto( f, x, y ) ;
  f:SetSize( cx, cy ) ;
  f:Show() ;
  return f ;
end

function oq.create_challenge_dot( parent, x, y, cx, cy ) 
  oq.nthings = (oq.nthings or 0) + 1 ;
  local n = "DotRegion".. oq.nthings ;
  local f = oq.panel( parent, n, x, y, cx, cy ) ;
  local val = 5 ;

  f.cy = cy ;

  f.gid  = 0 ;
  f.slot = 0 ;
  n = "DotTexture".. oq.nthings ;
  f.texture:SetAllPoints(f) ;
  f.texture:SetTexture( 0.2, 0.2, 0.0, 1 ) ;

  -- status
  f.status = f:CreateTexture(n .. "Deserter", "OVERLAY" ) ;
  f.status:SetPoint("TOPLEFT", f,"BOTTOMRIGHT", -25, 16) ;
  f.status:SetPoint("BOTTOMRIGHT", f,"BOTTOMRIGHT", -1, -8) ;

  f.status:SetTexture( nil ) ;

  -- class
  f.class = f:CreateTexture(n .. "Class", "OVERLAY" ) ;
  f.class:SetPoint("TOPLEFT", f,"TOPLEFT", -17, -12) ;
  f.class:SetPoint("BOTTOMRIGHT", f,"TOPLEFT", -1, -28) ;
  f.class:SetTexture( nil ) ;

  -- role
  f.role = f:CreateTexture(n .. "Role", "OVERLAY" ) ;
  f.role:SetPoint("TOPLEFT", f,"BOTTOMLEFT", 1, 14) ;
  f.role:SetPoint("BOTTOMRIGHT", f,"BOTTOMLEFT", 17, -4) ;
  f.role:SetTexture( nil ) ;
  

  -- add tooltip event handler 
  --
  f:SetScript("OnEnter", function(self, ...) oq.on_classdot_enter(self) ; end ) ;
  f:SetScript("OnLeave", function(self, ...) oq.on_classdot_exit (self) ; end ) ;

  f:SetScript( "OnMouseDown", function(self, frame)  
                                oq.on_classdot_click( self, frame ) ;
                              end  
             ) ;

  oq.moveto( f, x, y ) ;
  f:SetSize( cx, cy ) ;
  f:Show() ;
  return f ;
end

function oq.on_ladderdot_click( cell, frame ) 
  if (oq.iam_raid_leader() and oq.cell_occupied( cell.gid, cell.slot )) then
    cell:SetPoint("Center", UIParent, "Center") ;
    oq.make_classdot_dropdown(cell) ;
    cell:SetHeight(cell.cy) ; -- forcing hieght; EasyMenu seems to resize the cell for some reason
  elseif oq.cell_occupied( cell.gid, cell.slot ) and not oq.my_cell(cell.gid, cell.slot) then
    cell:SetPoint("Center", UIParent, "Center") ;
    oq.make_classdot_dropdown(cell) ;
    cell:SetHeight(cell.cy) ; -- forcing hieght; EasyMenu seems to resize the cell for some reason
  end
end


function oq.create_group( parent, x, y, cx, cy, label_cx, title, group_id ) 
  oq.nthings = (oq.nthings or 0) + 1 ;
  local n = "GroupRegion".. oq.nthings ;
  local f = oq.panel( parent, n, x, y, cx, cy ) ;
  local i = 1 ;

  f.texture:SetTexture( 0.0, 0.0, 0.0, 1 ) ;

  f.gid       = oq.label( f,   2, 2,  16, cy-8, title ) ;
  f.bgroup    = oq.texture(f ,16, (cy - 25)/2,  25, 25, nil ) ;
-- f.bgroup.texture:SetTexture( OQ_BGROUP_ICON["Vengeance"] ) ;

  f.realm     = oq.label( f,  50, 2,  75, cy-8, "-" ) ;
  f.realm:SetTextColor( 0.6, 0.6, 0.6 ) ;
  f.leader    = oq.label( f, 135, 2, 125, cy-8, "-" ) ;
  f.leader:SetFont(OQ.FONT, 12, "") ;
  f.lag       = oq.label( f, 135, 2, 120, cy-8, "-" ) ;
  f.lag:SetTextColor( 0.7, 0.7, 0.7, 1 ) ;
  f.lag:SetFont(OQ.FONT, 8, "") ;
  f.lag:SetJustifyV( "BOTTOM" ) ;
  f.lag:SetJustifyH( "RIGHT" ) ;
  
  f.status = tbl.new() ;
  f.status[1] = oq.label( f, 450, 2, 100, cy-8, "-" ) ;
  f.status[2] = oq.label( f, 625, 2, 100, cy-8, "-" ) ;

  f.dtime = tbl.new() ;
  f.dtime[1] = oq.label( f, 450, 2, 100, cy, "" ) ;
  f.dtime[1]:SetTextColor( 0.7, 0.7, 0.7, 1 ) ;
  f.dtime[1]:SetFont(OQ.FONT, 8, "") ;
  f.dtime[1]:SetJustifyV( "BOTTOM" ) ;
  f.dtime[1]:SetJustifyH( "CENTER" ) ;
  
  f.dtime[2] = oq.label( f, 625, 2, 100, cy, "" ) ;
  f.dtime[2]:SetTextColor( 0.7, 0.7, 0.7, 1 ) ;
  f.dtime[2]:SetFont(OQ.FONT, 8, "") ;
  f.dtime[2]:SetJustifyV( "BOTTOM" ) ;
  f.dtime[2]:SetJustifyH( "CENTER" ) ;

  f.slots = tbl.new() ;
  local cx = cy-2*2 ; -- to make them square
  for i=1,5 do
    f.slots[i] = oq.create_class_dot( f, 255 + 5 + (cx+4)*(i-1), 2, cx, cy-2*2 ) ;
    f.slots[i].gid  = group_id ;
    f.slots[i].slot = i ;
  end
  f:Show() ;
  return f ;
end

function oq.create_dungeon_group( parent, x_, y_, ix, iy, label_cx, title, group_id ) 
  oq.nthings = (oq.nthings or 0) + 1 ;
  local n = "GroupRegion".. oq.nthings ;
  local f = oq.panel( parent, n, x_, y_, ix, iy ) ;
  local i = 1 ;

  f.texture:SetTexture( 0.0, 0.0, 0.0, 1 ) ;
  f.texture:SetAllPoints( f ) ;

  local cy = iy - 2*5 ;
  local cx = floor( (ix - 4*10 - 2*10) / 5 ) ;
  
  f.gid = oq.label( f,   2, 2,  16, cy-8, title ) ;

  f.slots = tbl.new() ;
  local x = 10 ;
  for i=1,5 do
    f.slots[i] = oq.create_dungeon_dot( f, x, 5, cx, cy ) ;
    f.slots[i].gid  = group_id ;
    f.slots[i].slot = i ;
    x = x + cx + 10 ;
  end

  f:Show() ;
  return f ;
end

function oq.create_challenge_group( parent, x_, y_, ix, iy, label_cx, title, group_id ) 
  oq.nthings = (oq.nthings or 0) + 1 ;
  local n = "GroupRegion".. oq.nthings ;
  local f = oq.panel( parent, n, x_, y_, ix, iy ) ;
  local i = 1 ;

  f.texture:SetTexture( 0.0, 0.0, 0.0, 1 ) ;
  f.texture:SetAllPoints( f ) ;

  local cy = iy - 2*5 ;
  local cx = floor( (ix - 4*10 - 2*10) / 5 ) ;
  
  f.gid = oq.label( f,   2, 2,  16, cy-8, title ) ;

  f.slots = tbl.new() ;
  local x = 10 ;
  for i=1,5 do
    f.slots[i] = oq.create_class_dot( f, x, 5, cx, cy ) ;
    f.slots[i].gid  = group_id ;
    f.slots[i].slot = i ;
    x = x + cx + 10 ;
  end

  f:Show() ;
  return f ;
end

function oq.create_scenario_group( parent, x, y, ix, iy, label_cx, title, group_id ) 
  oq.nthings = (oq.nthings or 0) + 1 ;
  local n = "GroupRegion".. oq.nthings ;
  local f = oq.panel( parent, n, x, y, ix, iy ) ;
  local i = 1 ;

  f.texture:SetTexture( 0.0, 0.0, 0.0, 1 ) ;
  f.texture:SetAllPoints( f ) ;

  local cy = iy - 2*5 ;
  local cx = floor( (ix - 4*10 - 2*10) / 5 ) ;
  
  f.gid       = oq.label( f,   2, 2,  16, cy-8, title ) ;
  f.slots = tbl.new() ;
  local x = 10 ;
  x = x + cx + 10 ; -- bump ahead one panel to center it
  for i=1,3 do
    f.slots[i] = oq.create_dungeon_dot( f, x, 5, cx, cy ) ;
    f.slots[i].gid  = group_id ;
    f.slots[i].slot = i ;
    x = x + cx + 10 ;
  end
  f:Show() ;
  return f ;
end

function oq.create_arena_group( parent, x_, y_, ix, iy, label_cx, title, group_id ) 
  oq.nthings = (oq.nthings or 0) + 1 ;
  local n = "ArenaRegion".. oq.nthings ;
  local f = oq.panel( parent, n, x_, y_, ix, iy ) ;
  local i = 1 ;

  f.texture:SetTexture( 0.0, 0.0, 0.0, 1 ) ;
  f.texture:SetAllPoints( f ) ;

  local cy = iy - 2*5 ;
  local cx = floor( (ix - 4*10 - 2*10) / 5 ) ;
  
  f.gid = oq.label( f,   2, 2,  16, cy-8, title ) ;

  f.slots = tbl.new() ;
  local x = 10 ;
  for i=1,5 do
    f.slots[i] = oq.create_dungeon_dot( f, x, 5, cx, cy ) ;
    f.slots[i].gid  = group_id ;
    f.slots[i].slot = i ;
    x = x + cx + 10 ;
  end

  f:Show() ;
  return f ;
end

function oq.create_ladder_group( parent, x_, y_, ix, iy, label_cx, title, group_id ) 
  oq.nthings = (oq.nthings or 0) + 1 ;
  local n = "LadderRegion".. oq.nthings ;
  local f = oq.panel( parent, n, x_, y_, ix, iy ) ;
  local i = 1 ;
  local j = 1 ;

  f.texture:SetTexture( 0.0, 0.0, 0.0, 1 ) ;
  f.texture:SetAllPoints( f ) ;

  local cy = 16 ;
  local cx = 16 ;
  
  f.gid = oq.label( f,   2, 2,  16, cy-8, title ) ;

  f.slots = tbl.new() ;
  local x = 10 ;
  local y = (iy / 2) - 2 * (cy + 2) ;
  local ndx = 2 ;
  for i=1,4 do
    x = (ix / 2) - 2 * (cx + 2) ; 
    for j=1,4 do
      f.slots[ndx] = oq.create_ladder_dot( f, x, y, cx, cy ) ;
      f.slots[ndx].gid  = group_id ;
      f.slots[ndx].slot = ndx ;
      x = x + cx + 2 ;
      ndx = ndx + 1 ;
    end
    y = y + cy + 2 ;
  end

  f.slots[1] = oq.create_ladder_dot( f, (ix - cx)/2, 10, cx, cy ) ; -- referee / ladder owner
  f.slots[1].gid  = group_id ;
  f.slots[1].slot = 1 ;

  f:Show() ;
  return f ;
end

function oq.on_premade_item_enter( self )
  oq.pm_tooltip_set( self, self.token ) ;
end

function oq.on_premade_item_exit( self )
  oq.pm_tooltip_hide() ;
end


OQ.patterns = 
  {
    [0] = { r= 2/255, g= 100/255, b= 255/255, a=0.9, bdrop=nil,
            r2= 0/255, g2=  0/255, b2=0/255, a2=0.0,
            left=25, top=-55, right=-25, bottom=45,
            adjust_top=-30, adjust_bottom=70, nosort=1 
          },
  } ;

function oq.process_vlist(vlist)
  if (vlist == nil) then
    return ;
  end
  local n = #vlist / 2 ;
  if (n == 0) then
    return ;
  end
  for i=1,n do
    oq.req_vlist( oq.decode_mime64_digits( vlist:sub( i*2-1, i*2 ))) ;
  end
end

function oq.req_vlist(id)
  if (id == nil) or (id == 0) then
    return ;
  end
  if (OQ_data.vlist == nil) then
    OQ_data.vlist = {} ;
  end
  if (OQ_data.vlistq == nil) then
    OQ_data.vlistq = {} ;
  end
  local now = utc_time() ;
  if (OQ_data.vlist[id] == nil) or (OQ_data.vlist[id] < now) then
    -- queue it up
    table.insert( OQ_data.vlistq, id ) ;
    if (not oq.is_timer("chk_vlist")) then
      oq.timer( "chk_vlist", OQ.CHK_VLIST_TM, oq.chk_vlistq, true ) ;
    end
  end
end

function oq.chk_vlistq()
  if (OQ_data.vlistq == nil) then
    return ;
  end
  local now = utc_time() ;
  if (OQ_data.vlistq_last) and ((now - OQ_data.vlistq_last) < OQ.CHK_VLIST_TM) then
    return ;
  end
  OQ_data.vlistq_last = now ;
  local id = table.remove( OQ_data.vlistq, 1 ) ;
  if (id == nil) then
    oq.timer( "chk_vlist", OQ.CHK_VLIST_TM, nil ) ;
    return ;
  end
  
  oq.send_req_vlist( id ) ;
end

function oq.send_req_vlist(id)
  if (id == nil) or (id == 0) then
    return ;
  end
  local now = utc_time() ;
  if (OQ_data.vlist[id]) and (OQ_data.vlist[id] > now) then
    return ;
  end
  
  local submit_token = "S".. oq.token_gen() ;
  oq.token_push( submit_token ) ;
  local msg = OQSK_HEADER ..",".. 
              OQSK_VER ..","..
              "W1,"..
              "req_vlist,"..
              tostring(player_realid) ..","..
              submit_token ..","..
              oq.encode_mime64_2digit(id) ;
  oq.send_to_scorekeeper( msg ) ;
end

local _vlist = {} ;
function oq.on_vlist(token, id, expiration, vlist)
  if (OQ_data.vlist == nil) then
    OQ_data.vlist = {} ;
  end
  if (not oq.is_my_req_token( token )) then
    return ;
  end
  id = oq.decode_mime64_digits(id) ;
  if (id == nil) or (id == 0) then
    return ;
  end
  expiration = oq.decode_mime64_digits(expiration) ;
  if (expiration == nil) or (expiration == 0) then
    return ;
  end
  -- parse
  OQ_data.vlist[id] = expiration ;
  local v ;
  local i = 0 ;
  tbl.clear(_vlist) ;
  for v in string.gmatch(vlist, "([^.]+)") do
    i = i + 1 ;
    _vlist[i] = v ;
  end
  
  if (OQ_data.vtags == nil) then
    OQ_data.vtags = {} ;
  end
  
  for i,v in pairs(_vlist) do
    local ndx   = oq.decode_mime64_digits(v:sub(5,5)) ;
    local nosrt = nil ;
    local btag  = v:sub(6,-1) ;
    if (v:sub(4,4) == '1') then
      nosrt = 1 ;
    end
    if (OQ_data.vtags[btag]) then
      OQ_data.vtags[btag] = tbl.delete( OQ_data.vtags[btag] ) ;
    end
    if (OQ.patterns[ndx]) then
      OQ_data.vtags[btag] = copyTable( OQ.patterns[ndx] ) ;
      OQ_data.vtags[btag] = { r = (oq.decode_mime64_digits(v:sub(1,1)) * 4)/255, 
                              g = (oq.decode_mime64_digits(v:sub(2,2)) * 4)/255, 
                              b = (oq.decode_mime64_digits(v:sub(3,3)) * 4)/255, 
                              nosort = nosrt,
                              expires = expiration,
                            } ;
    end
  end
end

function oq.create_raid_listing( parent, x, y, cx, cy, token, type ) 
  oq.nlistings = oq.nlistings + 1 ;
  local i = 1 ;
  local n = "ListingRegion".. oq.nlistings ;
  local f = oq.panel( parent, n, x, y, cx, cy, true ) ;
--  f:SetFrameLevel( parent:GetFrameLevel() + 10 ) ;

  f.cy = cy ;
  f.token = token ;
--  f.texture:SetTexture( 0.0, 0.0, 0.0, 1 ) ;
--  f:SetFrameStrata( "LOW" ) ;

  local x2 = 0 ;
  f.raid_name = oq.label  ( f, x2, 2, 175, cy, ""  ) ;  x2 = x2 + 185 ;
  f.raid_name:SetFont(OQ.FONT, 11, "") ;

  -- 
  -- dragon
  --
  local d = oq.CreateFrame("FRAME", "OQListing".. oq.nlistings .."Dragon", f ) ;
  d:SetBackdropColor(0.8,0.8,0.8,1.0) ;
  oq.setpos( d, x2-16, 0, 32, 32 ) ;
  local t = d:CreateTexture( nil, "OVERLAY" ) ;
  t:SetTexture( nil ) ;
  t:SetAllPoints(d) ;
  t:SetAlpha( 1.0 ) ;
  d.texture = t ;
  d:Show() ;
  f.dragon = d ;

  f.leader    = oq.label  ( f, x2, 2,  90, cy, ""  ) ;  x2 = x2 +  90 ;
  f.leader:SetFont( OQ.FONT, 11, "" ) ;
  f.leader:SetTextColor( 0.9, 0.9, 0.9 ) ;
  
  f.levels    = oq.label  ( f, x2, 2,  45, cy, ""  ) ;  x2 = x2 +  45 + 2 ; -- keep these 2 lines balanced to line up
  f.min_ilvl  = oq.label  ( f, x2, 2,  40, cy, "-" ) ;  x2 = x2 +  40 - 2 ; -- keep these 2 lines balanced to line up
  f.min_resil = oq.label  ( f, x2, 2,2*48, cy, "-" ) ;  x2 = x2 +  45 ; -- extra wide for dungeon icons
  f.min_mmr   = oq.label  ( f, x2, 2,  45, cy, "-" ) ;  x2 = x2 +  45 ;
  f.zones     = oq.label  ( f, x2, 2, 140, cy, ""  ) ;  x2 = x2 + 140 ;
  f.zones:SetTextColor( 0.9, 0.9, 0.9 ) ;
  f.zones:SetFont( OQ.FONT, 10, "" ) ;
  f.has_pword = oq.texture( f, x2, 2,  24, 38, nil ) ;  x2 = x2 + 22 ;
  f.req_but   = oq.button ( f, x2, 2,  75, cy-2, OQ.BUT_WAITLIST, 
                                              function(self) 
                                                oq.get_battle_tag() ;
                                                if ((player_realid == nil) or (player_realid == "")) then
                                                  return ;
                                                else
                                                  oq.check_and_send_request( self:GetParent().token ) ;
                                                end
                                              end ) ;
  x2 = x2 +  80 ;
  f.unlist_but = oq.button( f, x2, 2,  24, cy-2, "x", 
                                              function(self,button,down) 
                                                local tok = self:GetParent().token ;
                                                if (button == "LeftButton") then
                                                  oq.send_leave_waitlist( tok ) ; 
                                                elseif (button == "RightButton") then  
                                                  local premade = oq.premades[ tok ] ;
                                                  if (premade ~= nil) then
                                                    local dialog = StaticPopup_Show("OQ_BanUser", premade.leader_rid) ;
                                                    if (dialog ~= nil) then
                                                      dialog.data2 = { flag = 4, btag = premade.leader_rid, raid_tok = tok } ;
                                                    end                                                            
                                                  end
                                                end 
                                              end ) ;
                                              
  f.unlist_but:RegisterForClicks("LeftButtonUp", "RightButtonUp") ;
  f.unlist_but.tt = OQ.TT_LEAVEPREMADE ;
  -- add tooltip event handler 
  --
  f:SetScript("OnEnter", function(self, ...) oq.on_premade_item_enter(self) ; end ) ;
  f:SetScript("OnLeave", function(self, ...) oq.on_premade_item_exit (self) ; end ) ;
                                              
  f:Show() ;
  return f ;
end

function oq.set_waitlist_tooltip( f )
  if (f ~= nil) and (f.token ~= nil) then
    oq.tooltip_set2( f, oq.waitlist[ f.token ], true ) ;
  end
end

function oq.create_waitlist_item( parent, x, y, cx, cy, token, n_members ) 
  oq.nthings = (oq.nthings or 0) + 1 ;
  local i = 1 ;
  local n = "WaitRegion".. oq.nthings ;
  local f = oq.panel( parent, n, x, y, cx, cy, true ) ;
  f:SetFrameLevel( parent:GetFrameLevel() + 10 ) ;
  f:SetScript("OnEnter", function(self, ...) oq.set_waitlist_tooltip( self ) ; end ) ;
  f:SetScript("OnLeave", function(self, ...) oq.tooltip_hide() ; end ) ;

  f.cy = cy ;
  f.token = token ;
  local x2 = 0 ;
  f.remove_but = oq.button( f, x2, 2,  20, cy-2, "x", function(self,button,down)  
                                                        local tok = self:GetParent().req_token ;
                                                        if (button == "LeftButton") then
                                                          oq.remove_waitlist( tok ) ; 
                                                        elseif (button == "RightButton") then  
                                                          local req = oq.waitlist[ tok ] ;
                                                          if (req ~= nil) then
                                                            local dialog = StaticPopup_Show("OQ_BanUser", req.realid) ;
                                                            if (dialog ~= nil) then
                                                              dialog.data2 = { flag = 2, btag = req.realid, req_token = tok } ;
                                                            end                                                            
                                                          end
                                                        end 
                                                      end
                           ) ;
  f.remove_but:RegisterForClicks("LeftButtonUp", "RightButtonUp") ;
  x2 = x2 + 20+4 ;                                               
  f.bgroup     = oq.texture( f, x2, (cy - 24)/2,  24, 24, nil ) ;  x2 = x2 + 30 ;
  f.role       = oq.label  ( f, x2, 5,  20, cy, ""            ) ;  x2 = x2 + 24 ;
  f.role:SetJustifyV( "middle" ) ;
  f.toon_name  = oq.label  ( f, x2, 2, 108, cy, ""            ) ;  x2 = x2 + 108 ;
  f.toon_name:SetFont(OQ.FONT, 12, "") ;
  f.realm      = oq.label  ( f, x2, 2, 100, cy, ""            ) ;  x2 = x2 + 100 ;
  f.level      = oq.label  ( f, x2, 2,  40, cy, "85"          ) ;  x2 = x2 +  40 ;
  f.ilevel     = oq.label  ( f, x2, 2,  40, cy, "395"         ) ;  x2 = x2 +  40 ;
  f.ilevel:SetTextColor( 0.9, 0.9, 0.9 ) ;
  f.resil      = oq.label  ( f, x2, 2,  40, cy, "4100"        ) ;  x2 = x2 +  40 ;
  f.pvppower   = oq.label  ( f, x2, 2,  40, cy, "99999"       ) ;  x2 = x2 +  50 ;
  f.pvppower:SetTextColor( 0.9, 0.9, 0.9 ) ;
  f.mmr        = oq.label  ( f, x2, 2,  40, cy, "1500"        ) ;  x2 = x2 +  40 ;
  x2 = x2 + 10 ; -- nudge for time
  f.nMembers   = n_members ;

  if (n_members == 1) then
    f.invite_but = oq.button( f, x2, 2,  75, cy-2, OQ.BUT_INVITE, 
                                               function(self, button, down) 
                                                oq.get_battle_tag() ;
                                                if (player_realid == nil) then
                                                  return ;
                                                else
                                                   local now = utc_time() ;
                                                   if (now < next_invite_tm) then
                                                     return ;
                                                   end
                                                   next_invite_tm = now + 4 ;
                                                   if (oq.raid.type == OQ.TYPE_RBG) or (oq.raid.type == OQ.TYPE_RAID) then
                                                     if (button == "LeftButton") then
                                                       -- right button should not work, as you cannot invite directly into a group
                                                       local tok = self:GetParent().req_token ;
                                                       local g, s = oq.first_raid_slot() ;
                                                       oq.group_invite_slot( tok, g, s ) ; -- always 1,5 ... will be reassigned later
                                                     end
                                                   elseif (button == "LeftButton") then
                                                     oq.group_invite_first_available( self:GetParent().req_token ) ;
                                                   elseif (button == "RightButton") then
                                                     oq.make_dropdown_04(self, self:GetParent().req_token) ;
                                                   end
                                                end
                                               end ) ;
    f.invite_but:RegisterForClicks("LeftButtonUp", "RightButtonUp") ;
    x2 = x2 +  75 + 5 ;
    f.ginvite_but = oq.button( f, x2, 2,  75, cy-2, OQ.BUT_GROUPLEAD, 
                                               function(self) 
                                                oq.get_battle_tag() ;
                                                if (player_realid == nil) then
                                                  return ;
                                                else
                                                  local now = utc_time() ;
                                                  if (now < next_invite_tm) then
                                                    return ;
                                                  end
                                                  next_invite_tm = now + 4 ;
                                                  if (oq.raid.type == OQ.TYPE_RBG) or (oq.raid.type == OQ.TYPE_RAID) then
                                                    message( OQ.NOLEADS_IN_RAID ) ;
                                                  else
                                                    oq.make_dropdown_03(self, self:GetParent().req_token) ; 
                                                  end
                                                end
                                               end ) ;
    x2 = x2 +  75 ;
  else
    --
    -- group invite button
    --
    f.invite_but = oq.button( f, x2, 2, 75*2+2, cy-2, string.format( OQ.BUT_INVITEGROUP, n_members ), 
                                               function(self) 
                                                oq.get_battle_tag() ;
                                                if (player_realid == nil) then
                                                  return ;
                                                else
                                                  local now = utc_time() ;
                                                  if (now < next_invite_tm) then
                                                    return ;
                                                  end
                                                  next_invite_tm = now + 5 ;
                                                  if (oq.raid.type == OQ.TYPE_RBG) or (oq.raid.type == OQ.TYPE_RAID) then
                                                    message( OQ.NOGROUPS_IN_RAID ) ;
                                                  else
                                                    oq.group_invite_party( self:GetParent().req_token ) ;
                                                  end
                                                end
                                               end ) ;
    x2 = x2 + 75*2 + 5 ;
  end
  f.wait_tm = oq.label ( f, x2+10, 2,  70, cy, "00:00" ) ;  x2 = x2 +  50 ;
  f:Show() ;


  return f ;
end

function oq.set_class( g_id, slot, class )
  g_id = tonumber(g_id) ;
  slot = tonumber(slot) ;
  local color = OQ.CLASS_COLORS[class] ;
  oq.raid.group[g_id].member[slot].class = class ;
  
  if (color == nil) then
    color = OQ.CLASS_COLORS[ OQ.SHORT_CLASS[class] ] ;
    if (color == nil) then
      return ;
    end
  end
end

function oq.assure_slot_exists( group_id, slot ) 
  if (group_id == 0) or (slot == 0) then
    return ;
  end
  if (oq.raid.group[group_id] == nil) then
    oq.raid.group[group_id] = tbl.new() ;
    oq.raid.group[group_id].member = tbl.new() ;
  end
  if (oq.raid.group[group_id].member == nil) then
    oq.raid.group[group_id].member = tbl.new() ;
  end
  if (oq.raid.group[group_id].member[slot] == nil) then
    oq.raid.group[group_id].member[slot] = tbl.new() ;
  end
end

function oq.set_group_member( group_id, slot, name_, realm_, class_, rid, s1, s2 )
  group_id = tonumber( group_id ) or 0 ;
  slot     = tonumber( slot ) or 0 ;
  if (group_id == 0) or (slot == 0) then
    return ;
  end
  if (name_) and (name_ == "-") then
    name_  = nil ;
    realm_ = nil ;
  end
  local realm_id = realm_ ;
  if (tonumber(realm_) ~= nil) then
    realm_ = oq.realm_uncooked(realm_) ;
  else
    realm_id = oq.realm_cooked(realm_) ;
  end
  if (class_ == nil) then
    class_ = "XX" ;
  end
  if (class_ == nil) or (class_:len() > 2) then
    class_ = OQ.SHORT_CLASS[ class_ ] or "ZZ" ;
  end
  oq.assure_slot_exists( group_id, slot ) ;
  
  local bgroup_ = oq.find_bgroup( realm_ ) ;
  local m = oq.raid.group[group_id].member[slot] ;

  if (m.realid ~= rid) then 
    if (rid) and (rid ~= "-") and (rid ~= "") and (name_) and (realm_) and (realm_ ~= "nil") then
      -- new member
      oq.on_member_join( name_, realm_, rid ) ;
    elseif ((rid == nil) or ((rid) and ((rid == "") or (rid == "-")))) and (m.realid ~= "-") then
      -- member left
      oq.on_member_left( m.name, m.realm, m.realid ) ;
    end
  end

  m.name         = name_ ;
  m.class        = class_ ;
  m.realm        = realm_ ;
  m.realm_id     = realm_id ;
  m.bgroup       = bgroup_ ;
  m.realid       = rid ;

  if (s1) and (s2) and (m.bg) then
    m.bg[1].status = (s1 or "3") ;
    m.bg[2].status = (s2 or "4") ;
  end

  if (class_ ~= nil) then
    oq.set_class( group_id, slot, class_ ) ;
  end
  
end

function oq.set_group_lead( g_id, name, realm, class, rid )
  oq.set_group_member( g_id, 1, name, realm, class, rid ) ;
end

function  oq.on_reload_now() 
  ReloadUI() ;
end

-- remove trailing and leading whitespace from string.
-- http://en.wikipedia.org/wiki/Trim_(8programming)
function oq.trim(s)
  -- from PiL2 20.4
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- remove leading whitespace from string.
-- http://en.wikipedia.org/wiki/Trim_(8programming)
function oq.ltrim(s)
  return (s:gsub("^%s*", ""))
end

-- remove trailing whitespace from string.
-- http://en.wikipedia.org/wiki/Trim_(8programming)
function oq.rtrim(s)
  local n = #s
  while n > 0 and s:find("^%s", n) do n = n - 1 end
  return s:sub(1, n)
end

function oq.tab3_create_activate()
  local in_party = (oq.GetNumPartyMembers() > 0) ;
  if (in_party and not UnitIsGroupLeader("player")) then
    StaticPopup_Show("OQ_CannotCreatePremade", nil, nil, ndx ) ;
    return ;
  end
  oq.get_battle_tag() ;
  local name = oq.rtrim( oq.tab3_raid_name:GetText() ) ;
  if ((name == nil) or (name == "")) then
    message( OQ.MSG_MISSINGNAME ) ;
    return ;
  end
  local low_name = strlower( name ) ;
  if (low_name:find( "lfg" )) then
    message( OQ.MSG_NOTLFG ) ;
    return ;
  end

  if ((player_realid == nil) or (player_realid == "")) then
    return ;
  elseif (not oq.valid_rid( player_realid )) then
    message( OQ.BAD_REALID .." ".. tostring(player_realid) ) ;
    return ;
  end
  local old_type = oq.raid.type ;
  if (oq.tab3_radio_selected == nil) then
    StaticPopup_Show("OQ_PremadeTypeMissing") ;
    return ;
  end
  oq.set_premade_type( oq.tab3_radio_selected ) ;
  if (old_type ~= oq.raid.type) then
    oq.reject_all_waitlist() ;
  end
  
  local rc = nil ;
  if (oq.tab3_create_but:GetText() == OQ.CREATE_BUTTON) then
    rc = oq.raid_create() ; 
    if (rc) then
      rc = oq.update_premade_note() ;
      oq.tab3_create_but:SetText( OQ.UPDATE_BUTTON ) ;
    end
  elseif (oq.tab3_create_but:GetText() == OQ.UPDATE_BUTTON) then
    rc = oq.update_premade_note() ;
  end
  if (rc) then
    -- do not let the user create, update, or disband the premade for 15 seconds
    oq.tab3_create_but:Disable() ;
    oq.timer_oneshot( OQ_CREATEPREMADE_CD, oq.enable_button, oq.tab3_create_but ) ;
    oq.tab1_quit_button:Disable() ;
    oq.timer_oneshot( OQ_CREATEPREMADE_CD, oq.enable_button, oq.tab1_quit_button ) ;
  end
end

function oq.enable_button( but ) 
  if (but ~= nil) then
    but:Enable() ;
  end
end

function oq.find_mesh() 
  oq.tab2_findmesh_but:Disable() ;
  oq.timer_oneshot( OQ_FINDMESH_CD, oq.enable_button, oq.tab2_findmesh_but ) ;
  
  local nOQlocals, nOQfriends = oq.get_nConnections() ;
  local connection = nOQlocals + nOQfriends ;
  if ((connection > OQ_MIN_CONNECTION) and (nOQfriends > OQ_MIN_BNET_CONNECTIONS)) then
    -- at least 3 friends off realm
    print( OQ_TRIANGLE_ICON .." ".. OQ.FINDMESH_OK ) ;
    return ;
  end
  local tok = "B" .. oq.token_gen() ;
  local msg = OQSK_HEADER ..",".. 
              OQSK_VER ..","..
              "W1,"..
              "req_btags,"..
              tostring(player_name) ..",".. 
              tostring(oq.realm_cooked(player_realm)) ..",".. 
              tostring(player_faction) ..",".. 
              tostring(player_realid) ..",".. 
              tok ;
  oq.token_push( tok ) ;
end

function oq.pull_btag() 
  oq.tab5_pullbtag_but:Disable() ;
  oq.timer_oneshot( OQ_FINDMESH_CD, oq.enable_button, oq.tab5_pullbtag_but ) ;
  local msg = OQSK_HEADER ..",".. 
              OQSK_VER ..","..
              "W1,"..
              "pull_btag,"..
              tostring(player_faction) ..",".. 
              tostring(player_realid) ;
  oq.tab5_pullbtag_but:Disable() ;
  
  oq.tab2_submit_but:Enable() ;
  OQ_data.btag_submitted = nil ;
end

function oq.submit_still_kickin() 
  if (player_realid == nil) then
    oq.get_battle_tag() ;
  end
  if (player_realm == nil) then
    player_realm = oq.GetRealmName() ;
  end
  if ((player_realid == nil) or (player_realm == nil)) then
    return ;
  end
  local msg = OQSK_HEADER ..",".. 
              OQSK_VER ..","..
              "W1,"..
              "still_kickin,"..
              tostring(player_faction) ..",".. 
              tostring(player_realid) ;
  oq.send_to_scorekeeper( msg ) ;
  return 1 ;
end

function oq.submit_btag( faction_, tag_ )
  local faction = player_faction ;
  local tag     = player_realid ;
  local now     = utc_time() ;
  local my_tag  = true ;

  if (faction_ ~= nil) and (tag_ ~= nil) then
    faction = faction_ ;
    tag     = tag_ ;
    my_tag  = nil ;
  elseif (OQ_data.btag_submitted ~= nil) and (OQ_data.btag_submitted > now) then
    -- no more then once per day
    return ;
  end
  local msg = OQSK_HEADER ..",".. 
              OQSK_VER ..","..
              "W1,"..
              "btag,"..
              tostring(faction) ..",".. 
              tostring(tag) ;
  oq.send_to_scorekeeper( msg ) ;
  if (my_tag) then
    oq.tab2_submit_but:Disable() ;
    OQ_data.ok2submit_tag = 1 ;
    oq.tab5_ok2submit_btag:SetChecked( true ) ;
    OQ_data.btag_submitted = now + 6*3600 ; -- no more then once every 6 hrs
  end
  return 1 ;
end

function oq.cache_btag( tag, note_ )
  if (tag == nil) or (tag == "") then
    return ;
  end
  if (OQ_data.btag_cache == nil) then
    OQ_data.btag_cache = tbl.new() ;
  end
  OQ_data.btag_cache[ strlower(tag) ] = { tm = utc_time() + OQ_BTAG_SUBMIT_INTERVAL, note = note_ } ;
end

function oq.clear_btag_cache()
  tbl.clear( OQ_data.btag_cache ) ;
end

function oq.in_btag_cache( tag )
  if (OQ_data.btag_cache == nil) then
    OQ_data.btag_cache = tbl.new() ;
    return nil ;
  end
  if (tag == nil) or (OQ_data.btag_cache[ strlower(tag) ] == nil) then
    return nil ;
  end
  return true ;
end

function oq.on_btags( token, t1, t2, t3, t4, t5, t6 )
  _ok2relay  = nil ;
  if (not oq.token_was_seen( token )) then
    -- not my token, bogus msg
    return ;
  end
  local msg = OQ_HEADER ..",".. 
              OQ_VER ..","..
              "W1,0,mesh_tag,0" ;

  if (not oq.is_banned( t1 )) then
    oq.BNSendFriendInvite( t1, msg, "OQ,mesh node" ) ;
  end
  if (not oq.is_banned( t2 )) then
    oq.BNSendFriendInvite( t2, msg, "OQ,mesh node" ) ;
  end
  if (not oq.is_banned( t3 )) then
    oq.BNSendFriendInvite( t3, msg, "OQ,mesh node" ) ;
  end
  if (not oq.is_banned( t4 )) then
    oq.BNSendFriendInvite( t4, msg, "OQ,mesh node" ) ;
  end
  if (not oq.is_banned( t5 )) then
    oq.BNSendFriendInvite( t5, msg, "OQ,mesh node" ) ;
  end
  if (not oq.is_banned( t6 )) then
    oq.BNSendFriendInvite( t6, msg, "OQ,mesh node" ) ;
  end
end

function oq.on_mesh_tag( faction_, rid_ ) 
  if (OQ_data.autoaccept_mesh_request ~= 1) then
    return ;
  end
  local ntotal, nonline = BNGetNumFriends() ;
  if (ntotal < OQ_MAX_BNFRIENDS) then
    _ok2decline = nil ;
    _oq_note    = "OQ,mesh node" ;
  end
end

--------------------------------------------------------------------------
-- main ui creation
--------------------------------------------------------------------------

function oq.toggle_filter( is_checked )
  local b = oq._filter ;
  if (is_checked) then
    -- show edit
    if (b._edit) then
      oq._filter._text = OQ_data._filter_text ;
      b._edit:SetText( oq._filter._text or "" ) ;
      b._edit:Show() ;
      b._edit:SetFocus() ;
    end
    OQ_data._filter_open = true ;
    OQ_data._was_filtering = true ;
    PlaySound("igMainMenuOptionCheckBoxOn") ;
    oq.reshuffle_premades() ;
  else
    -- hide edit & clear filter text
    if (b._edit) then
      b._edit:Hide() ;
    end
    b._text = nil ;
    oq.reshuffle_premades() ; -- filter removed, force ui update
    OQ_data._filter_open = nil ;
    OQ_data._was_filtering = nil ;
    PlaySound("igMainMenuOptionCheckBoxOff") ;
    oq.reshuffle_premades() ;
  end
end

function oq.update_filter( txt )
  oq._filter._text = txt ;
  OQ_data._filter_text = txt ;
  oq.reshuffle_premades() ;
end

function oq.pass_filter( p ) 
  if (p == nil) then
    return nil ;
  end
  local f = oq._filter._text ;
  if (f == nil) or (f == "") then
    return true ;
  end
  f = strlower(f) ;
  local t = strlower(p.name or "") ;
  if (t:find(f)) then
    return true ;
  end
  t = strlower(p.leader or "") ;
  if (t:find(f)) then
    return true ;
  end
  t = strlower(p.bgs or "") ;
  if (t:find(f)) then
    return true ;
  end
  return nil ;
end

function oq.filter_show()
  oq._filter:Show() ;
  if (OQ_data._was_filtering) then
    oq.toggle_filter(true) ;
  else
    oq.toggle_filter(nil) ;
--    oq._filter._edit:Show() ;
--    oq._filter._edit:SetFocus() ;
  end
end

function oq.filter_hide()
  oq._filter:Hide() ;
  OQ_data._was_filtering = oq._filter._edit:IsVisible() ;
  oq._filter._edit:Hide() ;
end

function oq.create_filter_button( parent ) 
  local x = 84 ;
  local y = 4 ;
  local cx = 24 ;
  local cy = 26 ;
  local b = CreateFrame( "CheckButton", nil, parent ) ;
  b:SetFrameLevel( parent:GetFrameLevel() + 1 ) ;
  b:RegisterForClicks('anyUp') ;
  b:SetWidth( cx ) ;
  b:SetHeight( cy ) ;
  b:SetPoint( "TOPLEFT", x, y ) ;

  local pt = b:CreateTexture()
  pt:SetTexture([[Interface\Buttons\UI-Quickslot-Depress]])
  pt:SetAllPoints(b)
  b:SetPushedTexture(pt)

  local ht = b:CreateTexture()
  ht:SetTexture([[Interface\Buttons\ButtonHilight-Square]])
  ht:SetAllPoints(b)
  b:SetHighlightTexture(ht)

  local ct = b:CreateTexture()
  ct:SetTexture([[Interface\Buttons\CheckButtonHilight]])
  ct:SetAllPoints(b)
  ct:SetBlendMode('ADD')
  ct:SetAlpha(0.5) ;
  b:SetCheckedTexture(ct)

  local bdrop = b:CreateTexture(nil, "BORDER") ;
  bdrop:SetAllPoints(b)
  bdrop:SetTexture( 0, 0, 0.1, 1 ) ;
  
  local icon = b:CreateTexture()
  icon:SetTexture([[Interface\Icons\INV_Misc_Spyglass_03]])
  icon:SetPoint( "TOPLEFT"    , 2, -2 ) ;
  icon:SetPoint( "BOTTOMRIGHT", -2, 2 ) ;
  icon:SetTexCoord(3/64,60/64,3/64,60/64);
  
  b._edit = oq.editline( parent, "Filter", x, y, 130, cy, 15 )
  b._edit:SetPoint( "TOPLEFT", x + cx + 8, y-4 ) ;
  b._edit:SetWidth( 140 ) ;
  b._edit:SetHeight( cy ) ;
  b._edit:SetAlpha(1.0) ;
  if (OQ_data._filter_text ~= nil) then
    b._edit:SetText( OQ_data._filter_text ) ;
    b._edit:Show() ;
    b:SetChecked(true) ;
  else
    b._edit:Hide() ;
  end
--[[ will clear filter text; removed to allow user to hit esc to close the ui while keeping filter text
  b._edit:SetScript( "OnEscapePressed", 
          function(self) 
            self:ClearFocus() ; 
            self:SetText("") ;
            oq._filter:Click() ;
          end ) ;
]]--
  b._edit:SetScript( "OnTextChanged"  , function(self) oq.update_filter(self:GetText()) ; end ) ;

  b:SetScript( "OnClick", function(self) oq.toggle_filter( self:GetChecked() ) ; end ) ;

  b:SetChecked(nil) ;
  b._edit:Hide() ;
  b:Hide() ;
  
  oq._filter = b ;
  return b ;
end


function oq.create_tab1_dungeon( parent )
  local x, y, cx, cy, label_cx ;
  local group_id = 1 ; -- only one group
  
  x  = 20 ;
  y  = 65 ;
  cx = 50 ;
  cy = 50 ;
  label_cx = 150 ;
  
  oq.dungeon_group = oq.create_dungeon_group( parent, x, y, parent:GetWidth()-x*2, 250, label_cx, title, group_id ) ;
end

function oq.create_tab1_challenge( parent )
  local x, y, cx, cy, label_cx ;
  local group_id = 1 ; -- only one group
  
  x  = 20 ;
  y  = 65 ;
  cx = 50 ;
  cy = 50 ;
  label_cx = 150 ;
  
  oq.raid_group = oq.create_group( parent, x, y, parent:GetWidth()-x*2, 250, label_cx, title, group_id ) ;
end


function oq.create_tab1_raid( parent )
  local x, y, cx, cy, label_cx ;

  oq.raid_group = {} ;
  x = 20 ;
  y = 65 ;
  cx = parent:GetWidth() - 2 * x ;
  cy = (parent:GetHeight() - 2*y) / 10 ;
  label_cx = 150 ;

  -- groups
  for i=1,8 do
    local f = oq.create_group( parent, x, y, cx, cy, label_cx, tostring(i), i ) ;
    f.slot = i ;
    f:Show() ;
    y = y + cy + 2 ;
    oq.raid_group[i] = f ;
  end
end

function oq.create_tab1_scenario( parent )
  local x, y, cx, cy, label_cx ;
  local group_id = 1 ; -- only one group
  
  x  = 20 ;
  y  = 65 ;
  cx = 50 ;
  cy = 50 ;
  label_cx = 150 ;
  
  oq.scenario_group = oq.create_scenario_group( parent, x, y, parent:GetWidth()-x*2, 250, label_cx, title, group_id ) ;
end

function oq.create_tab1_common( parent )
  local x, y, cx, cy, label_cx ;
  x = 20 ;
  y = 65 ;
  cx = parent:GetWidth() - 2 * x ;
  cy = (parent:GetHeight() - 2*y) / 10 ;
  label_cx = 150 ;
  
  -- raid title
  oq.tab1_name = oq.label( parent, x, 30, 300, 30, "" ) ;
  oq.tab1_name:SetFont(OQ.FONT, 14, "") ;

  -- raid notes
  y = parent:GetHeight() - cy*2 - 45 ;
  oq.tab1_notes_label = oq.label( parent, x, y     , 100, 20, "notes:" ) ;
  oq.tab1_notes       = oq.label( parent, x, y + 12, 285, cy*2 - 10, "" ) ;
  oq.tab1_notes:SetNonSpaceWrap(true) ;
  oq.tab1_notes_label:SetTextColor( 0.7, 0.7, 0.7, 1 ) ;
  oq.tab1_notes:SetTextColor( 0.9, 0.9, 0.9, 1 ) ;

  --[[ tag and version ]]--
  OQFrameHeaderLogo:SetText( "liteQueue" ) ;

  -- ready check
  oq.tab1_readycheck_button = oq.button( parent, 350, parent:GetHeight()-40, 100, 25, OQ.READY_CHK, 
                                         function(self) oq.start_ready_check() ; end ) ;

  -- quit premade
  oq.tab1_quit_button = oq.button( parent, parent:GetWidth()-155, parent:GetHeight()-40, 145, 25, OQ.LEAVE_PREMADE, 
                                   function(self) oq.quit_raid() ; end ) ;

  -- raid stats (ie: "5 / 4000 / 455" )
  x = parent:GetWidth()-155 - 110 ;
  y = parent:GetHeight() -  35 ;
  oq.tab1_raid_stats = oq.label( parent, x, y, 100, 15, "" ) ;  
  oq.tab1_raid_stats:SetJustifyH("RIGHT") ;
  oq.tab1_raid_stats:SetTextColor( 0.8, 0.8, 0.8, 1 ) ;
end

function oq.set_premade_type( t )
  oq.raid.type = t ;
  if (oq.iam_raid_leader()) then
    if (t == OQ.TYPE_RBG) or (t == OQ.TYPE_RAID) then
      ConvertToRaid() ;
    else
      ConvertToParty() ;
    end
  end
  
  if (OQTabPage6.header1 ~= nil) then
    if (oq.is_dungeon_premade() or (oq.raid.type == OQ.TYPE_RAID)) then
      -- change headers
      OQTabPage6.header1.label:SetText( OQ.HDR_HASTE ) ;
      OQTabPage6.header1.sortby = "haste" ;
      OQTabPage6.header2.label:SetText( OQ.HDR_MASTERY ) ;
      OQTabPage6.header2.sortby = "mastery" ;
      OQTabPage6.header3.label:SetText( OQ.HDR_HIT ) ;
      OQTabPage6.header3.sortby = "hit" ;
    else
      -- change headers
      OQTabPage6.header1.label:SetText( OQ.HDR_RESIL ) ;
      OQTabPage6.header1.sortby = "resil" ;
      OQTabPage6.header2.label:SetText( OQ.HDR_PVPPOWER ) ;
      OQTabPage6.header2.sortby = "power" ;
      OQTabPage6.header3.label:SetText( OQ.HDR_MMR ) ;
      OQTabPage6.header3.sortby = "mmr" ;
    end
  end
  
  -- hide all
  oq.ui.challenge_frame:Hide() ;
  oq.ui.dungeon_frame  :Hide() ;
  oq.ui.raid_frame     :Hide() ;  
  oq.ui.scenario_frame :Hide() ;  
  
  if (OQTabPage1:IsVisible()) then
    -- force the showing of the frame, incase the type changed 
    oq.onShow_tab1() ;
    oq.refresh_textures() ;
  end
end

function oq.onShow_tab1()
  -- hide all
  oq.ui.challenge_frame:Hide() ;
  oq.ui.dungeon_frame  :Hide() ;
  oq.ui.raid_frame     :Hide() ;  
  oq.ui.scenario_frame :Hide() ;  

  if (oq.raid.type == OQ.TYPE_CHALLENGE) then
    oq.ui.raid_frame:Show() ;
  elseif (oq.raid.type == OQ.TYPE_DUNGEON) then
    oq.ui.dungeon_frame:Show() ;
  elseif (oq.raid.type == OQ.TYPE_RAID) then
    oq.ui.raid_frame:Show() ;
  elseif (oq.raid.type == OQ.TYPE_SCENARIO) then
    oq.ui.scenario_frame:Show() ;
  elseif (oq.raid.type == OQ.TYPE_QUESTS) then
    oq.ui.raid_frame:Show() ;
  end
end

function oq.create_tab1()
  local cx = OQTabPage1:GetWidth() ;
  local cy = OQTabPage1:GetHeight() ;
  local level = OQTabPage1:GetFrameLevel() + 2 ;

  OQTabPage1:SetScript( "OnShow", function() 
                                    oq.onShow_tab1() ; 
                                    oq.refresh_textures() ; 
                                    if (oq.iam_raid_leader()) then 
                                      oq.ui_raidleader() ; 
                                    else 
                                      oq.ui_player() ;
                                    end
                                  end ) ;

  -- create common elements
  oq.create_tab1_common( OQTabPage1 ) ;
  
  -- create specific component: dungeons
  oq.ui.dungeon_frame = oq.panel( OQTabPage1, "OQPage1Dungeon", 0, 0, cx, cy, true ) ;
  oq.ui.dungeon_frame:SetFrameLevel( level ) ;
  oq.create_tab1_dungeon( oq.ui.dungeon_frame ) ;
  
  -- create specific component: challenge
  oq.ui.challenge_frame = oq.panel( OQTabPage1, "OQPage1Challenge", 0, 0, cx, cy, true ) ;
  oq.ui.challenge_frame:SetFrameLevel( level ) ;
  oq.create_tab1_challenge( oq.ui.challenge_frame ) ;
  
  -- create specific component: raid
  oq.ui.raid_frame = oq.panel( OQTabPage1, "OQPage1Raid", 0, 0, cx, cy, true ) ;
  oq.ui.raid_frame:SetFrameLevel( level ) ;
  oq.create_tab1_raid( oq.ui.raid_frame ) ;
  
  -- create specific component: scenario
  oq.ui.scenario_frame = oq.panel( OQTabPage1, "OQPage1Scenario", 0, 0, cx, cy, true ) ;
  oq.ui.scenario_frame:SetFrameLevel( level ) ;
  oq.create_tab1_scenario( oq.ui.scenario_frame ) ;
  
  -- show appropriate frame
  if (oq.raid == nil) or (oq.raid.type == nil) then
    oq.set_premade_type( OQ.TYPE_BG ) ;
  else
    oq.set_premade_type( oq.raid.type ) ;
  end
  
  -- enable proper controls
  oq.ui_player() ;
end

function oq.create_scrolling_list( parent, type_ )
  local scroll = oq.CreateFrame( "ScrollFrame", parent:GetName() .."ListScrollBar", parent, "FauxScrollFrameTemplate" ) ;
  scroll:SetScript("OnShow", function(self) OQ_ModScrollBar_Update(self) ; end ) ;
  scroll:SetScript("OnVerticalScroll", function(self, offset) 
    if (self._scroll_func) then  self._scroll_func(self, offset, 16, OQ_ModScrollBar_Update);
    else FauxScrollFrame_OnVerticalScroll(self, offset, 16, OQ_ModScrollBar_Update); 
    end
  end ) ;
  scroll._type = type_ ;

  local list = oq.CreateFrame( "Frame", parent:GetName() .."List", scroll ) ;
  list:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background", 
                 edgeFile="Interface/Tooltips/UI-Tooltip-Border", 
                 tile=true, tileSize = 16, edgeSize = 16,
                 insets = { left = 1, right = 1, top = 1, bottom = 1 }
                 })
  list:SetBackdropColor(0.0,0.0,0.0,1.0);
  oq.setpos( list, 0, 0, parent:GetWidth() - 2*30, 1000 ) ;

  scroll:SetScrollChild( list ) ;
  scroll:Show() ;
  
  return scroll, list ;
end

function oq.sort_premades( col )
  local order = oq.premade_sort_ascending ;
  if (oq.premade_sort ~= col) then
    order = true ;
  else
    if (order) then
      order = nil ;
    else
      order = true ;
    end
  end
  oq.premade_sort = col ;
  oq.premade_sort_ascending = order ;
  oq.reshuffle_premades() ;
end

function oq.on_premade_filter( arg1, arg2 )
  OQ_data.premade_filter_type = arg1 ;
  oq.reshuffle_premades() ;
end

OQ._premade_types = { { text = OQ.LABEL_ALL       , arg1 = OQ.TYPE_NONE },
                      { text = OQ.LABEL_ARENAS    , arg1 = OQ.TYPE_ARENA },
                      { text = OQ.LABEL_BGS       , arg1 = OQ.TYPE_BG },
                      { text = OQ.LABEL_DUNGEONS  , arg1 = OQ.TYPE_DUNGEON },
                      { text = OQ.LABEL_QUESTERS  , arg1 = OQ.TYPE_QUESTS },
                      { text = OQ.LABEL_RBGS      , arg1 = OQ.TYPE_RBG },
                      { text = OQ.LABEL_RAIDS     , arg1 = OQ.TYPE_RAID },
                      { text = OQ.LABEL_SCENARIOS , arg1 = OQ.TYPE_SCENARIO },
                      { text = OQ.LABEL_CHALLENGES, arg1 = OQ.TYPE_CHALLENGE },
                    } ;
function oq.get_premade_type_desc( t )
  for i,v in pairs(OQ._premade_types) do
    if (v.arg1 == t) then
      return v.text ;
    end
  end
  return "" ;
end

--
-- good page for docs:
-- http://www.wowpedia.org/API_UIDropDownMenu_AddButton
-- 
OQ.findpremade_types = { { text = OQ.LABEL_ALL       , arg1 = OQ.TYPE_NONE },
                         { text = OQ.LABEL_ARENAS    , arg1 = OQ.TYPE_ARENA },
                         { text = OQ.LABEL_BGS       , arg1 = OQ.TYPE_BG },
                         { text = OQ.LABEL_CHALLENGES, arg1 = OQ.TYPE_CHALLENGE },
                         { text = OQ.LABEL_DUNGEONS  , arg1 = OQ.TYPE_DUNGEON },
                         { text = OQ.LABEL_QUESTERS  , arg1 = OQ.TYPE_QUESTS },
                         { text = OQ.LABEL_RBGS      , arg1 = OQ.TYPE_RBG },
                         { text = OQ.LABEL_RAIDS     , arg1 = OQ.TYPE_RAID },
                         { text = OQ.LABEL_SCENARIOS , arg1 = OQ.TYPE_SCENARIO },
                       } ;
function oq.make_dropdown_premade_filter() 
  local m = oq.menu_create() ;
  for i,v in pairs(OQ.findpremade_types) do
    local text = v.text ;
    if (v.arg1 ~= OQ.TYPE_NONE) then
      local n = oq.premades_of_type( v.arg1 ) ;
      if (n > 0) then
        text  = v.text .." ( ".. string.format("|cFFFFD331%d|r",n) .." )" ;
      end
    end
    
    oq.menu_add( text, v.arg1, text, nil, 
                 function(cb_edit,arg1,arg2) 
                   oq.on_premade_filter( arg1, arg2 ) ; 
                   cb_edit:SetText( arg2 ) ;
                   oq.tab2_scroller:SetVerticalScroll(0) ;
                   return true ; 
                 end 
               ) ;
  end
  return m ;  
end

function oq.update_findpremade_selection()
  if (OQ_data.premade_filter_type ~= OQ.TYPE_NONE) then
    local n = oq.premades_of_type( OQ_data.premade_filter_type ) ;
    local text = oq.get_premade_type_desc( OQ_data.premade_filter_type ) ;
    if (n > 0) then
      text = text .." ( ".. string.format("|cFFFFD331%d|r",n) .." )" ;
    end
    oq.tab2_filter._edit:SetText( text ) ;
  end
end

function oq.update_premade_count() 
  local nShown, nPremades = oq.n_premades() ;

  local str = string.format( "%s  (|cFFE0E0E0%d|r - |cFF808080%d|r)", OQ.HDR_PREMADE_NAME, nShown, nPremades ) ;
  oq.premade_hdr.label:SetText( str ) ;
  oq.update_findpremade_selection() ;
end

function oq.trim_big_list( self )
  local offset = self._offset or 0 ;
  local cy = 13*25 ;
  local y1 = offset - 20 ;
  local y2 = y1 + cy + 20 ;

  for n,v in pairs(oq.tab2_raids) do 
    if (v._isvis) then
      local p = oq.premades[ v.raid_token ] ;
      if (p) then
        local y = floor(v.__y or 0) ;
        if (y >= y1) and (y <= y2) then
          v:Show() ;
        else
          v:Hide() ;
        end
      end
    end
  end
end

function oq.big_scroller( self, offset, n, f )
  self._offset = offset ;
  oq.trim_big_list( self ) ;
  FauxScrollFrame_OnVerticalScroll(self, offset, n, f ) ;
end

function oq.create_tab2()
  local parent = OQTabPage2 ;
  local x, y, cx, cy ;

  -- sorting and filtering presets
  oq.premade_sort = "name" ;
  oq.premade_sort_ascending = true ;
  if (OQ_data.premade_filter_qualified == nil) then
    OQ_data.premade_filter_qualified = 0 ;
  end
  if (OQ_data.premade_filter_type == nil) then
    OQ_data.premade_filter_type = OQ.TYPE_NONE ; -- show all premade types
  end
  
  parent:SetScript( "OnShow", function() oq.populate_tab2() ; oq.filter_show() ; end ) ;
  parent:SetScript( "OnHide", function() oq.filter_hide() ; end ) ;

  oq.tab2_scroller, oq.tab2_list = oq.create_scrolling_list( parent, "premades" ) ;
  oq.tab2_scroller._scroll_func = oq.big_scroller ;
  
  local f = oq.tab2_scroller ;
  oq.setpos( f, -40, 50, f:GetParent():GetWidth() - 2*30, f:GetParent():GetHeight() - (50+38) ) ;

  -- list header
  cy = 20 ;
  x  = 20 + 15 ;
  y  = 27 ;
  f = oq.click_label( parent, x, y, 185, cy, OQ.HDR_PREMADE_NAME  ) ;  x = x + 185 ;
  f:SetScript("OnClick", function(self) oq.sort_premades( "name" ) ; end ) ;
  oq.premade_hdr = f ;
  
  f = oq.click_label( parent, x, y,  90, cy, OQ.HDR_LEADER        ) ;  x = x +  90 ;
  f:SetScript("OnClick", function(self) oq.sort_premades( "lead" ) ; end ) ;
  f = oq.click_label( parent, x, y,  45, cy, OQ.HDR_LEVEL_RANGE   ) ;  x = x +  47 ;
  f:SetScript("OnClick", function(self) oq.sort_premades( "level" ) ; end ) ;
  f = oq.click_label( parent, x, y,  40, cy, OQ.HDR_ILEVEL        ) ;  x = x +  40 ;
  f:SetScript("OnClick", function(self) oq.sort_premades( "ilevel" ) ; end ) ;
  f = oq.click_label( parent, x, y,  45, cy, OQ.HDR_RESIL         ) ;  x = x +  45 ;
  f:SetScript("OnClick", function(self) oq.sort_premades( "resil" ) ; end ) ;
  f = oq.click_label( parent, x, y,  45, cy, OQ.HDR_MMR           ) ;  x = x +  45 ;
  f:SetScript("OnClick", function(self) oq.sort_premades( "mmr" ) ; end ) ;

  x = parent:GetWidth() - 200 ;
  oq.tab2_nfriends = oq.label( parent, x, y, 150, cy, string.format( OQ.BNET_FRIENDS, 0 ) ) ; 
  oq.tab2_nfriends:SetJustifyH("right") ;

  x = parent:GetWidth() - (120 + 50) ;
  y = parent:GetHeight() - 32 ;
  oq.tab2_connection = oq.label( parent, x, y, 120, 15, "connection  0 : 0" ) ;
  oq.tab2_connection:SetJustifyH("right") ;

  x = x - 110 ;
  oq.tab2_findmesh_but = oq.button2( parent, x, y-5, 90, 24, OQ.BUT_FINDMESH, 14,
                                     function(self) oq.find_mesh() ; end 
                                    ) ;
  oq.tab2_findmesh_but.string:SetFont(OQ.FONT, 10, "") ;
  
  x = x - 95 ;
  oq.tab2_submit_but = oq.button2( parent, x, y-5, 90, 24, OQ.BUT_SUBMIT2MESH, 14,
                                   function(self) oq.submit_btag() ; end 
                                 ) ;
  oq.tab2_submit_but.string:SetFont(OQ.FONT, 10, "") ;
  if (OQ_data.btag_submitted ~= nil) and (OQ_data.btag_submitted > utc_time()) then
    oq.tab2_submit_but:Disable() ;
  else
    oq.tab2_submit_but:Enable() ;
  end

  x = x - 195 ;

  oq.tab2_filter = oq.combo_box( parent, x, y-5, 170, 24, oq.make_dropdown_premade_filter, OQ.LABEL_ALL ) ;
  
  x = x - 85 ;
  oq.tab3_enforce = oq.checkbox( parent, x, y-2,  23, cy, 90, OQ.QUALIFIED, (OQ_data.premade_filter_qualified == 1), 
                     function(self) oq.toggle_premade_qualified( self ) ; end ) ;  

  -- tooltips
  oq.tab2_findmesh_but.tt = OQ.TT_FINDMESH ;
  oq.tab2_submit_but.tt   = OQ.TT_SUBMIT2MESH ;

  -- add sample raids
  oq.tab2_raids = {} ;

  -- tag

  oq.reshuffle_premades() ;
end

function oq.tab3_radio_buttons_clear()
  oq.tab3_radio_challenge:SetChecked( nil ) ;
  oq.tab3_radio_dungeon  :SetChecked( nil ) ;
  oq.tab3_radio_quests   :SetChecked( nil ) ;
  oq.tab3_radio_raid     :SetChecked( nil ) ;
  oq.tab3_radio_scenario :SetChecked( nil ) ;

  oq.tab3_radio_selected = nil ;
end

function oq.tab3_radio_buttons( but )
  local nmembers = oq.nMembers() ;
  if (but.value == OQ.TYPE_SCENARIO) and (nmembers > 3) then
    message( string.format( OQ.DLG_16, 3 ) ) ;
    oq.tab3_radio_scenario:SetChecked( nil ) ;
    return ;
  end
  if (but.value == OQ.TYPE_DUNGEON ) and (nmembers > 5) then
    message( string.format( OQ.DLG_16, 5 ) ) ;
    oq.tab3_radio_dungeon:SetChecked( nil ) ;
    return ;
  end
  if (but.value == OQ.TYPE_CHALLENGE) and (nmembers > 5) then
    message( string.format( OQ.DLG_16, 5 ) ) ;
    oq.tab3_radio_challenge:SetChecked( nil ) ;
    return ;
  end
  if (but.value == OQ.TYPE_QUESTS) and (nmembers > 5) then
    message( string.format( OQ.DLG_16, 5 ) ) ;
    oq.tab3_radio_quests:SetChecked( nil ) ;
    return ;
  end
  if (but.value == OQ.TYPE_ARENA) and (nmembers > 5) then
    message( string.format( OQ.DLG_16, 5 ) ) ;
    oq.tab3_radio_arena:SetChecked( nil ) ;
    return ;
  end
  if (but.value == OQ.TYPE_RBG     ) and (nmembers > 10) then
    message( string.format( OQ.DLG_16, 10 ) ) ;
    oq.tab3_radio_rbgs:SetChecked( nil ) ;
    return ;
  end

  oq.tab3_radio_bgs      :SetChecked( nil ) ;
  oq.tab3_radio_challenge:SetChecked( nil ) ;
  oq.tab3_radio_dungeon  :SetChecked( nil ) ;
  oq.tab3_radio_quests   :SetChecked( nil ) ; 
--  oq.tab3_radio_ladder   :SetChecked( nil ) ; 
  oq.tab3_radio_rbgs     :SetChecked( nil ) ;
  oq.tab3_radio_arena    :SetChecked( nil ) ;
  oq.tab3_radio_raid     :SetChecked( nil ) ;
  oq.tab3_radio_scenario :SetChecked( nil ) ;

  but:SetChecked( true ) ;
  oq.tab3_radio_selected = but.value ;
end

function oq.tab3_set_radiobutton( value )
  if (oq.tab3_radio_bgs.value == value) then
    oq.tab3_radio_buttons( oq.tab3_radio_bgs ) ;
  elseif (oq.tab3_radio_dungeon.value == value) then
    oq.tab3_radio_buttons( oq.tab3_radio_dungeon ) ;
  elseif (oq.tab3_radio_rbgs.value == value) then
    oq.tab3_radio_buttons( oq.tab3_radio_rbgs ) ;
  elseif (oq.tab3_radio_raid.value == value) then
    oq.tab3_radio_buttons( oq.tab3_radio_raid ) ;
  elseif (oq.tab3_radio_scenario.value == value) then
    oq.tab3_radio_buttons( oq.tab3_radio_scenario ) ;
  end
  oq.tab3_radio_selected = value ;
  oq.set_premade_type( value ) ;
end

function oq.create_tab3()
  local x, y, cx, cy ;

  OQTabPage3:SetScript( "OnShow", function() oq.populate_tab3() ; end ) ;
  x  = 20 ;
  y  = 30 ;
  cy = 25 ;
  local t = oq.label( OQTabPage3, x, y, 400, 30, OQ.CREATEURPREMADE ) ;
  t:SetFont(OQ.FONT, 14, "") ;
  t:SetTextColor( 1.0, 1.0, 1.0, 1 ) ;

  y = 65 ;
  x = 40 ;
  oq.label( OQTabPage3, x, y, 100, cy, OQ.PREMADE_NAME    ) ;   y = y + cy + 4 ;
  oq.label( OQTabPage3, x, y, 100, cy, OQ.LEADERS_NAME    ) ;   y = y + cy + 4 ;
  oq.label( OQTabPage3, x, y, 100, cy, OQ.REALID_MOP      ) ;   y = y + cy + 4 ;
  oq.label( OQTabPage3, x, y, 100, cy, OQ.MIN_ILEVEL      ) ;   y = y + cy + 4 ;
  oq.label( OQTabPage3, x, y, 100, cy, OQ.MIN_RESIL       ) ;   y = y + cy + 4 ;
  oq.label( OQTabPage3, x, y, 125, cy, OQ.MIN_MMR         ) ;   y = y + cy + 4 ;
  oq.label( OQTabPage3, x, y, 100, cy, OQ.BATTLEGROUNDS   ) ;   y = y + cy + 4 ;
  oq.label( OQTabPage3, x, y, 100, cy, OQ.NOTES           ) ;   y = y + 3*cy + 4 ;
  oq.label( OQTabPage3, x, y, 100, cy, OQ.PASSWORD        ) ;   

  -- set faciton emblem
  local txt ;
  if (player_faction == "A") then
    txt = "Interface\\FriendsFrame\\PlusManz-Alliance" ;
  else
    txt = "Interface\\FriendsFrame\\PlusManz-Horde" ;
  end
  oq.tab3_faction_emblem = oq.texture( OQTabPage3, 450, 55, 100, 100, txt ) ;

  -- set level range 
  if (player_level == 90) then
    t = oq.label( OQTabPage3, 540, 55, 100, 50, OQ.LABEL_LEVEL ) ;
  else
    t = oq.label( OQTabPage3, 540, 55, 100, 50, OQ.LABEL_LEVELS ) ;
  end
  t:SetFont(OQ.FONT, 22, "") ;
  t:SetJustifyH("center") ;

  local minlevel, maxlevel = oq.get_player_level_range() ;
  if (minlevel == 0) then
    txt = "unavailable" ;
  elseif (minlevel == 90) then
    txt = "90" ;
  else
    txt = minlevel .." - ".. maxlevel ;
  end
  oq.tab3_level_range = txt ;
  t = oq.label( OQTabPage3, 540, 90, 100, 50, txt ) ;
  t:SetFont(OQ.FONT, 22, "") ;
  t:SetJustifyH("center") ;

  y  = 65 ;
  x  = 175 ;
  cx = 200 ;
  cy = 25 ;
  oq.tab3_raid_name      = oq.editline( OQTabPage3, "RaidName"     , x, y,   cx,   cy,  25 ) ; y = y + cy + 4 ;
  oq.tab3_lead_name      = oq.editline( OQTabPage3, "LeadName"     , x, y,   cx,   cy,  30 ) ; y = y + cy + 4 ;
  oq.tab3_rid            = oq.editline( OQTabPage3, "RealID"       , x, y,   cx,   cy,  60 ) ; y = y + cy + 4 ;
  oq.tab3_min_ilevel     = oq.editline( OQTabPage3, "MinIlevel"    , x, y,   cx,   cy,  10 ) ; y = y + cy + 4 ;
  oq.tab3_min_resil      = oq.editline( OQTabPage3, "MinResil"     , x, y,   cx,   cy,  10 ) ; y = y + cy + 4 ;
  oq.tab3_min_mmr        = oq.editline( OQTabPage3, "MinMMR"       , x, y,   cx,   cy,  10 ) ; y = y + cy + 4 ;

  oq.tab3_enforce = oq.checkbox( OQTabPage3, x+cx+10, y,  23, cy, 200, OQ.ENFORCE_LEVELS, (oq.raid.enforce_levels == 1), 
                     function(self) oq.toggle_enforce_levels( self ) ; end ) ;  
  
  oq.tab3_bgs            = oq.editline( OQTabPage3, "Battlegrounds", x, y,   cx,   cy,  60 ) ; y = y + cy + 4 ;
  oq.tab3_notes          = oq.editbox ( OQTabPage3, "Notes"        , x, y,  350, 3*cy, 150 ) ; y = y + 3*cy + 4 ;
  oq.tab3_notes:SetMaxLetters( 125 ) ;
  oq.tab3_notes:SetFont(OQ.FONT, 10, "") ;
  oq.tab3_notes:SetTextColor( 0.9, 0.9, 0.9, 1 ) ;
  oq.tab3_notes:SetText( OQ.DEFAULT_PREMADE_TEXT ) ;
  
  oq.tab3_pword          = oq.editline( OQTabPage3, "password", x, y,   cx,   cy,  10 ) ; y = y + cy + 6 ;

  -- disable real-id to force user to setup tab
  -- in MoP, tab3_rid can only be the battle-tag
  oq.tab3_lead_name:Disable() ; 
  oq.tab3_rid      :Disable() ; 

  oq.tab3_faction        = player_faction ;
  oq.tab3_channel_pword  = "p".. oq.token_gen() ;  -- no reason for the leader to set password.  just auto generate
  oq.tab3_lead_name:SetText( player_name ) ; -- auto-populate the leader name
  if (player_realid ~= nil) then
    oq.tab3_rid:SetText( player_realid ) ; -- auto-populate the leader real-id, if we have it
  end

  -- premade type selector
  y  = 140 ;
  x  = OQTabPage3:GetWidth() - 250 ;
  cy = 22 ;
  oq.label( OQTabPage3, x, y, 100, cy, "Premade type:" ) ;   y = y + cy + 3 ;
  x = x + 25 ;
  oq.tab3_radio_bgs       = oq.radiobutton( OQTabPage3, x, y, 24, 22, 100, OQ.LABEL_BG       , OQ.TYPE_BG       , oq.tab3_radio_buttons ) ;   y = y + cy ;
  oq.tab3_radio_arena     = oq.radiobutton( OQTabPage3, x, y, 24, 22, 100, OQ.LABEL_ARENA    , OQ.TYPE_ARENA    , oq.tab3_radio_buttons ) ;   y = y + cy ;
  oq.tab3_radio_challenge = oq.radiobutton( OQTabPage3, x, y, 24, 22, 100, OQ.LABEL_CHALLENGE, OQ.TYPE_CHALLENGE, oq.tab3_radio_buttons ) ;   y = y + cy ;
  oq.tab3_radio_dungeon   = oq.radiobutton( OQTabPage3, x, y, 24, 22, 100, OQ.LABEL_DUNGEON  , OQ.TYPE_DUNGEON  , oq.tab3_radio_buttons ) ;   y = y + cy ;
  oq.tab3_radio_quests    = oq.radiobutton( OQTabPage3, x, y, 24, 22, 100, OQ.LABEL_QUESTING , OQ.TYPE_QUESTS   , oq.tab3_radio_buttons ) ;   y = y + cy ;
--  oq.tab3_radio_ladder    = oq.radiobutton( OQTabPage3, x, y, 24, 22, 100, OQ.LABEL_QUESTING , OQ.TYPE_LADDER  , oq.tab3_radio_buttons ) ;   y = y + cy ;
--  oq.tab3_radio_ladder:Disable() ; -- not ready yet
  oq.tab3_radio_rbgs      = oq.radiobutton( OQTabPage3, x, y, 24, 22, 100, OQ.LABEL_RBG      , OQ.TYPE_RBG      , oq.tab3_radio_buttons ) ;   y = y + cy ;
  oq.tab3_radio_raid      = oq.radiobutton( OQTabPage3, x, y, 24, 22, 100, OQ.LABEL_RAID     , OQ.TYPE_RAID     , oq.tab3_radio_buttons ) ;   y = y + cy ;
  oq.tab3_radio_scenario  = oq.radiobutton( OQTabPage3, x, y, 24, 22, 100, OQ.LABEL_SCENARIO , OQ.TYPE_SCENARIO , oq.tab3_radio_buttons ) ;   y = y + cy ;

  -- not ready yet
--  oq.tab3_radio_rbgs:Disable() ;
--  oq.tab3_radio_raid:Disable() ;

  if (oq.raid.type == nil) or (oq.raid.raid_token == nil) then
--    oq.tab3_radio_buttons( oq.tab3_radio_bgs ) ;
    oq.tab3_radio_buttons_clear() ;
  else
    oq.tab3_set_radiobutton( oq.raid.type ) ;
  end
  
  -- create/update button
  oq.tab3_create_but     = oq.button2( OQTabPage3, OQTabPage3:GetWidth() - 250, OQTabPage3:GetHeight() - 80, 150, 45, OQ.CREATE_BUTTON, 14,
                                      function(self) oq.tab3_create_activate() ; end 
                                    ) ;
  oq.tab3_create_but.string:SetFont(OQ.FONT, 14, "") ;

  -- tabbing order
  oq.set_tab_order( oq.tab3_raid_name    , oq.tab3_min_ilevel ) ;
  oq.set_tab_order( oq.tab3_min_ilevel   , oq.tab3_min_resil ) ;
  oq.set_tab_order( oq.tab3_min_resil    , oq.tab3_min_mmr ) ;
  oq.set_tab_order( oq.tab3_min_mmr      , oq.tab3_bgs ) ;
  oq.set_tab_order( oq.tab3_bgs          , oq.tab3_notes ) ;
  oq.set_tab_order( oq.tab3_notes        , oq.tab3_pword ) ;
  oq.set_tab_order( oq.tab3_pword        , oq.tab3_raid_name ) ;

  -- tag
end

function oq.sort_waitlist( col )
  local order = oq.waitlist_sort_ascending ;
  if (oq.waitlist_sort ~= col) then
    order = true ;
  else
    if (order) then
      order = nil ;
    else
      order = true ;
    end
  end
  oq.waitlist_sort = col ;
  oq.waitlist_sort_ascending = order ;
  oq.reshuffle_waitlist() ;
end

function oq.create_tab_waitlist()
  local x, y, cx, cy ;
  local parent = OQTabPage6 ;
  oq.tab7_scroller, oq.tab7_list = oq.create_scrolling_list( parent, "waitlist" ) ;
  local f = oq.tab7_scroller ;
  oq.setpos( f, -40, 50, f:GetParent():GetWidth() - 2*30, f:GetParent():GetHeight() - (50+38) ) ;

  -- list header
  cy = 20 ;
  x  = 43 ; 
  y  = 27 ;

  f = oq.click_label( parent, x, y,  50, cy, OQ.HDR_BGROUP    ) ;  x = x +  65 ;  -- leave space for role icon
  f:SetScript("OnClick", function(self) oq.sort_waitlist( "bgrp" ) ; end ) ;
  f = oq.click_label( parent, x, y, 120, cy, OQ.HDR_TOONNAME  ) ;  x = x + 105 ;  
  f:SetScript("OnClick", function(self) oq.sort_waitlist( "name" ) ; end ) ;
  f = oq.click_label( parent, x, y, 100, cy, OQ.HDR_REALM     ) ;  x = x + 100 ;
  f:SetScript("OnClick", function(self) oq.sort_waitlist( "rlm" ) ; end ) ;
  f = oq.click_label( parent, x, y,  40, cy, OQ.HDR_LEVEL     ) ;  x = x +  40 ;
  f:SetScript("OnClick", function(self) oq.sort_waitlist( "level" ) ; end ) ;
  f = oq.click_label( parent, x, y,  40, cy, OQ.HDR_ILEVEL    ) ;  x = x +  40 ;
  f:SetScript("OnClick", function(self) oq.sort_waitlist( "ilevel" ) ; end ) ;
  f = oq.click_label( parent, x, y,  50, cy, OQ.HDR_RESIL     ) ;  x = x +  41 ;
  f:SetScript("OnClick", function(self) oq.sort_waitlist( self.sortby ) ; end ) ;
  f.sortby = "resil" ;
  parent.header1 = f ;
  f = oq.click_label( parent, x, y,  48, cy, OQ.HDR_PVPPOWER  ) ;  x = x +  50 ;
  f:SetScript("OnClick", function(self) oq.sort_waitlist( self.sortby ) ; end ) ;
  f.sortby = "power" ;
  parent.header2 = f ;
  f = oq.click_label( parent, x, y,  40, cy, OQ.HDR_MMR       ) ;  x = x +  30 ;
  f:SetScript("OnClick", function(self) oq.sort_waitlist( self.sortby ) ; end ) ;
  f.sortby = "mmr" ;
  parent.header3 = f ;
  f = oq.click_label( parent, x+185, y,  40, cy, OQ.HDR_TIME ) ;  
  f:SetScript("OnClick", function(self) oq.sort_waitlist( "time" ) ; end ) ;

  -- add samples
  oq.tab7_waitlist = {} ;

  -- tag
  oq.waitlist_sort = "time" ;
  oq.waitlist_sort_ascending = true ;
  oq.reshuffle_waitlist() ;
end

function oq.create_tab_banlist()
  local x, y, cx, cy ;
  local parent = OQTabPage5 ;
  oq.tab6_scroller, oq.tab6_list = oq.create_scrolling_list( parent, "banlist" ) ;
  local f = oq.tab6_scroller ;
  oq.setpos( f, -40, 50, f:GetParent():GetWidth() - 2*30, f:GetParent():GetHeight() - (50+38) ) ;

  -- list header
  cy = 20 ;
  x  = 80 ;
  y  = 27 ;

--  oq.label( parent, x, y, 125, cy, OQ.HDR_BTAG    ) ;  x = x + 125 ;  
--  oq.label( parent, x, y, 450, cy, OQ.HDR_REASON  ) ;  
  f = oq.click_label( parent, x, y, 130, cy, OQ.HDR_DATE   ) ;  x = x +  130 + 6 ;
  f:SetScript("OnClick", function(self) oq.sort_banlist( "ts" ) ; end ) ;
  f = oq.click_label( parent, x, y, 125, cy, OQ.HDR_BTAG   ) ;  x = x +  125 + 4 ;
  f:SetScript("OnClick", function(self) oq.sort_banlist( "btag" ) ; end ) ;
  f = oq.click_label( parent, x, y, 450, cy, OQ.HDR_REASON ) ;  
  f:SetScript("OnClick", function(self) oq.sort_banlist( "reason" ) ; end ) ;

  x = parent:GetWidth() - 135 ;
  y = parent:GetHeight() - 30 ;
  oq.tab6_ban_but = oq.button2( parent, x, y-4, 90, 24, OQ.BUT_BAN_BTAG, 14,
                                     function(self) StaticPopup_Show("OQ_BanBTag") ; end 
                                    ) ;
  oq.tab6_ban_but.string:SetFont(OQ.FONT, 10, "") ;

  -- add samples
  oq.tab6_banlist = {} ;

  -- tag
  oq.banlist_sort = "ts" ;
  oq.banlist_sort_ascending = true ;

  oq.populate_ban_list() ; 
end

function oq.onShadeHide(f)
  oq.tremove_value( getglobal("UISpecialFrames"), f:GetName() ) ;
  tinsert( getglobal("UISpecialFrames"), oq.ui:GetName() ) ;
end

function oq.onShadeShow(f)
  tinsert( getglobal("UISpecialFrames"), f:GetName() ) ;
  oq.tremove_value( getglobal("UISpecialFrames"), oq.ui:GetName() ) ;
end

function oq.create_ui_shade()
  if (oq.ui_shade ~= nil) then
    return oq.ui_shade ;
  end
  local parent = oq.ui ;
  local cx = floor(parent:GetWidth()) ;
  local cy = floor(parent:GetHeight()) + 30 + 10 ;
  local f = oq.panel( parent, "Shade", 0, -10, cx, cy ) ;
  f:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background", 
                 edgeFile=nil, 
                 tile=true, tileSize = 16, edgeSize = 16,
                 insets = { left = 1, right = 1, top = 1, bottom = 1 }
                 })
  f:SetBackdropColor( 0.2, 0.2, 0.2, 0.75 ) ;
  f:SetFrameLevel( 125 ) ;
  f:EnableMouse(true) ;
  f:SetScript( "OnShow", function(self) oq.onShadeShow(self) ; end ) ;
  f:SetScript( "OnHide", function(self) oq.onShadeHide(self) ; end ) ;
  oq.onShadeShow(f) ; -- first time
  oq.ui_shade = f ;

-- HELP PLATE?
-- http://wowprogramming.com/utils/xmlbrowser/live/AddOns/Blizzard_TalentUI/Blizzard_TalentUI.lua
-- HelpPlate_Show
-- HelpPlate_Hide
  
  return oq.ui_shade ;
end

function oq.create_tab_setup() 
  local x, y, cx, cy, x2 ;
  local parent = OQTabPage4 ;
  
  parent:SetScript( "OnShow", function() oq.populate_tab_setup() ; end ) ;
  parent:SetScript( "OnHide", function() oq.onhide_tab_setup() ; end ) ;
  x  = 20 ;
  y  = 30 ;
  cy = 25 ;
  local t = oq.label( parent, x, y, 400, 30, OQ.SETUP_HEADING ) ;
  t:SetFont(OQ.FONT, 14, "") ;
  t:SetTextColor( 1.0, 1.0, 1.0, 1 ) ;

  y = 65 ;
  x = 40 ;
  oq.label( parent, x, y, 200, cy, OQ.REALID_MOP ) ;  
  y = y + cy + 6 ;

  oq.label( parent, x, y, 200, cy, OQ.SETUP_GODARK_LBL ) ; 
  y = y + cy ;
  oq.label( parent, x, y, 200, cy, OQ.SETUP_REMOQADDED ) ; 
  y = y + cy ;

  x  = parent:GetWidth() - 225 ;
  y  = 25 ;  
  cy = 20 ;
  oq.tab5_ar = oq.checkbox( parent, x, y,  23, cy, 200, OQ.SETUP_AUTOROLE, (OQ_toon.auto_role == 1), 
               function(self) oq.toggle_auto_role( self ) ; end ) ;
  y = y + cy ;
  oq.tab5_cp = oq.checkbox( parent, x, y,  23, cy, 200, OQ.SETUP_CLASSPORTRAIT, (OQ_toon.class_portrait == 1), 
               function(self) oq.toggle_class_portraits( self ) ; end ) ;
  y = y + cy ;
  oq.tab5_ok2submit_btag = oq.checkbox( parent, x, y,  23, cy, 200, OQ.SETUP_OK2SUBMIT_BTAG, (OQ_data.ok2submit_tag == 1), 
               function(self) oq.toggle_btag_submit( self ) ; end ) ;
  y  = y + cy ;
  oq.tab5_autoaccept_mesh_request = oq.checkbox( parent, x, y,  23, cy, 200, OQ.SETUP_AUTOACCEPT_MESH_REQ, (OQ_data.autoaccept_mesh_request == 1), 
               function(self) oq.toggle_autoaccept_mesh_request( self ) ; end ) ;
  y  = y + cy ;
  oq.tab5_autojoin_oqgeneral = oq.checkbox( parent, x, y,  23, cy, 200, OQ.SETUP_AUTOJOIN_OQGENERAL, (OQ_data.auto_join_oqgeneral == 1), 
               function(self) oq.toggle_autojoin_oqgeneral( self ) ; end ) ;
 
  x = 40 ;
  y  = parent:GetHeight() - 185 ;
  cx = 200 ;
  cy = 25 ;
  oq.label( parent, x, y, 225, cy*2, OQ.SETUP_ALTLIST ) ; 

  x  = 250 ;

  local f = oq.CreateFrame( "Frame", "OQTabPage4List", parent ) ;
  f:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background", 
                 edgeFile="Interface/Tooltips/UI-Tooltip-Border", 
                 tile=true, tileSize = 16, edgeSize = 16,
                 insets = { left = 1, right = 1, top = 1, bottom = 1 }
                 })
  f:SetBackdropColor(0.0,0.0,0.0,1.0);
  oq.setpos( f, 0, 0, 175, 150 ) ;
  oq.tab5_list = f ;

  f = oq.CreateFrame( "ScrollFrame", "OQTabPage4ListScrollBar", parent, "FauxScrollFrameTemplate" ) ;
  f:SetScript("OnVerticalScroll", function(self, offset) FauxScrollFrame_OnVerticalScroll(self, offset, 16, OQ_ModScrollBar_Update); end ) ;
  f:SetScript("OnShow", function(self) OQ_ModScrollBar_Update(self) ; end ) ;
  f:SetScrollChild( oq.tab5_list ) ;
  f:Show() ;
  oq.setpos( f, x, y, 175, f:GetParent():GetHeight() - (y+30) ) ;
  oq.tab5_scroller = f ;
  
  oq.tab5_add_alt = oq.button( parent, x+200, y, 75, cy, OQ.SETUP_ADD, function() StaticPopup_Show("OQ_AddToonName") ; end ) ;
  y = y + cy + 2 ;
  oq.tab5_add_mycrew = oq.button( parent, x+200, y, 75, cy, OQ.SETUP_MYCREW, function() oq.mycrew() ; end ) ;
  y = y + cy + 2 ;
  oq.tab5_clear = oq.button( parent, x+200, y, 75, cy, OQ.SETUP_CLEAR, function() oq.mycrew("clear") ; end ) ;
  if (oq.tab5_alts == nil) then
    oq.tab5_alts = {} ;
  end

  --
  -- edits and buttons
  --
  y  = 65 ; -- skip comment
  x  = 250 ;
  cy = 25 ;
  cx = 145 ;
  oq.tab5_bnet        = oq.editline( parent, "BnetAddress", x, y, cx-4, cy,  60 ) ; 
  y = y + cy + 6 ;
  oq.tab5_go_dark     = oq.button( parent, x-5, y, cx, cy, OQ.SETUP_GODARK, 
                                     function() oq.godark() ; end )
  y = y + cy ;
  oq.tab5_prune_bnet  = oq.button( parent, x-5, y, cx, cy, OQ.SETUP_REMOVENOW, 
                                     function() oq.remove_OQadded_bn_friends() ; end )
  oq.tab5_bnet:Disable() ;
  y = y + cy ;

  
  
  --
  --  geek corner
  --
  x  = parent:GetWidth() - 200 ;
  x2 = parent:GetWidth() -  90 ;
  y  = parent:GetHeight() - 42 ;
  cy = 20 ;
  oq.label( parent, x, y, 150, cy, OQ.PPS_SENT ) ;
  oq.tab5_oq_pktsent = oq.label( parent, x2, y, 60, cy, "0", "MIDDLE", "RIGHT" ) ; 
  oq.tab5_oq_send_queuesz = oq.label( parent, x-30, y, 24, cy, "--", "MIDDLE", "RIGHT" ) ; 
  y = y - cy ; -- moving up
 
  oq.label( parent, x, y, 150, cy, OQ.PPS_PROCESSED ) ;
  oq.tab5_oq_pktprocessed = oq.label( parent, x2, y, 60, cy, "0", "CENTER", "RIGHT" ) ; 
  y = y - cy ; -- moving up
  
  oq.label( parent, x, y, 150, cy, OQ.PPS_RECVD ) ;
  oq.tab5_oq_pktrecv = oq.label( parent, x2, y, 60, cy, "0", "CENTER", "RIGHT" ) ; 
  y = y - cy ; -- moving up

--[[  
  oq.tab5_oq_sk_dtime_err = oq.label( parent, x-26, y+4, 24, cy, OQ_REDX_ICON, "CENTER", "RIGHT" ) ; 
  oq.label( parent, x, y, 150, cy, OQ.OQSK_DTIME ) ;
  oq.tab5_oq_sk_dtime = oq.label( parent, x2-40, y, 100, cy, "0", "CENTER", "RIGHT" ) ; 
  y = y - cy ; -- moving up
]]--
  
  -- tag
  
  -- populate alt list
  oq.populate_alt_list() ; 
end

function oq.update_alltab_text() 
  OQMainFrameTab1:SetText( OQ.TAB_PREMADE       ) ; 
  OQMainFrameTab2:SetText( OQ.TAB_FINDPREMADE   ) ; 
  OQMainFrameTab3:SetText( OQ.TAB_CREATEPREMADE ) ; 
  OQMainFrameTab4:SetText( OQ.TAB_SETUP         ) ; 
  OQMainFrameTab5:SetText( OQ.TAB_BANLIST       ) ; 

  local nWaiting = oq.n_waiting() ;
  if (nWaiting > 0) then
    OQMainFrameTab6:SetText( string.format( OQ.TAB_WAITLISTN, nWaiting ) ) ;
  else
    OQMainFrameTab6:SetText( OQ.TAB_WAITLIST ) ;
  end
end


function oq.create_main_ui() 

  oq.filter_button = oq.create_filter_button( OQMainFrame ) ;
  
  ------------------------------------------------------------------------
  --  tab 1: current premade
  ------------------------------------------------------------------------
  oq.create_tab1() ;
  
  ------------------------------------------------------------------------
  --  tab 2: find premade
  ------------------------------------------------------------------------
  oq.create_tab2() ;
  
  ------------------------------------------------------------------------
  --  tab 3: create premade
  ------------------------------------------------------------------------
  oq.create_tab3() ;
    
  ------------------------------------------------------------------------
  --  tab 4: setup
  ------------------------------------------------------------------------
  oq.create_tab_setup() ;
  
  ------------------------------------------------------------------------
  --  tab 5: ban list
  ------------------------------------------------------------------------
  oq.create_tab_banlist() ;
  
  ------------------------------------------------------------------------
  --  tab 6: waiting list
  ------------------------------------------------------------------------
  oq.create_tab_waitlist() ;
  
  oq.update_alltab_text() ;
  
end

function oq.get_battle_tag()
  if (not BNConnected()) then
    local now = utc_time() ;
    oq._bnetdown_error_cnt = (oq._bnetdown_error_cnt or 0) + 1 ;
    if (oq._bnetdown_error_cnt < 3) then
      -- allow for 3 strikes before announcing.  
      -- b.net could just glitch for a few seconds, allow for recovery
      return nil ;
    end
    if (oq._bnetdown_error_tm == nil) or ((now - oq._bnetdown_error_tm) > 90) then
      oq._bnetdown_error_tm = now ;
      print( OQ_REDX_ICON ..L[" Battle.net is currently down."] ) ;
      print( OQ_REDX_ICON ..L[" oQueue will not function properly until Battle.net is restored."] ) ;
    end
    return nil ;
  end
  oq._bnetdown_error_cnt = nil ;
  oq._bnetdown_error_tm  = nil ;
  
  player_realid = select( 2, BNGetInfo() ) ;
  if (player_realid == nil) then
    local now = utc_time() ;
    if (oq._btag_error_tm == nil) or ((now - oq._btag_error_tm) > 120) then
      oq._btag_error_tm = now ;
      print( OQ_REDX_ICON ..L[" Please set your battle-tag before using oQueue."] ) ;
      print( OQ_REDX_ICON ..L[" Your battle-tag can only be set via your WoW account page."] ) ;
    end
    return nil ;
  end
  player_realid = strlower(player_realid) ;
  if (player_realid == strlower(OQ.SK_BTAG)) then
    oq._iam_scorekeeper = true ;
  end
  return player_realid ;
end

function oq.populate_tab2() 
  oq.get_battle_tag() ;
  oq.n_connections() ;
  oq.update_premade_count() ;
end

function oq.create_tab3_notice( parent )
  local pcx = parent:GetWidth() ;
  local pcy = parent:GetHeight() ;
  local cx = floor(pcx/2) ;
  local cy = floor(4*pcy/5) ;
  local f = oq.panel( parent, "Notice", floor((pcx - cx)/2), floor((pcy - cy)/2), cx, cy) ;
  f:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background", 
                 edgeFile="Interface/Tooltips/UI-Tooltip-Border", 
                 tile=true, tileSize = 16, edgeSize = 16,
                 insets = { left = 1, right = 1, top = 1, bottom = 1 }
                 })
  f:SetBackdropColor( 0.2, 0.2, 0.2, 1.0 ) ;
  f:SetAlpha( 1.0 ) ;
  oq.closebox( f, function(self) self:GetParent():GetParent():Hide() ; end ) ;

  local x = 15 ;
  local y = 20 ;
  for i,v in pairs(OQ.LFGNOTICE_DLG) do
    local s = v ;
    if (i ~= 2) then
      s = "|cFFE0E0E0".. v .."|r" ;
    end    
    local t = oq.label( f, x, y, cx-2*15, 20, string.format( s, dtstr ), "CENTER", "LEFT" ) ;
    t:SetFont(OQ.FONT, 16, "") ;
    y = y + 24 ;
  end
  
  f.ok_but = oq.button( f, floor((cx - 80)/2), cy - 50,  80, 32, "Okay", 
                        function(self) 
                          self:GetParent():GetParent():Hide() ; 
                        end ) ;
  return f ;
end

function oq.create_tab3_shade( parent )
  local cx = floor(parent:GetWidth()) ;
  local cy = floor(parent:GetHeight()) ;
  local f = oq.panel( parent, "Shade", 0, 0, cx, cy ) ;
  f:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background", 
                 edgeFile=nil, 
                 tile=true, tileSize = 16, edgeSize = 16,
                 insets = { left = 1, right = 1, top = 1, bottom = 1 }
               })
  f:SetBackdropColor( 0.2, 0.2, 0.2, 0.75 ) ;
  f:SetFrameLevel( 125 ) ;
  f:EnableMouse(true) ;
  return f ;
end

function oq.populate_tab3() 
  oq.get_battle_tag() ;
  
  oq.tab3_lead_name:SetText( player_name or "" ) ;
  oq.tab3_rid      :SetText( player_realid or "" ) ;
  
  local now = utc_time() ;
  if (OQ_toon.tab3_notice == nil) or (OQ_toon.tab3_notice < now) then
    -- notice
    OQ_toon.tab3_notice = now + 7*24*60*60 ; -- once per week
    if (oq.ui_tab3_shade == nil) then
      oq.ui_tab3_shade = oq.create_tab3_shade( OQTabPage3 ) ;
    end
    if (oq.ui_tab3_notice == nil) then
      oq.ui_tab3_notice = oq.create_tab3_notice( oq.ui_tab3_shade ) ;
      oq.ui_tab3_shade:SetScript( "OnShow", function(self) oq.onShadeShow(self) ; end ) ;
      oq.ui_tab3_shade:SetScript( "OnHide", function(self) oq.onShadeHide(self) ; end ) ;
      oq.onShadeShow(oq.ui_tab3_shade) ; -- first time
    end
    oq.ui_tab3_shade:Show() ;
    if (oq.ui_tab3_warning) then oq.ui_tab3_warning:Hide() ; end
    oq.ui_tab3_notice:Show() ;    
  elseif (oq.ui_tab3_shade ~= nil) and (oq.ui_tab3_shade:IsVisible()) then
    oq.ui_tab3_shade:Hide() ;
    if (oq.ui_tab3_notice) then oq.ui_tab3_notice:Hide() ; end
    if (oq.ui_tab3_warning) then oq.ui_tab3_warning:Hide() ; end
  end
end

function oq.populate_tab_setup() 
  oq.get_battle_tag() ;

  oq.tab5_bnet:SetText( player_realid or "" ) ;
  if (_oqgeneral_id) then
    SetSelectedDisplayChannel( _oqgeneral_id ) ;
  end
  
--  oq.populate_dtime() ;
end

function oq.onhide_tab_setup()
  OQ_data.realid = player_realid ;
end

function oq.on_party_event( msg, sender, lang, line_id )
  oq.echo_party_msg( sender, msg ) ;
end

function oq.is_my_req_token( req_tok )
  return oq.token_was_seen( req_tok ) ;
end

function oq.bnfriend_note( presenceId )
  if (presenceId == nil) or (presenceId == 0) then
    return nil ;
  end
  local noteText = select( 12, BNGetFriendInfoByID(presenceId)) ;
--  pid, givenName, surname, toonName, toonID, client, isOnline, lastOnline, 
--  isAFK, isDND, messageText, noteText, isFriend, unknown = BNGetFriendInfoByID(presenceID) ;
  return noteText ;
end

function oq.on_bnet_friend_invite() 
  local nInvites = BNGetNumFriendInvites() ; 
  if (nInvites == 0) then 
    return ;
  end
  -- 
  -- do the list backwards incase there are multiple
  --
  local valid_req = nil ;
  local is_lead = nil ;
  for i=nInvites,1,-1 do
    local presenceId, name, surname, message, timeSent, days = BNGetFriendInviteInfo( i ) ; 
    if ((message ~= nil) and (message ~= "")) then
      local msg_type = message:sub(1,#OQ_MSGHEADER) ;
      if (msg_type == OQ_MSGHEADER) then
        -- OQ message.  check note to see if i initiated it
        local msg = message:sub( message:find(OQ_MSGHEADER)+1, -1 ) ;
        local req_tok = nil ;
        local p = msg:find("#tok:") ;
        if (p) then
          req_tok = msg:sub( p+5, msg:find(",", p+5 )-1 ) ;
        end
        if (req_tok ~= nil) and (oq.is_my_token( req_tok )) then
          -- bn_realfriend_invite( r.realid, "#tok:".. req_token ..",#lead" ) ;
          if (msg:find("#lead")) then
            -- inviting to be group lead, bnfriend must stay
            BNAcceptFriendInvite(presenceId) ;
            oq.set_bn_enabled( presenceId ) ;
            oq.timer_oneshot( 1.5, oq.bn_check_online ) ;
            if (oq.bnfriend_note( presenceId ) == nil) then
              oq.timer_oneshot( 2, BNSetFriendNote, presenceId, "OQ,leader" ) ;    
            end                  
          elseif (msg:find("#grp:")) then
            -- inviting to be group member, bnfriend is temporary until grouped
            -- "#tok:".. req_token_ ..",#grp:".. my_group ..",#nam:".. player_name .."-".. player_realm 
            p = msg:find("#grp:") ;
            local group_id = msg:sub( p+5, p+5 ) ;
            if (group_id ~= nil) then
              my_group = tonumber(group_id) ;
              oq.ui_player() ;
              oq.update_my_premade_line() ;
              local lead = oq.raid.group[ my_group ].member[1] ;
              p = msg:find("#nam:") ;
              local n = msg:sub( p+5, -1 ) ;
              lead.name  = n:sub( 1, n:find("-")-1 ) ;
              lead.realm = n:sub( n:find("-")+1, -1 ) ;
              lead.realm = oq.realm_uncooked(lead.realm) ;
              BNAcceptFriendInvite(presenceId) ;

              oq.set_bn_enabled( presenceId ) ;
              oq.timer_oneshot( 1.5, oq.bn_check_online ) ;
              -- giving it some time to set the removal note
              local note = oq.bnfriend_note( presenceId ) ;
              if (note == nil) or (note:sub(1,7) == "REMOVE ") then
                oq.timer_oneshot( 1, BNSetFriendNote, presenceId, "" ) ; -- clear any previous note
                oq.timer_oneshot(15, BNSetFriendNote, presenceId, "REMOVE OQ" ) ;
              end
            end
          end
        else  -- not my token, inc OQ msg
          -- msg thru invite note, decline invite and process msg
           -- now process
           
           -- the b-tag is not sent along with the invite request (lame)
--          if (oq.is_banned( rid_ )) then
--            return ;
--          end
          oq._sender  = name .." ".. tostring(surname) ;
          _source     = "bnfinvite" ;
          _oq_note    = "OQ,leader" ;
          _oq_msg     = nil ;
          _ok2relay   = nil ; 
          _ok2decline = true ;
          _ok2accept  = true ;
          oq.process_msg( oq._sender, message ) ;
          oq.post_process() ;

          -- valid OQ msg, remove from friend-req-list 
          if (_ok2decline) then
            BNDeclineFriendInvite( presenceId ) ; 
          elseif (_ok2accept) then
            BNAcceptFriendInvite(presenceId) ;
            oq.set_bn_enabled( presenceId ) ;
            oq.timer_oneshot( 1.5, oq.bn_check_online ) ;
            oq.timer_oneshot( 2, BNSetFriendNote, presenceId, _oq_note ) ;
          end
        end
      end
    end
  end
end

function oq.on_disband( raid_tok, token, local_override )
  oq._error_ignore_tm  = GetTime() + 5 ;
  if (oq.token_was_seen( token ) and (local_override == nil)) then
    _ok2relay = nil ; 
    return ;
  end
  oq.token_push( token ) ;
  oq.remove_premade( raid_tok ) ;
  -- clear from cache
  if (raid_tok) and (OQ_data._premade_info) then
    OQ_data._premade_info[ raid_tok ] = nil ; 
  end
  if (oq.raid.raid_token ~= raid_tok) then
    -- not my raid
    return ;
  end
  oq.raid_cleanup() ;
end

local oq_find_request = {} ;
--
-- this is called in response to a "find" message
--
function oq.queue_find_request( reply_token_, faction_, level_range_, realm_ )
  if (oq.token_was_seen( reply_token_ )) then
    _ok2relay = nil ;
    return ;
  end
  oq.token_push( reply_token_ ) ;
  realm_ = oq.realm_uncooked(realm_) ;

  -- to be processed within the next 10 seconds
  local now  = utc_time() ;
  local when = now + random( 3, 10 ) ;
  local tok  = reply_token_ ..".".. (utc_time() % 1000) ;
  oq_find_request[ tok ] = { reply_token = reply_token_, 
                             faction = faction_,
                             level_range = level_range_,
                             realm = realm_,
                             tm = when 
                           } ;
  oq.send_my_premade_info() ;
end

--
-- each group slot is 2 characters in group_hp representing the max_hp of the unit
-- max_hp of 0 for the slot means that slot is empty
-- this is reported by every group leader and echoe'd by the raid leader
-- ####
function oq.on_group_hp( raid_token, group_id, group_hp )
  if (oq.raid.raid_token ~= raid_token) then
    return ;
  end

  local a, b, hp ;
  group_id = tonumber(group_id) ;
  for i=1,5 do
    a  = oq_mime64[ group_hp:sub((i-1)*2+1,(i-1)*2+1) ] ;
    b  = oq_mime64[ group_hp:sub((i-1)*2+2,(i-1)*2+2) ] ;
    hp = (a * 36) + b ;
    if (hp == 0) then
      -- deadspot
      oq.raid_cleanup_slot( group_id, i ) ;
    else
      oq.raid.group[ group_id ].member[ i ].hp = hp ;
    end
  end
end

-- 
-- called by party_leader (my_group == group_id)
-- dead slots have hp of 0
--
function oq.get_group_hp()
  if ((my_group < 1) or (my_slot < 1)) then
    return ;
  end
  local spots = "" ;
  local hp, n, a, b ;
  for i = 1,5 do
    if (oq.raid.group[my_group].member) and (oq.raid.group[my_group].member[i]) then
      n  = oq.raid.group[ my_group ].member[ i ].name ;
      hp = 0 ;
      if ((n ~= nil) and (n ~= "held") and (n ~= "n/a") and (oq.raid.group[ my_group ].member[ i ].realm ~= nil)) then
        if (oq.raid.group[ my_group ].member[ i ].realm ~= player_realm) then
          n = n .."-".. oq.raid.group[ my_group ].member[ i ].realm ;
        end
        hp = UnitHealthMax( n ) ;
      end
      a = floor((hp / 1000) / 36) ;
      b = floor((hp / 1000) % 36) ;
      oq.raid.group[ my_group ].member[ i ].hp = (a * 36) + b ;
      spots = spots .."".. oq_mime64[ a ] .."".. oq_mime64[ b ] ;

      oq.set_status_online( my_group, i, (hp > 0) ) ;

      if (hp == 0) then
      -- deadspot
--      oq.raid_cleanup_slot( my_group, i ) ;
      end
    end
  end
  return spots ;
end

function oq.send_group_hp()
  if (oq.raid.raid_token == nil) then
    return ; 
  end
  if (not oq.iam_party_leader() and not oq.iam_raid_leader()) then
    return ;
  end
  local spots = oq.get_group_hp() ;
  if (spots) then
    oq.raid_announce( "group_hp,".. 
                       oq.raid.raid_token ..","..
                       my_group ..","..
                       spots
                    ) ;
  end
end


function oq.on_leave_group( name, realm )
  -- clean up the raid ui
  for i=1,8 do
    for j=1,5 do
      local mem = oq.raid.group[i].member[j] ;
      if ((mem ~= nil) and (mem.name == name) and (mem.realm == realm)) then
        -- clean out the locker
        mem.name   = nil ;
        mem.class  = "XX" ;
        mem.realm  = nil ;
        mem.realid = nil ;
        oq.set_group_member( i, j, nil, nil, "XX", nil, "0", "0" ) ;
        oq.set_deserter( i, j, nil ) ;
        oq.set_role( i, j, OQ.ROLES["NONE"] ) ;
        if (j == 1) then
        
          oq.group_left( i ) ;
          oq.raid_announce( "remove_group,".. i ) ;          
        else
          oq.member_left( i, j ) ;
        end
        return ;
      end
    end
  end
end

function oq.on_leave_slot( g_id, slot )
  g_id = tonumber(g_id) ;
  slot = tonumber(slot) ;
  if (g_id == 0) or (slot == 0) then
    return ;
  end
  local mem = oq.raid.group[g_id].member[slot] ;
  if (mem == nil) then
    return ;
  end
  mem.name   = nil ;
  mem.class  = "XX" ;
  mem.realm  = nil ;
  mem.realid = nil ;
  oq.set_group_member( g_id, slot, nil, nil, "XX", nil ) ;
  oq.set_deserter( g_id, slot, nil ) ;
  oq.set_role( g_id, slot, OQ.ROLES["NONE"] ) ;
  if (slot == 1) then
    oq.group_left( g_id ) ;
    oq.raid_announce( "remove_group,".. g_id ) ;
  else
    oq.member_left( g_id, slot ) ;
  end
end

--
-- intended for group leader 
--
function oq.on_proxy_invite( group_id, slot_, enc_data_, req_token_ ) 
  group_id = tonumber( group_id ) ;
  slot     = tonumber( slot ) ;
  if (not oq.iam_party_leader()) or (group_id == nil) or (group_id ~= my_group) then
    return ;
  end
  if (oq.raid.raid_token == nil) or (_source == "bnfinvite") or (_source == "oqgeneral") or (_source == "party") then
    return ;
  end
  if (not oq.iam_raid_leader()) and (oq.raid.type ~= OQ.TYPE_BG) then
    return ; 
  end
  local enc_data = oq.encode_data( "abc123", 
                                   player_name, 
                                   player_realm, 
                                   player_realid ) ;
  local msg = "OQ,".. 
              OQ_VER ..",".. 
              "W1,"..
              "1,"..
              "proxy_target,".. 
              group_id ..","..
              slot_ ..","..
              enc_data ..","..
              oq.raid.raid_token ..","..
              req_token_ ;
              
  -- this is the target name, realm, and real-id
  local  name, realm, rid_ = oq.decode_data( "abc123", enc_data_ ) ;
  if (realm == player_realm) then
    -- on my realm, let player know he's in my group then invite him
    oq.realid_msg( name, realm, rid_, msg ) ;
    oq.timer_oneshot( 1.5, oq.InviteUnit, name, realm ) ;
    oq.timer_oneshot( 2.5, oq.brief_group_members ) ;  
    return ;
  end
  
  local n = name .."-".. realm ;
  if (oq.pending_invites == nil) then
    oq.pending_invites = {} ;
  end
  oq.pending_invites[ n ] = { raid_tok = oq.raid.raid_token, gid = my_group, slot = slot_, rid = rid_, req_token = req_token_ } ;
  
  local pid = oq.bnpresence( name .."-".. realm ) ;
  if (pid ~= 0) then
    oq.realid_msg( name, realm, rid_, msg ) ;
    oq.timer_oneshot( 1.5, oq.InviteUnit, name, realm ) ;
    oq.timer_oneshot( 2.5, oq.brief_group_members ) ;  
    return ;
  end
  
  -- if reaches here, player is not b-net friend or not on realm... must b-net friend then invite
  oq.bn_realfriend_invite( name, realm, rid_, "#tok:".. req_token_ ..",#grp:".. my_group ..",#nam:".. player_name .."-".. tostring(oq.realm_cooked(player_realm)) ) ; 

  _ninvites = _ninvites + 1 ;
  oq.timer( "invite_to_group".. _ninvites, 2, oq.timer_invite_group_member, true, name, realm, rid_, msg, my_group, slot_, req_token_ ) ;  
end

--
-- intended for recruit  
--
function oq.on_proxy_target( group_id, slot, enc_data, raid_token, req_token ) 
  group_id = tonumber( group_id ) ;
  slot     = tonumber( slot ) ;

  if (not oq.is_my_token( req_token )) then
    return ;
  end

  local  gl_name, gl_realm, gl_rid = oq.decode_data( "abc123", enc_data ) ;
  my_group = group_id ;
  my_slot  = slot ;
  oq.ui_player() ;
  oq.update_my_premade_line() ;
  
  -- set group leader to prepare for invite
  oq.raid.group[ group_id ].member[ 1 ].name   = gl_name ;
  oq.raid.group[ group_id ].member[ 1 ].realm  = gl_realm ;
  oq.raid.group[ group_id ].member[ 1 ].realid = gl_rid ;
  oq.raid.raid_token = raid_token ;

  if (gl_realm ~= player_realm) then
    oq.bn_realfriend_invite( gl_name, gl_realm, gl_rid ) ; -- will need to be b-net friends to invite cross-realm (!!!!)
  end
end

--
-- fired by raid leader
--
function oq.proxy_invite( group_id, slot, name, realm, rid, req_token ) 
  if ((oq.raid.group[ group_id ].member[1].name == nil) or (oq.raid.group[ group_id ].member[1].name == "-")) then
    return ;
  end

  --
  -- creating new msgs... ok to turn off sender info
  --
  oq._sender = nil ;

  --[[ if group to be invited to isn't my group, send message out for that group-leader to do the invite ]]--
  if (my_group == group_id) then
    local enc_data = oq.encode_data( "abc123", name, realm, rid ) ;
    oq.on_proxy_invite( group_id, slot, enc_data, req_token ) ;
  else
    -- not my group, ask the other group leader to invite
    msg_tok = "W".. oq.token_gen() ;
    oq.token_push( msg_tok ) ;

    enc_data = oq.encode_data( "abc123", name, realm, rid ) ;
    local m = "OQ,".. 
              OQ_VER ..",".. 
              msg_tok ..","..
              OQ_TTL ..","..
              "proxy_invite,".. 
              group_id ..","..
              slot ..","..
              enc_data ..","..
              req_token ;

    local lead = oq.raid.group[ group_id ].member[1] ;
    oq.realid_msg( lead.name, lead.realm, lead.realid, m ) ;
  end
end

function oq.valid_rid( rid )
   if (rid == nil) or (rid == OQ_NOEMAIL) then
      return nil ;
   end
   -- good battle-tag has a '#' in the middle
   if (rid:find("#") ~= nil) then
      -- battle-tag
      return true ;
   end
   if (rid:find("+") or rid:find("&")) then
      return nil ;
   end
   -- good email has a '@' and a '.'
   local f1 = rid:find("@") ;
   if (f1 ~= nil) then
      local f2 = rid:find(".", f1) ;
      if (f2 ~= nil) then
         -- possible email 
         return true ;
      end
   end
   return nil ;
end

-- will need to real-id friend the person in order to invite  (!!!!)
function oq.bn_realfriend_invite( name, realm, rid, extra_note ) 
  if ((rid == nil) or (rid == OQ_NOEMAIL)) then
    return ;
  end
  if (not oq.valid_rid( rid )) then
    message( OQ.BAD_REALID .." ".. tostring(rid) ) ;
    return ;
  end
  
  oq.bntoons() ;
  local friend = OQ_data.bn_friends[ name .."-".. realm ] ;
  if (friend ~= nil) and friend.isOnline and friend.oq_enabled then
    -- won't try to add if friended at all.  oq enabled or not
    return ;
  end
  if (friend ~= nil) and (friend.presenceId == 0) then
    return ;
  end
  
  -- if already friended, ok to re-try.  will fail silently (well, red text top center)
  local msg = "OQ,".. oq.raid.raid_token ;
  if (extra_note) then
    msg = msg ..",".. extra_note ;
  end
  oq.BNSendFriendInvite( rid, msg, "OQ,mesh node", name, realm ) ;
  
  oq.timer_oneshot( 15, oq.set_note_if_null, name, realm, "OQ,".. oq.raid.raid_token ) ;
end

function oq.set_note_if_null( name, realm, note )
  oq.bntoons() ;
  local friend = OQ_data.bn_friends[ name .."-".. realm ] ;
  if (friend == nil) or (not friend.isOnline) then
    return ;
  end
  local pid = friend.presenceID or 0 ;
  if (oq.bnfriend_note( pid ) == nil) then
    BNSetFriendNote( pid, note ) ;
  end
end

function oq.raid_identify_self()
  oq.raid_announce( "identify,0" ) ;
end

function oq.brief_group_lead( group_id ) 
  local name  = oq.raid.group[group_id].member[1].name ;
  local realm = oq.raid.group[group_id].member[1].realm ;
  if (name == nil) or (realm == nil) then
    return ;
  end
  oq._sender = nil ;
  for i=1,8 do
    if (i ~= group_id) then
      local grp = oq.raid.group[i] ;
      if (grp._names ~= nil) then
        oq.whisper_msg( name, realm, grp._names ) ;
      end
      if (grp._stats ~= nil) then
        oq.whisper_msg( name, realm, grp._stats ) ;
      end
    end
  end
end

function oq.IsRaidLeader()
  if (oq._instance_type and ((oq._instance_type == "party") or (oq._instance_type == "raid"))) then
    return oq.iam_raid_leader() ; -- OQ leader is the lead
  else
    return UnitIsGroupLeader("player") ;  -- pandaria update
  end
end

local last_group_brief = 0 ;
function oq.group_lead_bookkeeping()
  if (my_slot ~= 1) or (_inside_bg) then
    return ;
  end
  local now = utc_time() ;
  if (now < (last_group_brief + OQ_BOOKKEEPING_INTERVAL)) then
    return ;
  end
  last_group_brief = now ;
  
  -- update online status
  for slot=2,5 do
    local m = oq.raid.group[my_group].member[slot] ;
    if (m.name) and (m.name ~= "-") then
      local n = m.name ;
      if (m.realm ~= player_realm) then
        n = n .."-".. m.realm ;
      end
      
      -- online status check
      oq.set_status_online( my_group, slot, UnitIsConnected( n ) ) ;
    end
  end
end
  
function oq.ready_check( g_id, slot, stat )
  g_id = tonumber( g_id ) ;
  slot = tonumber( slot ) ;
  stat = tonumber( stat ) ;
  if (g_id == 0) or (slot == 0) then
    return ;
  end
  oq.raid.group[ g_id ].member[ slot ].check = stat ;
  oq.set_textures( g_id, slot ) ;
end

function oq.on_ready_check_complete()
  for grp=1,8 do
    for s=1,5 do
      oq.raid.group[grp].member[s].check = OQ.FLAG_CLEAR ;
      oq.set_textures( grp, s ) ;
    end
  end
end

local last_brief_tm = 0 ;
function oq.brief_group_members() 
  local now = utc_time() ;
  if (my_slot ~= 1) or (now < (last_brief_tm + OQ_BRIEF_INTERVAL) or (_inside_bg)) then
    return ;
  end
  last_brief_tm = now ;
  
  local mygrp = oq.raid.group[my_group] ;
  
  -- send party info
  local enc_data = oq.encode_data( "abc123", oq.raid.leader, oq.raid.leader_realm, oq.raid.leader_rid ) ;
  oq.party_announce( "party_join,".. 
                      my_group ..","..
                      oq.encode_name( oq.raid.name ) ..",".. 
                      oq.raid.leader_class ..",".. 
                      enc_data ..",".. 
                      oq.raid.raid_token  ..",".. 
                      oq.encode_note( oq.raid.notes )
                   ) ;

  -- send party slots
  local msg = "party_slots,"..
               my_group ..",".. 
               oq.raid.type ;
  for i=1,5 do
    local name = mygrp.member[i].name ;
    if (name == nil) or (name == "") or (name == "-") then
      name = "-" ;
    end
    msg = msg ..",".. name ;
  end 
  oq.party_announce( msg ) ;
  
  -- send group info from other known groups
  oq._sender = nil ;
  for i=1,8 do
    local grp = oq.raid.group[i] ;
    if (grp._names ~= nil) then
      oq.party_announce( grp._names ) ;
    end
    if (grp._stats ~= nil) then
      oq.party_announce( grp._stats ) ;
    end
  end
end

--
--  received by the raid-leader
--
function oq.on_invite_accepted( raid_token, group_id, slot, class, enc_data, req_token )
  if (oq.raid.raid_token ~= raid_token) then
    return ;
  end
  if (not oq.iam_raid_leader()) then
    return ;
  end

  group_id = tonumber( group_id ) ;
  slot     = tonumber( slot ) ;

  local  name, realm, rid = oq.decode_data( "abc123", enc_data ) ;
  oq.set_group_member( group_id, slot, name, realm, class, rid ) ;

  if (slot == 1) then
    -- unit is new group leader, brief him
    oq.timer( "brief_leader", 1.5, oq.brief_group_lead, nil, group_id ) ;
    return ;
  end 

  -- invite (by proxy if needed)
  if ((realm == player_realm) and (group_id == my_group)) then
    -- direct invite ok
    local enc = oq.encode_data( "abc123", name, realm, rid ) ;  -- rid not needed, as the invite goes to this realm
    oq.on_proxy_invite( group_id, slot, enc, req_token ) ;
  else
    oq.proxy_invite( group_id, slot, name, realm, rid, req_token ) 
  end
  
  -- not the best, as we don't have resil and ilevel, but that will be updated when we queue.
-- this is on a 60 sec timer
--  oq.send_my_premade_info() ;  
end

function oq.update_my_premade_line()
  if (oq.raid.raid_token == nil) then
    return ;
  end
  
  -- update status 
  local raid = oq.premades[ oq.raid.raid_token ] ;
  if (raid ~= nil) then
    local s = raid.stats ;
    local line = oq.find_premade_entry( raid.raid_token ) ;
    if (line ~= nil) then
      line.req_but:Disable() ;
      if (raid.has_pword) then
        line.has_pword.texture:Show() ;
        line.has_pword.texture:SetTexture( OQ_KEY ) ;
      else
        line.has_pword.texture:Hide() ;
        line.has_pword.texture:SetTexture( nil ) ;
      end
    end  
  end
  
  local now = utc_time() ;
  if (oq._last_btag_send == nil) or ((now - oq._last_btag_send) > 30) or ((my_group * 10 + my_slot) ~= oq._last_btag_pos) then
    oq._last_btag_send = now ;
    oq._last_btag_pos  = my_group * 10 + my_slot ;
    oq.send_my_btag_to_raid() ;
  end
end

function oq.on_invite_group_lead( req_token, group_id, raid_name, raid_leader_class, enc_data, raid_token, raid_notes )
  if (not oq.is_my_token( req_token )) then
    return ;
  end
  local  raid_leader, raid_leader_realm, raid_leader_rid = oq.decode_data( "abc123", enc_data ) ;
  _received = true ;
  group_id = tonumber(group_id) ;
  raid_name  = oq.decode_name( raid_name ) ;
  raid_notes = oq.decode_note( raid_notes ) ;
  if (not raid_notes) then
    raid_notes = "" ;
  end
  
  if (oq.iam_raid_leader() and (oq.raid.raid_token ~= raid_token)) then
    -- tried to start my own premade, but join another instead.  
    -- my original premade must be disbanded
    oq.raid_disband() ;
  end

  -- activate in-raid only procs
  oq.procs_join_raid() ;
  

  my_group             = group_id ;
  my_slot              = 1 ;
  oq.raid.name         = raid_name ;
  oq.raid.leader       = raid_leader ;
  oq.raid.leader_class = raid_leader_class ;
  oq.raid.leader_realm = raid_leader_realm ;
  oq.raid.leader_rid   = raid_leader_rid ;
  oq.raid.notes        = (raid_notes or "") ;
  oq.raid.raid_token   = raid_token ;
  
  oq.tab1_name :SetText( raid_name ) ;
  oq.tab1_notes:SetText( raid_notes ) ;

  oq.set_group_lead( group_id, player_name, player_realm, player_class, player_realid ) ;
  local me = oq.raid.group[group_id].member[1] ;
  me.name   = player_name ;
  me.realm  = player_realm ;
  me.level  = player_level ;
  me.class  = player_class ;
  me.resil  = player_resil ;
  me.ilevel = player_ilevel ;
  me.realid = player_realid ;
  me.check  = OQ.FLAG_CLEAR ;

  oq.send_invite_accept( raid_token, group_id, my_slot, player_name, player_class, player_realm, player_realid, req_token ) ;
  
  -- assign slots to the party members
  oq.party_assign_slots( group_id, enc_data ) ;
  
  -- remove myself from other waitlists
  oq.clear_pending() ;
  oq.ui_player() ;
  oq.update_my_premade_line() ;
  
  -- null out the group stats will force stats send
  last_stats = nil ;
  oq.raid.group[ my_group ]._stats = nil ;
  oq.raid.group[ my_group ]._names = nil ; 
  
  -- make sure we don't decline the friend request
  _ok2decline = nil ;
end

function oq.party_assign_slots( group_id, enc_data )
  local  n_members = oq.GetNumPartyMembers() ;
  if (n_members == 0) then
    return ;
  end
  
  -- send party members raid info and slot assignment
  oq.party_announce( "party_join,".. 
                      group_id ..","..
                      oq.encode_name( oq.raid.name ) ..",".. 
                      oq.raid.leader_class ..",".. 
                      enc_data ..",".. 
                      oq.raid.raid_token  ..",".. 
                      oq.encode_note( oq.raid.notes )
                   ) ;
  local msg = "party_slots,"..                   
               group_id ..","..
               oq.raid.type ..","..
               player_name ;
  for i=1,4 do
    local name = GetUnitName( "party".. i, true )
    if (name) then
      if (name:find(" - ") ~= nil) then
        name  = name:sub(1,name:find(" - ")-1) ;
      end
    else
      name = "-" ;
    end
    msg = msg ..",".. name ;
  end 
  
  oq.party_announce( msg ) ;
end

function oq.on_raid_join( raid_name, premade_type, raid_leader_class, enc_data, raid_token, raid_notes )
  if (_msg_type ~= 'R') then
    return ;
  end
  
  local  raid_leader, raid_leader_realm, raid_leader_rid = oq.decode_data( "abc123", enc_data ) ;
  _received = true ;

  raid_name  = oq.decode_name( raid_name ) ;
  raid_notes = oq.decode_note( raid_notes ) ;

  oq.raid.name         = raid_name ;
  oq.raid.leader       = raid_leader ;
  oq.raid.leader_class = raid_leader_class ;
  oq.raid.leader_realm = raid_leader_realm ;
  oq.raid.leader_rid   = raid_leader_rid ;
  oq.raid.notes        = raid_notes or "" ;
  oq.raid.raid_token   = raid_token ;

  oq.set_group_member( 1, 1, raid_leader, raid_leader_realm, raid_leader_class, raid_leader_rid, "0", "0" ) ;
  
  oq.tab1_name :SetText( raid_name ) ;
  oq.tab1_notes:SetText( raid_notes ) ;
  
  -- activate in-raid only procs
  oq.procs_join_raid() ;  
  oq.set_premade_type( premade_type ) ;
  oq.ui_player() ;
  oq.update_my_premade_line() ;
  oq.timer_oneshot( 3, oq.send_my_btag_to_raid ) ;
end

function oq.on_party_join( group_id, raid_name, raid_leader_class, enc_data, raid_token, raid_notes )
  if (_msg_type ~= 'P') then
    return ;
  end
  
  local  raid_leader, raid_leader_realm, raid_leader_rid = oq.decode_data( "abc123", enc_data ) ;
  _received = true ;

  raid_name  = oq.decode_name( raid_name ) ;
  raid_notes = oq.decode_note( raid_notes ) ;

  my_group             = tonumber(group_id) ;
  oq.raid.name         = raid_name ;
  oq.raid.leader       = raid_leader ;
  oq.raid.leader_class = raid_leader_class ;
  oq.raid.leader_realm = raid_leader_realm ;
  oq.raid.leader_rid   = raid_leader_rid ;
  oq.raid.notes        = raid_notes or "" ;
  oq.raid.raid_token   = raid_token ;
  
  oq.set_group_member( 1, 1, raid_leader, raid_leader_realm, raid_leader_class, raid_leader_rid, "0", "0" ) ;

  oq.tab1_name :SetText( raid_name ) ;
  oq.tab1_notes:SetText( raid_notes ) ;
  
  -- activate in-raid only procs
  oq.procs_join_raid() ;  
  oq.ui_player() ;
  oq.update_my_premade_line() ;
  oq.timer_oneshot( 3, oq.send_my_btag_to_raid ) ;
end

function oq.on_party_slots( group_id, premade_type, n1, n2, n3, n4, n5 )
  if (_msg_type ~= 'P') then
    return ;
  end
  if (premade_type ~= nil) then
    oq.set_premade_type( premade_type ) ;
  end
  oq.on_party_slot( n1, group_id, 1 ) ;
  oq.on_party_slot( n2, group_id, 2 ) ;
  oq.on_party_slot( n3, group_id, 3 ) ;
  oq.on_party_slot( n4, group_id, 4 ) ;
  oq.on_party_slot( n5, group_id, 5 ) ;
end

function oq.player_demographic()
  local _, raceId = UnitRace( "player" ) ;
  local gender = UnitSex( "player" ) ; 
  -- gender can now be: 2(male) 3(female) or 1(neutrum/unknown) ......
  if (gender == 2) then
    gender = 0 ; -- represented in a bit flag, 0 and 1 are better
  else
    gender = 1 ;
  end
  return gender, OQ.RACE[raceId] ; -- 1 == female, 0 == male
end

function oq.on_party_slot( name, group_id, slot, premade_type )
  if (name ~= player_name) or ((_msg_type ~= 'P') and (_msg_type ~= 'A') and (_msg_type ~= 'R')) then
    return ;
  end
  my_group  = tonumber( group_id ) ;
  my_slot   = tonumber( slot ) ;
  
  if (premade_type ~= nil) then
    oq.set_premade_type( premade_type ) ;
  end

  -- populate the slot for myself
  local me = oq.raid.group[ my_group ].member[ my_slot ] ;
  oq.get_my_stats() ; -- will populate 'me'

-- use to be:
-- OQ_NONE, 0, OQ_NONE, 0, 
--  local stats = oq.encode_my_stats( me.flags, me.check, me.charm, me.bg[1].status, me.bg[2].status ) ;
  oq._override = true ;
  oq.on_stats( player_name, oq.realm_cooked(player_realm), me.stats ) ;
  oq.ui_player() ;
  oq.update_my_premade_line() ;

  -- push stats for everyone else in the raid
  last_stats = nil ;
end

function oq.mmr_check(base)
  if (base == 0) then
    return true ;
  end
  if (oq.raid.type == OQ.TYPE_ARENA) then
    if (oq.get_arena_rating(1) < base) and (oq.get_arena_rating(2) < base) and (oq.get_arena_rating(3) < base) then
      return nil ;
    end
  elseif (base > oq.get_mmr()) then
    return nil ;
  end
  return true ;
end

function oq.update_premade_note()
  if (not oq.iam_raid_leader()) then
    return ;
  end
  local name = oq.tab3_raid_name:GetText() ;
  local note = oq.tab3_notes:GetText() ;
  
  oq.raid.name  = name ;  
  oq.raid.notes = note ;
  
  if (oq.get_resil()  < oq.numeric_sanity( oq.tab3_min_resil:GetText() )) or 
     (oq.get_ilevel() < oq.numeric_sanity( oq.tab3_min_ilevel:GetText() )) or 
     (not oq.mmr_check(oq.numeric_sanity( oq.tab3_min_mmr:GetText() ))) then
    StaticPopup_Show("OQ_DoNotQualifyPremade") ;
    return ;
  end

  
  oq.tab1_name :SetText( oq.raid.name ) ;
  oq.tab1_notes:SetText( oq.raid.notes ) ; 
  oq.raid.level_range      = oq.tab3_level_range ;
  oq.raid.min_ilevel       = oq.numeric_sanity( oq.tab3_min_ilevel:GetText() ) ;
  oq.raid.min_resil        = oq.numeric_sanity( oq.tab3_min_resil:GetText() ) ;
  oq.raid.min_mmr          = oq.numeric_sanity( oq.tab3_min_mmr:GetText() ) ;
  oq.raid.bgs              = string.gsub( oq.tab3_bgs:GetText() or ".", ",", ";" ) ;
  oq.raid.pword            = oq.tab3_pword:GetText() or "" ;
  if (oq.raid.pword == nil) or (oq.raid.pword == "") then
    oq.raid.has_pword = nil ;
  else
    oq.raid.has_pword = true ;
  end

  oq.raid_announce( "premade_note,"..
                    oq.raid.raid_token ..","..
                    oq.encode_name( name ) ..","..
                    oq.encode_note( note ) 
                  ) ;
  local premade = oq.premades[ oq.raid.raid_token ] ;                  
  if (premade ~= nil) then      
    premade.tm          = 0 ;            
    premade.last_seen   = utc_time() ;
    premade.next_advert = 0 ;    
    premade.min_ilevel  = oq.raid.min_ilevel ;
    premade.min_resil   = oq.raid.min_resil ;
    premade.min_mmr     = oq.raid.min_mmr ;
    premade.pdata       = oq.get_pdata() ;
  end
  oq.send_my_premade_info() ;
  return 1 ;
end

function oq.on_premade_note( raid_token, name, note )
  if (oq.raid.raid_token == nil) or (oq.raid.raid_token ~= raid_token) then
    return ;
  end
  name = oq.decode_name( name ) ;
  note = oq.decode_note( note ) ;

  oq.raid.name = name ;  
  oq.tab1_name :SetText( oq.raid.name ) ;
  
  oq.raid.notes = note ;
  oq.tab1_notes:SetText( oq.raid.notes ) ; 
end

function oq.find_player_slot( g_id, name, realm )
  for i=1,5 do
    local p = oq.raid.group[g_id].member[i] ;
    if (p.name ~= nil) and (p.name == name) and (p.realm == realm) then
      return i ;
    end
  end
  return 0 ;
end

function oq.on_promote( g_id, name, realm, lead_rid, leader_realm, req_token )
  g_id = tonumber(g_id) ;
  slot = tonumber(slot) ;
  if (my_group ~= g_id) and (g_id ~= 1) then
    return ;
  end
  oq.token_push( req_token ) ; -- push it to the list so auto-realid-invites can happen

  if (g_id == 1) and (my_group ~= 1) and (my_slot == 1) then
    -- connect with oq-leader
    if (realm ~= player_realm) then
      local pid = oq.bnpresence( name .."-".. realm ) ;
      if (pid == 0) then
        -- real-id the oq-leader
        oq.realid_msg( name, realm, lead_rid, "#tok:".. req_token ..",#lead" ) ;
      end
    end
    -- push info
    lead_ticker = 0 ;
    oq.timer_oneshot( 1, oq.force_stats ) ;
    return ;
  end
  if (my_slot == 1) or oq.iam_party_leader() then
    -- take the slot of the target
    local p_slot = oq.find_player_slot( g_id, name, realm ) ;
    if (p_slot == 0) then
      return ;
    end
    -- send to party BEFORE processing
    oq.channel_party( _msg ) ;
    _ok2relay = nil ;
    
    -- promote
    my_slot = p_slot ;
    if (realm ~= player_realm) then
      PromoteToLeader( name .."-".. realm ) ;
    else
      PromoteToLeader( name ) ;
    end
    -- update info
--    oq.set_group_lead( g_id, name, realm, oq.raid.group[g_id].member[p_slot].class, nil ) ;
    oq.set_group_lead( g_id, name, realm, player_class, player_realid ) ;
    oq.set_name      ( g_id, my_slot, player_name, player_realm, player_class ) ;
    
    -- push info
    lead_ticker = 0 ;
    oq.timer_oneshot( 1, oq.force_stats ) ;
  elseif (player_name == name) then
    -- change my_slot
    local p_slot = my_slot ;
    my_slot = 1 ;
    -- update info
    local p = oq.raid.group[g_id].member[1] ;
    oq.set_name      ( g_id, p_slot, p.name, p.realm, p.class ) ;
    oq.set_group_lead( g_id, name, realm, player_class, player_realid ) ;
    -- push info
    lead_ticker = 0 ;
    oq.timer_oneshot( 3, oq.force_stats ) ;
    if (g_id == 1) then
      oq.ui_raidleader() ;
    end

    -- connect with oq-leader
    if (player_realm ~= leader_realm) and (g_id ~= 1) then
      local r = oq.raid.group[1].member[1] ;
      local pid = oq.bnpresence( r.name .."-".. r.realm ) ;
      if (pid == 0) then
        -- real-id the oq-leader
        oq.realid_msg( r.name, r.realm, lead_rid, "#tok:".. req_token ..",#lead" ) ;
      end
    end
    -- push info
    lead_ticker = 0 ;
    oq.timer_oneshot( 1, oq.force_stats ) ;
  end
end

function oq.on_invite_group( req_token, group_id, slot, raid_name, raid_leader_class, enc_data, raid_token, raid_notes )
  if (not oq.is_my_token( req_token )) then
    return ;
  end
  local  raid_leader, raid_leader_realm, raid_leader_rid = oq.decode_data( "abc123", enc_data ) ;
  _received = true ;
  _ok2relay = nil ;

  if (oq.iam_raid_leader() and (oq.raid.raid_token ~= raid_token)) then
    -- tried to start my own premade, but join another instead.  
    -- my original premade must be disbanded
    oq.raid_disband() ;
  end

  -- activate in-raid only procs
  oq.procs_join_raid() ;

  raid_name  = oq.decode_name( raid_name ) ;
  raid_notes = oq.decode_note( raid_notes ) ;
  
  my_group             = tonumber(group_id) ;
  my_slot              = tonumber(slot) ;
  oq.raid.name         = raid_name ;
  oq.raid.leader       = raid_leader ;
  oq.raid.leader_class = raid_leader_class ;
  oq.raid.leader_realm = raid_leader_realm ;
  oq.raid.leader_rid   = raid_leader_rid ;
  oq.raid.notes        = raid_notes ;
  oq.raid.raid_token   = raid_token ;
  
  local me = oq.raid.group[my_group].member[my_slot] ;
  me.name   = player_name ;
  me.realm  = player_realm ;
  me.level  = player_level ;
  me.class  = player_class ;
  me.resil  = player_resil ;
  me.ilevel = player_ilevel ;
  me.realid = player_realid ;
  me.check  = OQ.FLAG_CLEAR ;
  me.charm  = 0 ;

  oq.tab1_name :SetText( raid_name ) ;
  oq.tab1_notes:SetText( raid_notes ) ;

  oq.set_group_lead( 1, raid_leader, raid_leader_realm, raid_leader_class, raid_leader_rid ) ;
  oq.set_group_member( group_id, slot, player_name, player_realm, player_class, player_realid, "0", "0" ) ;

  -- send out invite acceptance
  oq.send_invite_accept( raid_token, group_id, slot, player_name, player_class, player_realm, player_realid, req_token ) ;

  -- send out my status (give it time for the group invites to settle)
--  oq.timer( "mystatus", 2, oq.send_my_status ) ; 

  -- remove myself from other waitlists
  oq.clear_pending() ;
  oq.ui_player() ;
  oq.update_my_premade_line() ;

  -- null out the group stats will force stats send
  last_stats = nil ;
  oq.raid.group[ my_group ]._stats = nil ;
  oq.raid.group[ my_group ]._names = nil ; 
  
end

function oq.on_member( group_id, slot, class, name, realm )
  realm = oq.realm_uncooked(realm) ;
  oq.set_group_member( group_id, slot, name, realm, class, nil ) ;
end

function oq.on_pass_lead( raid_token, nuleader, nuleader_realm, nuleader_rid )
  oq.raid.leader        = nuleader ;
  oq.raid.leader_realm  = nuleader_realm ;
  oq.raid.leader_realid = nuleader_rid ;
end

function oq.on_party_update( raid_token )
  oq.raid.raid_token = raid_token ;
end

function oq.premade_remove( lead_name, lead_realm, lead_rid, tm ) 
  local found = nil ;
  for i,v in pairs(oq.premades) do
--    if ((v.leader == lead_name) and (v.leader_realm == lead_realm) and (v.leader_rid == lead_rid)) then
    if (v.leader_rid == lead_rid) then
      if ((tm == nil) or (v.tm == nil) or (v.tm < tm)) then
        oq.remove_premade( v.raid_token ) ;
        found = true ;
      end
    end
  end
  return found ;
end

function oq.get_role_icon( n )
  if (n == "T") then
    -- OQ_TANK_ICON     
    return "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:16:16:0:0:64:64:0:19:22:41|t";
  elseif (n == "H") then
    -- OQ_HEALER_ICON   
    return "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:16:16:0:0:64:64:20:39:1:20|t";
  elseif (n == "D") then
    -- OQ_DAMAGE_ICON    
    return "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:16:16:0:0:64:64:20:39:22:41|t" ;
  end
  -- OQ_EMPTY_ICON 
  return "|TInterface\\TARGETINGFRAME\\UI-PhasingIcon.blp:16:16:0:0:64:64:0:64:0:64|t";
--  return "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:16:16:0:%d:64:64:0:0:0:0|t";
end

function oq.nMaxGroups()
  return 8 ;
end

function oq.get_n_roles() 
  local ntanks = 0 ;
  local nheals = 0 ;
  local ndps   = 0 ;
  local ngroups = oq.nMaxGroups() ;

  for i=1,ngroups do
    if (oq.raid.group[i]) then
      for j=1,5 do
        if (oq.raid.group[i].member) then
          local m = oq.raid.group[i].member[j] ;
          if (m.name) and (m.name ~= "-") then
            if (OQ.ROLES[ m.role ] == "TANK") then
              ntanks = ntanks + 1 ;
            elseif (OQ.ROLES[ m.role ] == "HEALER") then
              nheals = nheals + 1 ;
            else
              ndps   = ndps + 1 ;
            end
          end
        end
      end
    end
  end
  return ntanks, nheals, ndps ;
end

function oq.update_raid_listitem( raid_tok, raid_name, ilevel, resil, mmr, battlegrounds, tm_, status, has_pword, lead_name, pdata, type, karma_ )
  if (oq.tab2_raids == nil) then 
    return ;
  end
  
  if (_msg) then
    if (OQ_data._premade_info == nil) then
      OQ_data._premade_info = {} ;
    end
    OQ_data._premade_info[raid_tok] = tostring(player_faction) ..".".. tostring(utc_time()) ..".".. _msg ;
  end
  status = tonumber(status) ;
  for i,f in pairs( oq.tab2_raids ) do
    if (f.raid_token == raid_tok) then
      f.leader   :SetText( lead_name ) ;
      f.leader   :SetTextColor( 1,1,1 ) ;

      f.raid_name:SetText( raid_name ) ;
      f.min_ilvl :SetText( ilevel ) ;
      if (type == OQ.TYPE_DUNGEON) or (type == OQ.TYPE_CHALLENGE) or (type == OQ.TYPE_QUESTS) then
        oq.moveto( f.min_resil, 360, 6 ) ; -- move down slightly 
        local s = "" ;
        for j=1,5 do
          local ch = pdata:sub(j,j) ;
          if (ch ~= "") and (ch ~= "-") then
            s = s .."".. oq.get_role_icon( ch ) ;
          else
            s = s .."".. oq.get_role_icon( "X" ) ; -- empty slot
          end
        end
        f.min_resil:SetText( s ) ;
        f.min_mmr  :SetText( "" ) ;
      elseif (type == OQ.TYPE_SCENARIO) then
        oq.moveto( f.min_resil, 360, 6 ) ; -- move down slightly 
        local s = "" ;
        for j=1,3 do
          local ch = pdata:sub(j,j) ;
          if (ch ~= "") and (ch ~= "-") then
            s = s .."".. oq.get_role_icon( ch ) ;
          else
            s = s .."".. oq.get_role_icon( "X" ) ; -- empty slot
          end
        end
        f.min_resil:SetText( s ) ;
        f.min_mmr  :SetText( "" ) ;
      elseif (type == OQ.TYPE_RAID) then
--        oq.moveto( f.min_resil, 360, 6 ) ; -- move down slightly 
        if (pdata:sub(1,3) == "---") then
          pdata = "AAA" ; -- equivalent to 000 in mime64
        end
        local ntanks = oq.decode_mime64_digits(pdata:sub(1,1)) ;
        local nheals = oq.decode_mime64_digits(pdata:sub(2,2)) ;
        local ndps   = oq.decode_mime64_digits(pdata:sub(3,3)) ;
        local s = string.format( "%01d", ntanks ) .."".. oq.get_role_icon( "T" ) ;
        s = s .." ".. string.format( "%01d", nheals ) .."".. oq.get_role_icon( "H" ) ;
        s = s .." ".. string.format( "%02d", ndps   ) .."".. oq.get_role_icon( "D" ) ;
        f.min_resil:SetText( s ) ;
        f.min_mmr  :SetText( "" ) ;
      else
        oq.moveto( f.min_resil, 360, 2 ) ; -- back to normal position
        f.min_resil:SetText( resil ) ;
        f.min_mmr  :SetText( mmr ) ;
      end
      f.zones  :SetText( battlegrounds ) ;
      -- update status 
      if (status == 2) or (raid_tok == oq.raid.raid_token) then
        -- inside, disable button
        f.req_but:Disable() ;
      else
        f.req_but:Enable() ;
        f.has_pword.texture:Show() ;
        if (has_pword) then
          f.has_pword.texture:SetTexture( OQ_KEY ) ;
        else
          f.has_pword.texture:SetTexture( nil ) ;
        end
      end
      
      local r = oq.premades[ raid_tok ] ;
      if (r ~= nil) then
        r.leader       = lead_name ;
        r.name         = raid_name ;
        r.min_ilevel   = ilevel ; 
        r.min_resil    = resil ;
        r.min_mmr      = mmr ;
        r.bgs          = battlegrounds ;
        r.tm           = tm_ ;
      end
      return ;
    end
  end
end

local npremades = 0 ;
function oq.on_premade( raid_tok, raid_name, premade_info, enc_data, bgs_, type_, pdata_, leader_xp_, subtype_ )
  if (enc_data == nil) then
    return ;
  end
  if (subtype_) and (subtype_:find("#") ~= nil) then
    subtype_ = nil ; -- old msg types had fields appended
  end
  subtype_ = oq.decode_mime64_digits( subtype_ ) ;
  if (type_ == nil) then
    type_ = OQ.TYPE_BG ; -- default type, regular battlegrounds
  end
  if (pdata_ == nil) or (pdata_:find( "#rlm" )) then
    pdata_ = "-----" ;
  end
  oq._raid_token = raid_tok ;
  local faction, has_pword, is_realm_specific, is_source, level_range, 
        min_ilevel, min_resil, nmembers, nwaiting, status, tm_, min_mmr, karma  = oq.decode_premade_info( premade_info ) ;
        
  local raid_tm_token = raid_tok ..".".. tm_ ;
  if (oq.token_was_seen( raid_tm_token ) or (faction ~= player_faction)) then
    _ok2relay = nil ;
    return ;
  end
  oq.token_push( raid_tm_token ) ;
  
  oq.process_premade_info( raid_tok, raid_name, faction, level_range, min_ilevel, min_resil, min_mmr,
                           enc_data, bgs_, nmembers, 
                           is_source, tm_, status, 
                           nwaiting, has_pword, is_realm_specific, type_, pdata_, leader_xp_, karma ) ;
                           
  -- group leaders opt out of forwarding premade info, except their own premade
  --  this is to lessen the number of bnet msgs being sent and prevent the queue from backing up
  if (my_slot == 1) and (oq._raid_token ~= oq.raid.raid_token) then
    _ok2relay = nil ;
  end
end
  
function oq.process_premade_info( raid_tok, raid_name, faction, level_range, ilevel, resil, mmr, enc_data, 
                                  bgs_, nMem, is_source, tm_, status, nWait, has_pword, 
                                  is_realm_specific, type_, pdata_, leader_xp_, karma_ )
  if (OQ_toon.disabled) then
    return ;
  end
  local  now = utc_time() ;
  local  wins = 0 ; 
  local battlegrounds = oq.decode_bg( bgs_ ) ;
  raid_name = oq.ltrim( oq.decode_name( raid_name ) ) ;
  -- decode data
  local lead_name, lead_realm, lead_rid = oq.decode_data( "abc123", enc_data ) ;
  if (lead_name == nil) or (lead_realm == nil) or (lead_rid == nil) then
    return ;
  end
  if (abs(now - tm_) >= OQ_PREMADE_STAT_LIFETIME) then
    -- premade leader's time is off.  ignore
    _ok2relay = nil ;
    return ;
  end
  
  if (oq._my_group == nil) and (lead_rid == player_realid) then
    _ok2relay = nil ;
    return ;
  end

  if (oq.is_banned( lead_rid )) then
    -- do not record or relay premade info for banned people
    _ok2relay = nil ;
    return ;
  end
  if (raid_tok == oq.raid.raid_token) then
    if (type_ ~= oq.raid.type) then
      oq.set_premade_type( type_ ) ;
    end
    oq.update_my_premade_line() ;
  end
  if (oq.premades[ raid_tok ] ~= nil) then
    -- already seen
    local premade = oq.premades[ raid_tok ] ;
    if (tm_ < premade.tm) then
      -- drop old data
      _ok2relay = nil ;
      return ;
    end
    -- data is newer then what i have.. replace
    premade.leader        = lead_name ;
    premade.leader_realm  = lead_realm ;
    premade.leader_rid    = lead_rid ;
    premade.last_seen     = now ;
    premade.type          = type_ ; 
    premade.pdata         = pdata_ ;
    premade.leader_xp     = leader_xp_ ;
    premade.karma         = karma_ ;
    if (is_source == 0) then
      premade.next_advert = now + OQ_SEC_BETWEEN_ADS + random(1,10) ;
    end
    premade.has_pword         = has_pword ;
    premade.is_realm_specific = is_realm_specific ;
    oq.on_premade_stats( raid_tok, nMem, is_source, tm_, status, nWait, type_ ) ;
    oq.update_raid_listitem( raid_tok, raid_name, ilevel, resil, mmr, battlegrounds, tm_, status, has_pword, lead_name, pdata_, type_, karma_ ) ;
    return ;
  end

  oq.premade_remove( lead_name, lead_realm, lead_rid, tm_ ) ;
  oq.premades[ raid_tok ] = { raid_token   = raid_tok, 
                              name         = raid_name, 
                              leader       = lead_name, 
                              leader_realm = lead_realm,
                              leader_rid   = lead_rid, 
                              level_range  = level_range, 
                              faction      = faction, 
                              min_ilevel   = ilevel, 
                              min_resil    = resil, 
                              min_mmr      = mmr,
                              bgs          = battlegrounds,
                              type         = type_,
                              pdata        = pdata_,
                              leader_xp    = leader_xp_,
                              karma        = karma_,
                              tm           = tm_,  -- owner's time
                              last_seen    = now,  -- my time
                              next_advert  = now + OQ_SEC_BETWEEN_ADS + random(1,10),
                              stats = { nMembers    = tonumber(nMem), 
                                        nWaiting    = tonumber(nWait),
                                      }
                            } ;
  
  oq.premades[ raid_tok ].has_pword         = has_pword ;
  oq.premades[ raid_tok ].is_realm_specific = is_realm_specific ;
  
  local x, y, cy ;
  cy = 25 ;
  x  = 20 ;
  y  =  npremades * (cy + 2) + 10 ; 
  npremades = npremades + 1 ;
        
  local f   = oq.create_raid_listing( oq.tab2_list, x, y, oq.tab2_list:GetWidth() - 2*x, cy, raid_tok, type_ ) ;
  f.leader   :SetText( lead_name ) ;
  f.levels   :SetText( level_range ) ;
  f.raid_token = raid_tok ;
  table.insert( oq.tab2_raids, f ) ;
  oq.reshuffle_premades() ;
  oq.on_premade_stats( raid_tok, nMem, is_source, tm_, status, nWait, type_ ) ;
  oq.update_raid_listitem( raid_tok, raid_name, ilevel, resil, mmr, battlegrounds, tm_, status, has_pword, lead_name, pdata_, type_, karma_ ) ;
  if (raid_tok == oq.raid.raid_token) then
    oq.update_my_premade_line() ;
  end
end

function oq.on_premade_stats( raid_token, nMem, is_source, tm, status, nWait, type_ )
  _ok2relay = "bnet" ; -- should only bounce to bn-friends and oqgeneral, if raid-leader not on realm and msg never seen
  local raid = oq.premades[ raid_token ] ;
  if (raid == nil) then
    -- never seen, nothing to do
    return ;
  end
  local s = raid.stats ;
  local wins = 0 ;
  tm = tonumber(tm) ;
  if ((raid.tm == nil) or (raid.tm <= tm)) then
    s.nMembers     = tonumber(nMem) ;
    s.status       = tonumber(status) ;
    s.nWaiting     = tonumber(nWait) ;
    if (is_source) then
      raid.tm = tm ; -- so only the latest data is kept
    end
    -- update status 
    local line = oq.find_premade_entry( raid_token ) ;
    if (line ~= nil) then
      if (s.status == 2) or (raid_token == oq.raid.raid_token) then
        -- if inside, disable the waitlist button
        line.req_but:Disable() ;
      else
        line.req_but:Enable() ;
      end
    end  
  end
end

function oq.on_invite_req_response( raid_token, req_token, answer, reason )
  _ok2accept  = nil ;
  if (not oq.is_my_token( req_token )) then
    -- multi-boxer can receive same msg if via real-id msg
    _ok2decline = nil ;
    return ;
  end
  if (answer == "N") then
    PlaySound( "RaidWarning" ) ;
    message( string.format( OQ.MSG_REJECT, reason )) ;
  elseif (answer == "Y") then
    PlaySound( "AuctionWindowOpen" ) ;
    local f = oq.find_premade_entry( raid_token ) ;
    if (f ~= nil) then
      f.req_but:SetText( OQ.BUT_PENDING ) ;
      f.req_but:SetBackdropColor( 0.5, 0.5, 0.5, 1 ) ;
      f.pending = true ;
    end
  end
end

function oq.send_invite_response( name, realm, realid, raid_token, req_token, answer, reason )
  if (realid == nil) or (realid == "") then
    return ;
  end
  oq.timer_oneshot( 2, oq.realid_msg, name, realm, realid, 
                    OQ_MSGHEADER .."".. 
                    OQ_VER ..","..
                    "W1,"..
                    "0,"..
                    "invite_req_response,"..                 
                    raid_token ..","..
                    req_token ..","..
                    answer ..","..
                    (reason or ".")
                  ) ;
end

function oq.on_report_recvd( report, token )
  if (token == nil) or (report == nil) or (OQ_toon.reports == nil) then
    return ;
  end
  local r = OQ_toon.reports[token] ;
  if (r == nil) then
    -- why am i getting this response?
    return ;
  end
  
  r.report_recvd = true ;
  if (r.report_recvd and r.top_dps_recvd and r.top_heals_recvd) then
    OQ_toon.reports[token] = nil ;
  end
end

function oq.is_banned( rid, only_local )
  if (rid == nil) or (rid == "") or (rid == "nil") then
    return nil ;
  end
  if (OQ_data.banned == nil) then
    OQ_data.banned = {} ;
  end
  if (OQ_data.banned[rid] ~= nil) then
    return true ;
  end
  if (only_local == nil) and (OQ.gbl[strlower(rid)] ~= nil) then
    return true ;
  end
  return nil ;
end

function oq.ban_add( rid, reason_ )
  if (rid == nil) or (rid == "") or (rid == player_realid) then
    print( OQ_REDX_ICON .." invalid battle-tag (".. tostring(rid) ..")" ) ;
    return ;
  end
  if (OQ_data.banned == nil) then
    OQ_data.banned = {} ;
  end
  OQ_data.banned[ rid ] = { ts = utc_time(), reason = reason_ } ;  
  
  -- now add to the list
  local f = oq.create_ban_listitem( oq.tab6_list, 1, 1, 200, 22, rid, reason_, OQ_data.banned[ rid ].ts ) ;
  table.insert( oq.tab6_banlist, f ) ;
  oq.reshuffle_banlist() ;  
end

function oq.ban_remove( rid )
  if (rid == nil) or (rid == "") then
    print( OQ_REDX_ICON .." invalid battle-tag (".. tostring(rid) ..")" ) ;
    return ;
  end
  if (OQ_data.banned == nil) then
    OQ_data.banned = {} ;
  end
  OQ_data.banned[ rid ] = nil ;
end

function oq.ban_clearall()
  OQ_data.banned = {} ;
end

-- function oq.is_qualified( level_, faction, resil_, ilevel_, role_, mmr_ )
function oq.is_qualified( m )
  local level_min, level_max = oq.get_player_level_range() ;
  if (m.level < level_min) or (m.level > level_max) then
    return (oq.raid.enforce_levels == 0) ;
  end
  if (m.ilevel == nil) then
    return nil ;
  end
  if (oq.raid.min_ilevel ~= 0) and (oq.raid.min_ilevel > m.ilevel) then
    return nil ;
  end
  if (oq.is_dungeon_premade() or (oq.raid.type == OQ.TYPE_RAID)) then
    return true ;
  end
  if (oq.raid.min_resil ~= 0) and (oq.raid.min_resil > m.resil) then
    return nil ;
  end
  if (oq.raid.min_mmr ~= 0) then
    if (oq.raid.min_mmr > m.mmr) then
      return nil ;
    end
--[[
    if (oq.raid.type == OQ.TYPE_ARENA) then
      if (m.arena2s < oq.raid.min_mmr) and (m.arena3s < oq.raid.min_mmr) and (m.arena5s < oq.raid.min_mmr) then
        return nil ;
      end
    elseif (oq.raid.min_mmr > m.mmr) then
      return nil ;
    end
]]--
  end
  return true ;
end

function oq.on_req_invite( raid_token, raid_type, n_members_, req_token, enc_data, stats, pword )
  if (not oq.iam_raid_leader()) then
    return ;
  end
  -- not my raid
  --
  if (raid_token ~= oq.raid.raid_token) then
    oq.debug_report( "bad-token (".. raid_token ..") ~= (".. oq.raid.raid_token ..")" ) ;
    return ;
  end
  local  name_, realm_, realid_ = oq.decode_data( "abc123", enc_data ) ;
  pword      = oq.decode_pword( pword ) ;
  n_members_ = tonumber( n_members_ ) ;
  local m = tbl.new() ;
  local demos = oq.decode_their_stats( m, stats ) ;
  local flags_ = 0 ;
  local hp_ = 0 ;
  m.spec_id = select( 3, oq.get_class_spec_type( m.spec_id )) ;

  if (oq.n_waiting() > OQ_MAX_WAITLIST) then  
    oq.send_invite_response( name_, realm_, realid_, raid_token, req_token, "N", "wait list full" ) ;
    tbl.delete( m ) ;
    return ;
  elseif (not m.class) then
    oq.send_invite_response( name_, realm_, realid_, raid_token, req_token, "N", "invalid class" ) ;
    tbl.delete( m ) ;
    return ;
  elseif (oq.is_banned( realid_ )) then
    oq.send_invite_response( name_, realm_, realid_, raid_token, req_token, "N", "banned" ) ;
    tbl.delete( m ) ;
    return ;
  elseif (n_members_ == 1) and (not oq.is_qualified( m )) then
    oq.send_invite_response( name_, realm_, realid_, raid_token, req_token, "N", "not qualified" ) ;
    tbl.delete( m ) ;
    return ;
  elseif (oq.raid.has_pword and (oq.raid.pword ~= pword)) then
    oq.send_invite_response( name_, realm_, realid_, raid_token, req_token, "N", "invalid password" ) ;
    tbl.delete( m ) ;
    return ;
  end

  if (oq.waitlist == nil) then
    oq.waitlist = tbl.new() ;
  end

  -- check to see if the toon is already queue'd
  if (not oq.ok_for_waitlist( name_, realm_ )) then
    tbl.delete( m ) ;
    return ;
  end

  oq.waitlist[ req_token ] = m ;
  oq.waitlist[ req_token ].name      = name_ ;
  oq.waitlist[ req_token ].realm     = realm_ ;
  oq.waitlist[ req_token ].realid    = realid_ ;
  oq.waitlist[ req_token ].n_members = n_members_ ;
  oq.waitlist[ req_token ].bgroup    = oq.find_bgroup( realm_ ) ;
  oq.waitlist[ req_token ].create_tm = utc_time() ;
  
  local x, y, cy ;
  x  = 2 ;
  cy = 25 ;
  y  = oq.nwaitlist * (cy + 2) + 10 ;
  oq.nwaitlist = oq.nwaitlist + 1 ;
  
  local f = oq.insert_waitlist_item( x, y, req_token, n_members_, name_, realm_, oq.waitlist[ req_token ] ) ;
  table.insert( oq.tab7_waitlist, f ) ;
  oq.reshuffle_waitlist() ;
  oq.send_invite_response( name_, realm_, realid_, raid_token, req_token, "Y" ) ;  
  
  -- play sound to alert raid leader
  PlaySound( "AuctionWindowOpen" ) ;
end

function oq.get_spec_icon_text( spec_id )
  if (spec_id == nil) or (spec_id == 0) then
    return "" ;
  end
  local id, name, description, icon, background, role, class = GetSpecializationInfoByID( spec_id ) ;
  if (icon ~= nil) then
    return "|T".. icon ..":20:20:0:0|t" ;
  else
    return "--" ;
  end
end

function oq.insert_waitlist_item( x, y, req_token, n_members_, name_, realm_, m ) 
  local f = oq.create_waitlist_item( oq.tab7_list, x, y, oq.tab7_list:GetWidth() - 2*x, 25, req_token, n_members_ ) ;
  f.bgroup.texture:SetTexture( OQ.BGROUP_ICON[oq.find_bgroup(realm_)] ) ;
  if (m.role == 2) then
    local s = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:20:20:0:%d:64:64:20:39:1:20|t";
    f.role:SetText( s ) ;
  elseif (m.role == 4) then
    local s = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:20:20:0:%d:64:64:0:19:22:41|t";
    f.role:SetText( s ) ;
  else
    -- set icon for spec
    f.role:SetText( oq.get_spec_icon_text( m.spec_id )) ;
  end
--  f.create_tm = utc_time() ;
  f.m = m ; -- hopefully a ptr to the table
  f.toon_name :SetText( name_ ) ;
  f.realm     :SetText( realm_ ) ;
  f.level     :SetText( m.level ) ;
  f.ilevel    :SetText( m.ilevel ) ;
  
  if (oq.is_dungeon_premade() or (oq.raid.type == OQ.TYPE_RAID)) then
    f.resil     :SetText( m.haste ) ;
    f.pvppower  :SetText( m.mastery ) ;
    f.mmr       :SetText( m.hit ) ;
  else
    f.resil     :SetText( m.resil ) ;
    f.pvppower  :SetText( m.pvppower ) ;
    f.mmr       :SetText( m.mmr ) ;
  end
  
  f.toon_name :SetTextColor( OQ.CLASS_COLORS[m.class].r, OQ.CLASS_COLORS[m.class].g, OQ.CLASS_COLORS[m.class].b, 1 ) ;
-- 
-- set texture for role (might not work as ppl can't set role without a party/raid)
--
  f.req_token = req_token ;
  return f ;
end

function oq.update_wait_times()
  local now = utc_time() ;
  for i,v in pairs(oq.tab7_waitlist) do
    if (v.m.create_tm) then
      v.wait_tm:SetText( date("!%H:%M:%S", (now - v.m.create_tm) )) ;
    end
  end
end

function oq.on_req_mesh( token )
  if (OQ_data.autoaccept_mesh_request ~= 1) or (token == nil) then
    return ;
  end
  local ntotal, nonline = BNGetNumFriends() ;
  if (ntotal >= OQ_MAX_BNFRIENDS) then
    return ;
  end
  if (_source ~= "oqgeneral") or (oq._sender == nil) then
    -- only works locally
    return ;
  end
  if (oq.is_toon_friended( oq._sender, player_realm )) then
    return ;
  end
  _ok2relay = nil ; -- this should be a realm only msg
  local msg = OQ_HEADER ..",".. 
              OQ_VER ..","..
              "W1,0,imesh,".. tostring(token) ..",".. tostring(player_realid) ;
              
  oq.SendAddonMessage( "OQ", msg, "WHISPER", oq._sender ) ;
end

function oq.on_imesh( token, btag )
  _ok2relay = nil ; -- this should be a targeted msg
  if (not oq.token_was_seen( token )) then
    -- not my token, bogus msg
    return ;
  end
  if (player_realid == btag) then
    -- my tag, disregard
    return ;
  end
  local ntotal, nonline = BNGetNumFriends() ;
  if (ntotal >= OQ_MAX_BNFRIENDS) then
    return ;
  end

  local pid, is_online = oq.is_bnfriend( btag ) ;
  if (pid ~= nil) then
    -- already friended
    return ;
  end
  
  if (not oq.is_banned( btag )) then
    local msg = OQ_HEADER ..",".. 
                OQ_VER ..","..
                "W1,0,mesh_tag,0" ;
    oq.BNSendFriendInvite( btag, msg, "OQ,mesh node" ) ;
  end
end

function oq.ok_for_waitlist( name, realm )
  -- check to see if the toon is already queue'd
  for i,v in pairs(oq.waitlist) do
    if ((name == v.name) and (realm == v.realm)) then
      return nil ;
    end
  end
  -- or already in the group
  
  for i=1,8 do
    for j=1,5 do
      local mem = oq.raid.group[i].member[j] ;
      if (mem.name == name) and (mem.realm == realm) and (mem.class ~= "XX") then
        return nil ;
      end
    end
  end
  return true ;
end

function oq.start_role_check()
  oq.boss_announce( "role_check" ) ;
  InitiateRolePoll() ;
end

function oq.start_ready_check()
  oq.raid_announce( "ready_check" ) ;
  oq.on_ready_check() ;
end

function oq.ready_check_complete()
  oq.on_ready_check_complete() ;
end

function oq.on_ready_check()
  local ngroups = oq.nMaxGroups() ;
  for grp=1,ngroups do
    for s=1,5 do
      oq.raid.group[grp].member[s].check = OQ.FLAG_WAITING ;
      oq.set_textures( grp, s ) ;
    end
  end

  if (my_group > 0) and (my_slot > 0) and (oq.iam_raid_leader()) then
    oq.ready_check( my_group, my_slot, OQ.FLAG_READY ) ;
    oq.timer( "rdycheck_end", 30, oq.ready_check_complete ) ;
    return ;
  end
  local dialog = StaticPopup_Show("OQ_ReadyCheck", nil, nil, ndx ) ;
  last_group_brief = 0 ; -- force the update for ready-check status
  oq.timer( "rdycheck_end", 20, oq.ready_check_complete ) ;
end

function oq.on_role_check()
  if (not oq.iam_party_leader()) then
    return ;
  end
  InitiateRolePoll() ;
end

function oq.nMembers() 
  if (oq.raid.type ~= OQ.TYPE_BG) then
    return max( 1, GetNumGroupMembers() ) ;
  end
  local i, j, nMembers ;
  nMembers = 0 ;
  for i=1,8 do
    for j=1,5 do
      if (oq.raid.group[i]) and (oq.raid.group[i].member) then
        local m = oq.raid.group[i].member[j] ;
        if (m) and ((m.name) and (m.name ~= "-")) then
          nMembers = nMembers + 1 ;
        end
      end
    end
  end
  return nMembers ;
end

function oq.calc_raid_stats()
  local nMembers = oq.nMembers() ;
  local resil    = 0 ;
  local ilevel   = 0 ;
  local nWaiting = oq.n_waiting() ;
  
  for i=1,8 do
    if (oq.raid.group[i]) then
      for j=1,5 do
        if (oq.raid.group[i].member) then
          local mem = oq.raid.group[i].member[j] ;
          if (mem) and (mem.name) and (mem.name ~= "-") then
            if ((mem.ilevel == 0) and (mem.name == player_name)) then
              mem.ilevel = player_ilevel ;
              mem.resil  = player_resil ;
            end
            resil    = resil  + (mem.resil  or 0) ;
            ilevel   = ilevel + (mem.ilevel or 0) ;
          end
        end
      end
    end
  end
  if (nMembers == 0) then
    return 0, 0, 0, 0 ;
  end
  return  nMembers, floor(resil / nMembers), floor(ilevel / nMembers), nWaiting ;
end

function oq.update_tab1_stats()
  local nMembers, avg_resil, avg_ilevel = oq.calc_raid_stats() ;

  if (nMembers == 0) then
    oq.tab1_raid_stats:SetText( "0 / - / -" ) ;
  else
    oq.tab1_raid_stats:SetText( nMembers .." / ".. avg_resil .." / ".. avg_ilevel ) ;
  end
end

function oq.update_tab3_info()
  if ((oq.raid.raid_token == nil) or (not oq.iam_raid_leader())) then
    return ;
  end
  oq.tab3_raid_name :SetText( oq.raid.name ) ;
  oq.tab3_lead_name :SetText( player_name ) ;
  oq.tab3_rid       :SetText( player_realid or "" ) ;
  oq.tab3_min_ilevel:SetText( oq.raid.min_ilevel or 0 ) ;
  oq.tab3_min_resil :SetText( oq.raid.min_resil or 0 ) ;
  oq.tab3_min_mmr   :SetText( oq.raid.min_mmr or 0 ) ;
  oq.tab3_bgs       :SetText( oq.raid.bgs or "" ) ;
  oq.tab3_notes     :SetText( oq.raid.notes or "" ) ;
  oq.tab3_pword     :SetText( oq.raid.pword or "" ) ;
  
  oq.tab3_set_radiobutton( oq.raid.type ) ;
end

function oq.bset( flags, mask, set )
  flags = bit.bor( flags, mask ) ;
  if ((set == nil) or (set == 0) or (set == false)) then
    flags = bit.bxor( flags, mask ) ;
  end
  return flags ;
end

function oq.is_set( flags, mask )
  if (flags) and (mask) and (bit.band( flags, mask ) ~= 0) then
    return true ;
  end
  return nil ;
end

function oq.refresh_textures() 
  local ngroups = oq.nMaxGroups() ;
  for i=1,ngroups do
    for j=1,5 do
      oq.set_textures( i, j ) ;
    end
  end
end

function oq.set_textures( g_id, slot )
  if (oq.raid.type == nil) then
    return ;
  end
  g_id = tonumber( g_id ) ;
  slot = tonumber( slot ) ;
  if (g_id == nil) or (slot == nil) then
    return ;
  end
  local m     = oq.raid.group[g_id].member[slot] ;
  if (m == nil) then
    return ;
  end
  if (oq.raid.type == OQ.TYPE_RAID) then
    oq.set_textures_cell( m, oq.raid_group[g_id].slots[slot] ) ; -- raid
  end
  if (oq.raid.type == OQ.TYPE_DUNGEON) then
    oq.set_textures_cell( m, oq.dungeon_group.slots[slot] ) ; -- dungeon
  end
  if (oq.raid.type == OQ.TYPE_CHALLENGE) then
    oq.set_textures_cell( m, oq.raid_group[g_id].slots[slot] ) ; -- challenge
  end
  if (oq.raid.type == OQ.TYPE_QUESTS) then
    oq.set_textures_cell( m, oq.raid_group[g_id].slots[slot] ) ; -- challenge
  end
  if (oq.raid.type == OQ.TYPE_SCENARIO) then
    oq.set_textures_cell( m, oq.scenario_group.slots[slot]   ) ; -- scenario
  end
end

function oq.is_dungeon_premade( m )
  if (m == nil) then
    return (oq.raid.type == OQ.TYPE_DUNGEON) or (oq.raid.type == OQ.TYPE_SCENARIO) or 
           (oq.raid.type == OQ.TYPE_CHALLENGE) or (oq.raid.type == OQ.TYPE_QUESTS) ;
  else
    return (m.premade_type == OQ.TYPE_DUNGEON) or (m.premade_type == OQ.TYPE_SCENARIO) or 
           (m.premade_type == OQ.TYPE_CHALLENGE) or (m.premade_type == OQ.TYPE_QUESTS) ;
  end
end

function oq.set_textures_cell( m, cell )
  if (m == nil) or (cell == nil) or (cell.texture == nil) then
    return ;
  end
  local color = OQ.CLASS_COLORS["XX"] ;

  -- set color of cell
  if ((m.class ~= nil) and oq.is_set( m.flags, OQ.FLAG_ONLINE ) and (OQ.CLASS_COLORS[m.class] ~= nil)) then
    color = OQ.CLASS_COLORS[m.class] ;
  end
  if (color ~= nil) then
    cell.texture:SetTexture( color.r, color.g, color.b, 1 ) ;
  end

  if ((m.name == nil) or (m.name == "") or (m.name == "-")) then
    -- unused slot
    cell.status:SetTexture( nil ) ;
    cell.class :SetTexture( nil ) ;
    cell.role  :SetTexture( nil ) ;
    return ;
  end
  -- set overlap state
  if (m.check == nil) then
    m.check = OQ.FLAG_CLEAR ;
  end
  if (m.check == OQ.FLAG_WAITING) then
    cell.status:SetTexCoord( 0, 1.0, 0.0, 1.0 ) ; 
    cell.status:SetTexture( "Interface\\RAIDFRAME\\ReadyCheck-Waiting" ) ;
  elseif (m.check == OQ.FLAG_READY) then
    cell.status:SetTexCoord( 0, 1.0, 0.0, 1.0 ) ; 
    cell.status:SetTexture( "Interface\\RAIDFRAME\\ReadyCheck-Ready" ) ;
  elseif (m.check == OQ.FLAG_NOTREADY) then
    cell.status:SetTexCoord( 0, 1.0, 0.0, 1.0 ) ; 
    cell.status:SetTexture( "Interface\\RAIDFRAME\\ReadyCheck-NotReady" ) ;
  elseif (not oq.is_set( m.flags, OQ.FLAG_ONLINE )) then
    cell.status:SetTexCoord( 0, 1.0, 0.0, 1.0 ) ; 
    cell.status:SetTexture( "Interface\\CHARACTERFRAME\\Disconnect-Icon" ) ; -- "Interface\\GuildFrame\\GuildLogo-NoLogoSm" ) ;
  elseif (oq.is_set( m.flags, OQ.FLAG_BRB )) then
    cell.status:SetTexCoord( 0, 0.50, 0.0, 0.50 ) ; 
    cell.status:SetTexture( "Interface\\CHARACTERFRAME\\UI-StateIcon" ) ; -- Interface\\RAIDFRAME\\ReadyCheck-Waiting" ) ;
  elseif (oq.is_set( m.flags, OQ.FLAG_DESERTER )) then
    cell.status:SetTexCoord( 0, 1.0, 0.0, 1.0 ) ; 
    cell.status:SetTexture( "Interface\\Icons\\Ability_Druid_Cower" ) ;
  elseif (oq.is_set( m.flags, OQ.FLAG_QUEUED )) then
    cell.status:SetTexCoord( 0, 1.0, 0.0, 1.0 ) ; 
    if (player_faction == "A") then
      cell.status:SetTexture( "Interface\\BattlefieldFrame\\Battleground-Alliance" ) ;
    else
      cell.status:SetTexture( "Interface\\BattlefieldFrame\\Battleground-Horde" ) ;
    end
  else
    cell.status:SetTexture( nil ) ;
  end
  -- set role
  if (oq.is_set( m.flags, OQ.FLAG_TANK )) then
    cell.role:SetTexture( "Interface\\LFGFRAME\\UI-LFG-ICON-PORTRAITROLES" ) ;
    cell.role:SetTexCoord( 0, 19/64, 22/64, 41/64 ) ;
  elseif (oq.is_set( m.flags, OQ.FLAG_HEALER )) then
    cell.role:SetTexture( "Interface\\LFGFRAME\\UI-LFG-ICON-PORTRAITROLES" ) ;
    cell.role:SetTexCoord( 20/64, 39/64, 1/64, 20/64 ) ;
  elseif oq.is_dungeon_premade() then
    cell.role:SetTexture( "Interface\\LFGFRAME\\UI-LFG-ICON-PORTRAITROLES" ) ;
    cell.role:SetTexCoord( 20/64, 39/64, 22/64, 41/64 ) ;
  else
    cell.role:SetTexture( nil ) ; 
  end

  
end

function oq.set_status( g_id, slot, deserter, queued, online )
  g_id = tonumber( g_id ) ;
  slot = tonumber( slot ) ;
  if ((g_id <= 0) or (slot <= 0)) then
    return ;
  end

  local m = oq.raid.group[g_id].member[slot] ;
  local old_stat = m.flags ;

  m.flags = oq.bset( m.flags, OQ.FLAG_ONLINE  , online ) ;

  oq.set_textures( g_id, slot ) ;
end

function oq.gather_my_stats() 
  player_ilevel   = oq.get_ilevel() ;
  player_resil    = oq.get_resil() ;
  if (player_realm == nil) or (player_realm == "") then
    player_realm = oq.GetRealmName() ;
  end
  if (player_realm_id == nil) or (player_realm_id == 0) then
    player_realm = oq.GetRealmName() ;
    player_realm_id = oq.realm_cooked( player_realm ) ;
  end

  player_online = true ;

  if ((my_group <= 0) or (my_slot <= 0)) then
    return ;
  end
  local me = oq.raid.group[ my_group ].member[ my_slot ] ;
  me.gender, me.race = oq.player_demographic() ;  

  me.flags = 0 ; -- reset to 0
  me.flags = oq.bset( me.flags, OQ.FLAG_ONLINE  , player_online ) ;
  me.flags = oq.bset( me.flags, OQ.FLAG_BRB     , player_away ) ;
  if (player_role == OQ.ROLES["TANK"]) then
    me.flags = oq.bset( me.flags, OQ.FLAG_TANK  , true ) ;
  elseif (player_role == OQ.ROLES["HEALER"]) then
    me.flags = oq.bset( me.flags, OQ.FLAG_HEALER, true ) ;
  end
  
  if (me.check == nil) then
    me.check = OQ.FLAG_CLEAR ;
  end

  oq.set_role( my_group, my_slot, player_role ) ;

  me.resil    = player_resil ;
  me.ilevel   = player_ilevel ;
  me.hp       = floor(UnitHealthMax("player")/1000) ;
  local hks = GetStatistic(588) ;
  if (hks == "--") then
    hks = 0 ;
  end
  me.hks      = floor(hks / 1000) ;  
  me.oq_ver   = oq.get_version_id() ;
  me.tears    = 0 ;
  me.pvppower = oq.get_pvppower() ;
  me.mmr      = oq.get_mmr() ;
  
end

function oq.set_status_online( g_id, slot, online ) 
  if ((g_id <= 0) or (slot <= 0)) then
    return ;
  end
  if (oq.raid.group[g_id] == nil) or (oq.raid.group[g_id].member == nil) or (oq.raid.group[g_id].member[slot] == nil) then
    return ;
  end
  local m = oq.raid.group[g_id].member[slot] ;

  if (m.flags == nil) then
    m.flags = 0 ;
  end
  m.flags = oq.bset( m.flags, OQ.FLAG_ONLINE, online ) ;

  oq.set_textures( g_id, slot ) ;
end

function oq.set_role( g_id, slot, role ) 
  if ((g_id <= 0) or (slot <= 0)) then
    return ;
  end
  local m = oq.raid.group[g_id].member[slot] ;
  m.role = role ;

  if (role == OQ.ROLES["TANK"]) then
    m.flags = oq.bset( m.flags, OQ.FLAG_HEALER, false ) ;
    m.flags = oq.bset( m.flags, OQ.FLAG_TANK  , true  ) ;
  elseif (role == OQ.ROLES["HEALER"]) then
    m.flags = oq.bset( m.flags, OQ.FLAG_HEALER, true  ) ;
    m.flags = oq.bset( m.flags, OQ.FLAG_TANK  , false ) ;
  else
    m.flags = oq.bset( m.flags, OQ.FLAG_HEALER, false ) ;
    m.flags = oq.bset( m.flags, OQ.FLAG_TANK  , false ) ;
  end
  oq.set_textures( g_id, slot ) ;
end

function oq.on_stats( name, realm, stats, btag )
  local g_id, slot = oq.decode_slot( stats ) ;
  if (my_group == g_id) and (my_slot == slot) and (oq._override == nil) then
    -- don't tell me my own status
    return ;
  end
  if (g_id == 0) or (slot == 0) then
    -- bad info
    return ;
  end
  name, realm = oq.name_sanity( name, realm ) ;
  
  local force_grp_stats = nil ;
  local m = oq.raid.group[g_id].member[slot] ;
  if (my_group == g_id) and (m ~= nil) and (m.stats ~= stats) then
    force_grp_stats = true ;
  end
  if (btag ~= nil) then
    m.realid = btag ;
  end
  
  local g, s, lvl, demos = oq.decode_stats2( name, realm, stats ) ;
  oq._override = nil ;
  if (g == 0) and (s == 0) then
    -- most likely my slot... ignore
    return ;
  end
  if (lvl == 0) then
    if (name) and (name ~= "-") then
      oq.on_member_left( name, realm, m.realid ) ;
    end
    oq.raid_cleanup_slot( g_id, slot ) ;
    return ;
  end
  if ((name == nil) or (name == "-")) then
    name = "n/a" ;
  end
  local realm_id = 0 ;
  if (realm == nil) or (realm == "-") then
    realm = "n/a" ;
  else
    realm_id = tonumber(realm) ;
    realm = oq.realm_uncooked(realm) ;
  end

  oq.update_tab1_stats() ;
  
--  if (force_grp_stats) then
--    oq.lead_send_party_stats() ;
--  end  
  _ok2relay = nil ;  -- do not relay the stats message
end

function oq.init_table()
   for i=0,255 do
      local c = string.format("%c", i ) ;
      local n = i ;
      oq_ascii[n] = c ;
      oq_ascii[c] = n ;
   end
   
   local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/" ;
   local n = strlen(charset) ;
   for i=1,n do
      local c = charset:sub(i,i) ;
      oq_mime64[i-1] = c ;
      oq_mime64[c] = i-1 ;
   end
end

function oq.base64( a, b, c )
   local w, x, y, z ;
   a = oq_ascii[ a ] ;
   b = oq_ascii[ b ] ;
   c = oq_ascii[ c ] ;
   
   --   w = (a & 0xFC) >> 2 ;
   w = bit.rshift( bit.band( a, 0xFC ), 2 ) ;
   
   --   x = ((a & 0x03) << 4) + ((b & 0xF0) >> 4) ;
   x =  bit.lshift( bit.band( a, 0x03 ), 4 ) + bit.rshift( bit.band( b, 0xF0 ), 4 ) ;
   
   --   y = ((b & 0x0F) << 2) + ((c & 0xC0) >> 6) ;
   y = bit.lshift( bit.band( b, 0x0F ), 2 ) + bit.rshift( bit.band( c, 0xC0 ), 6 ) ;
   
   --   z = (c & 0x3F) ;
   z = bit.band( c, 0x3F ) ;
   
   w = oq_mime64[ w ] ;
   x = oq_mime64[ x ] ;
   y = oq_mime64[ y ] ;
   z = oq_mime64[ z ] ;
   return  w, x, y, z ;
end

function oq.base256( w, x, y, z )
   local a, b, c ;
   w = oq_mime64[ w ] or 0 ;
   x = oq_mime64[ x ] or 0 ;
   y = oq_mime64[ y ] or 0 ;
   z = oq_mime64[ z ] or 0 ;
   
   --   a = (w << 2) + ((x & 0x30) >> 4) ;
   a = bit.lshift( w, 2 ) + bit.rshift( bit.band( x, 0x30 ), 4 ) ;
   
   --   b = ((x & 0x0F) << 4) + ((y & 0x3C) >> 2) ;
   b = bit.lshift( bit.band( x, 0x0F ), 4 ) + bit.rshift( bit.band( y, 0x3C ), 2 ) ;
   
   --   c = ((y & 0x03) << 6) + z ;
   c = bit.lshift( bit.band( y, 0x03 ), 6 ) + z ;
   
   a = oq_ascii[ a ] ;
   b = oq_ascii[ b ] ;
   c = oq_ascii[ c ] ;
   return a, b, c ;
end

function oq.decode256( enc ) 
   local str = "" ;
   local n = strlen(enc) ;
   local w, x, y, z, a, b, c ;
   for i=1,n,4 do
      w = enc:sub(i,i) ;
      x = enc:sub(i+1,i+1) ;
      y = enc:sub(i+2,i+2) ;
      z = enc:sub(i+3,i+3) ;
      a, b, c = oq.base256( w, x, y, z ) ;
      str = str .."".. a .."".. b .."".. c ;
   end
   return str ;
end

function oq.encode64( str ) 
   local enc = "" ;
   local n = strlen(str) ;
   local w, x, y, z, a, b, c ;
   for i=1,n,3 do
      a = str:sub(i,i) ;
      b = str:sub(i+1,i+1) ;
      c = str:sub(i+2,i+2) ;
      w, x, y, z = oq.base64( a, b, c ) ;
      enc = enc .."".. w .."".. x .."".. y .."".. z ;
   end
   return enc ;
end


function oq.encode_data( pword, name, realm, rid )
  local s = tostring(name) ..",".. tostring(oq.realm_cooked(realm)) ..",".. tostring(rid) ;

  -- sub then reverse
  s = string.gsub( s, ",", ";" ) ;
  s = s:reverse() ;

  -- put in cocoon
  return oq.encode64( s ) ;
end

local _dvars = {} ;
function oq.decode_data( pword, data )
  -- pull from the cocoon
  local s = oq.decode256( data ) ;

  -- reverse then sub
  s = s:reverse() ;
  s = string.gsub( s, ";", "," ) ;
   
  -- pull vars out of it
  tbl.clear( _dvars ) ;
  local v ;
  local i = 0 ;
  for v in string.gmatch( s, "([^,]+)") do
    i = i + 1 ;
    _dvars[i] = v ; 
  end
  return _dvars[1], OQ.SHORT_BGROUPS[tonumber(_dvars[2])], _dvars[3] ;
end

function oq.encode_pword( pword )
  local s = pword or "." ;
  if (s:len() > 10) then
    s = s:sub( 1, 10 ) ;
  elseif (s == "") then
    s = "." ;
  end

  -- sub then reverse
  s = string.gsub( s, ",", ";" ) ;
  s = s:reverse() ;
   
  -- put in cocoon
  return oq.encode64( s ) ;
end

function oq.decode_pword( data )
  if (data == nil) or (data == "") then
    return "" ;
  end
  -- pull from the cocoon
  local s = oq.decode256( data ) ;
   
  -- reverse then sub
  s = s:reverse() ;
  s = string.gsub( s, ";", "," ) ;
  
  if (s == ".") then
    s = "" ;
  end
   
  return s ;
end

function oq.encode_name( name )
  local s = name or "." ;
  if (s:len() > 25) then
    s = s:sub( 1, 25 ) ;
  elseif (s == "") then
    s = "." ;
  end

  -- sub then reverse
  s = string.gsub( s, ",", ";" ) ;
  s = s:reverse() ;
   
  -- put in cocoon
  return oq.encode64( s ) ;
end

function oq.decode_name( data )
  -- pull from the cocoon
  local s = oq.decode256( data ) ;
   
  -- reverse then sub
  s = s:reverse() ;
  s = string.gsub( s, ";", "," ) ;
  
  if (s == ".") then
    s = "" ;
  end
   
  return s ;
end

function oq.encode_note( note )
  local s = note or "." ;
  if (s:len() > 150) then
    s = s:sub( 1, 150 ) ;
  elseif (s == "") then
    s = "." ;
  end

  -- sub then reverse
  s = string.gsub( s, ",", ";" ) ;
  s = s:reverse() ;
   
  -- put in cocoon
  return oq.encode64( s ) ;
end

function oq.decode_note( data )
  -- pull from the cocoon
  local s = oq.decode256( data ) ;
   
  -- reverse then sub
  s = s:reverse() ;
  s = string.gsub( s, ";", "," ) ;
  
  if (s == ".") then
    s = "" ;
  end
   
  return s ;
end

function oq.encode_bg( note )
  local s = note or "." ;
  if (s:len() > 35) then
    s = s:sub( 1, 35 ) ;
  elseif (s == "") then
    s = "." ;
  end

  -- sub then reverse
  s = string.gsub( s, ",", ";" ) ;
  s = s:reverse() ;
   
  -- put in cocoon
  return oq.encode64( s ) ;
end

function oq.decode_bg( data )
  if (data == nil) then
    return "" ;
  end
  -- pull from the cocoon
  local s = oq.decode256( data ) ;
   
  -- reverse then sub
  s = s:reverse() ;
  s = string.gsub( s, ";", "," ) ;
  
  if (s == ".") then
    s = "" ;
  end
   
  return s ;
end

function oq.decode_stats( s )
  local gid      = tonumber( s:sub( 1,1 )) ;
  local slot     = tonumber( s:sub( 2,2 )) ;
  local lvl      = tonumber( s:sub( 3,4 )) ;
  local demos    = oq_mime64[ s:sub( 5,5 ) ] ;
  if (demos == "0") then
    return gid, slot, lvl, demos ;
  end
  local gender   = bit.rshift( bit.band( 0x02, demos ), 1 ) ;
  local race     = bit.rshift( bit.band( 0x3C, demos ), 2 ) ;
  local faction  = 'H' ;
  if (bit.band( 0x01, demos ) ~= 0) then
    faction = 'A' ;
  end

  local class    = OQ.TINY_CLASS[ s:sub( 6, 6 ) ] ;
  local stat1    = s:sub(7, 7) ;
  local stat2    = s:sub(8, 8) ;
  local resil    = oq.decode_mime64_digits( s:sub(9,11) ) ;
  local ilevel   = oq.decode_mime64_digits( s:sub(12,13) ) ;

  local f1       = oq_mime64[ s:sub(14, 14)] ;
  local f2       = oq_mime64[ s:sub(15, 15)] ;
  local flags    = bit.lshift( f1, 4 ) + f2 ;
  local hp       = oq.decode_mime64_digits( s:sub(16,17) ) ;
  local role     = tonumber(s:sub(18,18) or 3) ;
  local charm    = tonumber(s:sub(19,19) or 0) ;
  local f3       = oq_mime64[ s:sub(20, 20)] ;
  local f4       = oq_mime64[ s:sub(21, 21)] ;
  local xflags   = bit.lshift( f3, 4 ) + f4 ;
  
  local wins     = oq.decode_mime64_digits( s:sub(22,24) ) ;
  local losses   = oq.decode_mime64_digits( s:sub(25,27) ) ;
  local hks      = oq.decode_mime64_digits( s:sub(28,29) ) ;
  local oq_ver   = oq.decode_mime64_digits( s:sub(30,30) ) ;
  local tears    = oq.decode_mime64_digits( s:sub(31,33) ) ;
  local pvppower = oq.decode_mime64_digits( s:sub(34,36) ) ;
  local mmr      = oq.decode_mime64_digits( s:sub(37,38) ) ;

  return gid, slot, lvl, faction, class, race, gender, 
         stat1, stat2, resil, ilevel, flags, 
         hp, role, charm, xflags, wins, losses, hks, oq_ver, tears, pvppower, mmr ;  
end

function oq.encode_hp( hp )
  if (hp == nil) then
    hp = 0 ;
  end
  local  a = floor(hp / 36) ;
  local  b = floor(hp % 36) ;
  return oq_mime64[ a ] .."".. oq_mime64[ b ] ;
end

function oq.decode_hp( code )
  local a = tonumber(oq_mime64[ code:sub( 1,1 ) ]) ;
  local b = tonumber(oq_mime64[ code:sub( 2,2 ) ]) ;
  return (a * 36) + b ;
end

function oq.encode_stats( g_id, slot, level, faction, class, race, gender, s1, s2, resil, ilevel, flags, hp, role, charm, xflags, wins, losses, hks, oq_ver, tears, pvppower, mmr )
  local lvl = level or 0 ;
  if (lvl < 10) then
    lvl = "0" .. tostring(lvl) ;
  end
  if (flags == nil) then
    flags = 0 ;
  end
  if (xflags == nil) then
    xflags = 0 ;
  end
  local faction_ = 0 ; -- 0 == horde, 1 == alliance
  if (faction ~= "H") then
    faction_ = 1 ;
  end
  local f1 = oq_mime64[ bit.rshift( flags ,    4 )] ;
  local f2 = oq_mime64[ bit.band  ( flags , 0x0F )] ;
  local f3 = oq_mime64[ bit.rshift( xflags,    4 )] ;
  local f4 = oq_mime64[ bit.band  ( xflags, 0x0F )] ;
  local demos = oq_mime64[ bit.lshift( race, 2 ) + bit.lshift( gender, 1 ) + faction_ ] ;
  if (not b1) then
    b1 = oq_mime64[ OQ.NONE ] ;
  else
    b1 = oq_mime64[ b1 ] ;
  end
  if (not b2) then
    b2 = oq_mime64[ OQ.NONE ] ;
  else
    b2 = oq_mime64[ b2 ] ;
  end
  local cls = class ;
  if (cls == nil) or (cls:len() > 2) then
    cls = (OQ.SHORT_CLASS[ class ] or "ZZ") ;
  end
  
  local stats = g_id .."".. 
                slot .."".. 
                lvl .."".. 
                demos .."".. 
                OQ.TINY_CLASS[cls] .."".. 
                (s1 or "A") ..""..
                (s2 or "A") ..""..
                oq.encode_mime64_3digit( resil ) ..""..
                oq.encode_mime64_2digit( ilevel ) ..""..
                f1 .."".. f2 ..""..
                oq.encode_mime64_2digit( hp ) ..""..
                tostring( role or 3 ) ..""..
                tostring( charm or 0 ) ..""..
                f3 .."".. f4 ..""..
                oq.encode_mime64_3digit( wins ) ..""..
                oq.encode_mime64_3digit( losses ) ..""..
                oq.encode_mime64_2digit( hks ) ..""..
                oq.encode_mime64_1digit( oq_ver ) ..""..
                oq.encode_mime64_3digit( tears ) ..""..
                oq.encode_mime64_3digit( pvppower or 0 ) ..""..
                oq.encode_mime64_2digit( mmr or 0 ) 
                ;
  return stats ;
end

function oq.encode_slot( gid, slot )
  gid  = tonumber(gid)  or 0 ;
  slot = tonumber(slot) or 0 ;
  if (gid == 0) then
    return oq.encode_mime64_1digit( gid ) ; -- 0 == no slot assigned
  end
  return oq.encode_mime64_1digit( (gid - 1) * 5 + slot ) ;
end

function oq.decode_slot( m )
  local n = oq.decode_mime64_digits( m:sub(1,1) ) ;
  return floor( ((n-1) / 5) + 1 ), floor( (n-1) % 5 ) + 1 ;
end

function oq.get_class_spec_type( spec_id )
  for i,v in pairs(OQ.CLASS_SPEC) do
    if (v.id == spec_id) then
      return v.type, v.n, i ;
    end
  end
  return 0, nil, 0 ;
end

function oq.encode_my_stats( flags, xflags, charm, s1, s2 )
  local class, spec, spec_id = oq.get_spec() ;
  local gender, race = oq.player_demographic() ;  
  local faction_ = 0 ; -- 0 == horde, 1 == alliance
  if (player_faction ~= "H") then
    faction_ = 1 ;
  end
  local demos = bit.lshift( race, 2 ) + bit.lshift( gender, 1 ) + faction_ ;
  local m = nil ;
  if (my_group > 0) then
    m = oq.raid.group[my_group].member[my_slot] ;
  end
  
  --[[ all purpose header data ]]--
  local s = oq.encode_slot( my_group, my_slot ) ;
  s = s .."".. (oq.raid.type or OQ.TYPE_NONE) ;
  s = s .."".. oq.encode_mime64_2digit( UnitLevel("player") ) ; -- 1..90, requires 2 digits
  s = s .."".. oq.encode_mime64_1digit( demos ) ;
  s = s .."".. OQ.TINY_CLASS[ player_class ] ;
  s = s .."".. oq.encode_mime64_1digit( flags ) ;
  s = s .."".. oq.encode_mime64_1digit( xflags ) ;
  s = s .."".. oq.encode_mime64_1digit( charm ) ;
  s = s .."".. oq.encode_mime64_2digit( floor(UnitHealthMax("player") / 1000) ) ; -- hp
  s = s .."".. oq.encode_mime64_1digit( oq.get_player_role() ) ;
  s = s .."".. oq.encode_mime64_1digit( OQ.CLASS_SPEC[ spec_id ].id ) ;
  s = s .."".. oq.encode_mime64_2digit( player_ilevel ) ;
  s = s .."".. oq.encode_mime64_1digit( oq.get_version_id() ) ;

  --[[ premade type specific data ]]--
  if oq.is_dungeon_premade() or (oq.raid.type == OQ.TYPE_RAID) then
    -- class.spec specific pve data
    local type = OQ.CLASS_SPEC[ spec_id ].type ;
    if     (type == OQ.TANK  ) then
      s = s .."".. oq.encode_mime64_3digit(floor(GetDodgeChance()*100)) ;
      s = s .."".. oq.encode_mime64_3digit(floor(GetParryChance()*100)) ;
      s = s .."".. oq.encode_mime64_3digit(floor(GetBlockChance()*100)) ;      
      s = s .."".. oq.encode_mime64_3digit(floor(GetMasteryEffect()*100)) ;
    elseif (type == OQ.RDPS  ) then
      s = s .."".. oq.encode_mime64_3digit(UnitRangedAttackPower("player")) ;
      s = s .."".. oq.encode_mime64_3digit(GetCombatRatingBonus(CR_HIT_RANGED) * 100) ;
      s = s .."".. oq.encode_mime64_3digit(floor(GetRangedCritChance() * 100)) ; 
      s = s .."".. oq.encode_mime64_3digit(floor(GetMasteryEffect() * 100)) ;
      s = s .."".. oq.encode_mime64_3digit(floor(GetRangedHaste() * 100)) ; 
    elseif (type == OQ.CASTER) then
      s = s .."".. oq.encode_mime64_3digit(oq.get_spell_power()) ;
      s = s .."".. oq.encode_mime64_3digit(GetCombatRatingBonus(CR_HIT_SPELL) * 100) ;
      s = s .."".. oq.encode_mime64_3digit(floor(oq.get_spell_crit() * 100)) ; 
      s = s .."".. oq.encode_mime64_3digit(floor(GetMasteryEffect() * 100)) ;
      s = s .."".. oq.encode_mime64_3digit(floor(UnitSpellHaste("player") * 100)) ; 
    else -- (type == OQ.MDPS) 
      s = s .."".. oq.encode_mime64_3digit(UnitAttackPower("player")) ;
      s = s .."".. oq.encode_mime64_3digit(GetCombatRatingBonus(CR_HIT_MELEE) * 100) ;
      s = s .."".. oq.encode_mime64_3digit(floor(GetCritChance() * 100)) ; 
      s = s .."".. oq.encode_mime64_3digit(floor(GetMasteryEffect() * 100)) ;
      s = s .."".. oq.encode_mime64_3digit(floor(GetMeleeHaste() * 100)) ; 
    end
    
    -- raid progression data
    if (oq.raid.type == OQ.TYPE_CHALLENGE) then
      s = s .."".. oq.get_past_experience() ;
    else
      s = s .."".. oq.get_raid_progression() ;
    end
  else
    -- pvp stats
    local bg_stats = OQ_toon.stats["rbg"] ;
    if (oq.raid.type == OQ.TYPE_BG) then
      bg_stats = OQ_toon.stats["bg"] ;
    end
    s = s .."".. oq.encode_mime64_3digit( oq.get_resil() ) ;
    s = s .."".. oq.encode_mime64_3digit( oq.get_pvppower() ) ;
    s = s .."".. oq.encode_mime64_3digit( bg_stats.nWins ) ;
    s = s .."".. oq.encode_mime64_3digit( bg_stats.nLosses ) ;
    s = s .."".. oq.encode_mime64_3digit( 0 ) ; -- the only tears that count are those of your enemy; rbgs could be same faction
    s = s .."".. oq.encode_mime64_2digit( oq.get_best_mmr(oq.raid.type) ) ; -- rbg rating
    s = s .."".. oq.encode_mime64_2digit( oq.get_hks() ) ; -- total hks
    s = s .."".. s1 ;
    s = s .."".. s2 ;
    if (m ~= nil) then
      m.ranks = oq.get_pvp_experience() ;
      s = s .."".. m.ranks ; -- ranks & titles
    else
      s = s .."".. oq.get_pvp_experience() ;
    end

--    s = s .."".. oq.encode_mime64_2digit( oq.get_arena_rating(1) ) ; -- 2s
--    s = s .."".. oq.encode_mime64_2digit( oq.get_arena_rating(2) ) ; -- 3s
--    s = s .."".. oq.encode_mime64_2digit( oq.get_arena_rating(3) ) ; -- 5s
  end
  -- karma, tacked on the back to avoid protocol change and forced update
  s = s .."".. oq.encode_mime64_1digit( min( 50, max( 0, player_karma + 25 )) ) ;

  if (my_group > 0) then
    oq.decode_stats2( player_name, player_realm, s, true ) ;
  end
  return s ;  
end

function oq.decode_their_stats( m, s )
  m.premade_type = s:sub(2,2) ;
  m.stats     = s ; -- hold onto the last stats

  m.level     = oq.decode_mime64_digits( s:sub(3,4) ) ;
  local demos = oq.decode_mime64_digits( s:sub(5,5) ) ;
  if (demos == "0") then
    return demos ;
  end
  m.gender    = bit.rshift( bit.band( 0x02, demos ), 1 ) ;
  m.race      = bit.rshift( bit.band( 0x3C, demos ), 2 ) ;
  m.faction   = 'H' ;
  if (bit.band( 0x01, demos ) ~= 0) then
    m.faction = 'A' ;
  end
  m.class     = OQ.TINY_CLASS[ s:sub(6,6) ] ;
  m.hp        = oq.decode_mime64_digits( s:sub(10,11) ) ;
  m.role      = oq.decode_mime64_digits( s:sub(12,12) ) ;
  m.spec_id   = oq.decode_mime64_digits( s:sub(13,13) ) ;
  m.ilevel    = oq.decode_mime64_digits( s:sub(14,15) ) ;
  m.oq_ver    = oq.decode_mime64_digits( s:sub(16,16) ) ;
  m.spec_type = oq.get_class_spec_type( m.spec_id ) ; -- tank, healer, dmg
  m.karma     = nil ;

  if oq.is_dungeon_premade( m ) or (m.premade_type == OQ.TYPE_RAID) then
    if     (m.spec_type == OQ.TANK  ) then
      m.dodge  = (oq.decode_mime64_digits( s:sub(17,19) ) or 0)/100 ; -- now a percentage
      m.parry  = (oq.decode_mime64_digits( s:sub(20,22) ) or 0)/100 ; 
      m.block  = (oq.decode_mime64_digits( s:sub(23,25) ) or 0)/100 ; 
      m.mastery= (oq.decode_mime64_digits( s:sub(26,28) ) or 0)/100 ; 
      m.raids  = s:sub(29,-1) ;
    elseif (m.spec_type == OQ.RDPS  ) then
      m.power  = (oq.decode_mime64_digits( s:sub(17,19) ) or 0) ;
      m.hit    = (oq.decode_mime64_digits( s:sub(20,22) ) or 0)/100 ; 
      m.crit   = (oq.decode_mime64_digits( s:sub(23,25) ) or 0)/100 ; 
      m.mastery= (oq.decode_mime64_digits( s:sub(26,28) ) or 0)/100 ; 
      m.haste  = (oq.decode_mime64_digits( s:sub(29,31) ) or 0)/100 ; 
      m.raids  = s:sub(32,-1) ;
    elseif (m.spec_type == OQ.CASTER) then
      m.power  = (oq.decode_mime64_digits( s:sub(17,19) ) or 0) ;
      m.hit    = (oq.decode_mime64_digits( s:sub(20,22) ) or 0)/100 ; 
      m.crit   = (oq.decode_mime64_digits( s:sub(23,25) ) or 0)/100 ; 
      m.mastery= (oq.decode_mime64_digits( s:sub(26,28) ) or 0)/100 ; 
      m.haste  = (oq.decode_mime64_digits( s:sub(29,31) ) or 0)/100 ; 
      m.raids  = s:sub(32,-1) ;
    elseif (m.spec_type == OQ.MDPS  ) then
      m.power  = (oq.decode_mime64_digits( s:sub(17,19) ) or 0) ;
      m.hit    = (oq.decode_mime64_digits( s:sub(20,22) ) or 0)/100 ; 
      m.crit   = (oq.decode_mime64_digits( s:sub(23,25) ) or 0)/100 ; 
      m.mastery= (oq.decode_mime64_digits( s:sub(26,28) ) or 0)/100 ; 
      m.haste  = (oq.decode_mime64_digits( s:sub(29,31) ) or 0)/100 ; 
      m.raids  = s:sub(32,-1) ;
    end
    m.karma  = m.raids:sub( -1, -1 ) ; -- last character
    m.raids  = m.raids:sub( 1, -2 ) ; -- trim off last character
  else
    --[[ pvp data ]]--  
    m.resil    = oq.decode_mime64_digits( s:sub(17,19) ) ;
    m.pvppower = oq.decode_mime64_digits( s:sub(20,22) ) ;
    m.wins     = oq.decode_mime64_digits( s:sub(23,25) ) ;
    m.losses   = oq.decode_mime64_digits( s:sub(26,28) ) ;
    m.tears    = oq.decode_mime64_digits( s:sub(29,31) ) ;
    m.mmr      = oq.decode_mime64_digits( s:sub(32,33) ) ;
    m.hks      = oq.decode_mime64_digits( s:sub(34,35) ) ;
    
    m.ranks    = s:sub(38,-1) ;
    
    -- tail:  223355k
--    m.arena2s  = oq.decode_mime64_digits( m.ranks:sub( -7, -6 ) ) ; 
--    m.arena3s  = oq.decode_mime64_digits( m.ranks:sub( -5, -4 ) ) ; 
--    m.arena5s  = oq.decode_mime64_digits( m.ranks:sub( -3, -2 ) ) ; 

    m.karma    = m.ranks:sub( -1, -1 ) ; -- last character
    m.ranks    = m.ranks:sub( 1, -2 ) ; -- trim off last character
  end
  if (m.karma == nil) or (m.karma == "") then
    m.karma = 0 ;
  else
    m.karma  = oq.decode_mime64_digits( m.karma ) - 25 ; -- 0..50, must rebalance to -25..25
  end
  return demos ;
end

function oq.decode_stats2( name, realm, s, force_it )
  local g_id, slot = oq.decode_slot( s ) ;
  if (((my_group == g_id) and (my_slot == slot) and (force_it == nil)) or (g_id == 0) or (slot == 0)) then
    return 0, 0, 0, 0 ;
  end
  oq.assure_slot_exists( g_id, slot ) ;
  
  -- decode directly into member slot
  local m = oq.raid.group[g_id].member[slot] ;
  if (m == nil) then
    return 0,0,0,0 ;
  end
  m.name, m.realm_id, m.realm = oq.name_sanity( m.name, m.realm_id ) ;
  
  if (oq.decode_their_stats( m, s ) == "0") then
    return g_id, slot, m.level, "0" ;
  end
  if ((g_id ~= my_group) or (slot ~= my_slot)) then
    m.flags     = oq.decode_mime64_digits( s:sub( 7, 7) ) ;
    m.check     = oq.decode_mime64_digits( s:sub( 8, 8) ) ;
  end
  oq.set_role ( g_id, slot, oq.decode_mime64_digits( s:sub(12,12) )) ;

  if oq.is_dungeon_premade( m ) or (m.premade_type == OQ.TYPE_RAID) then
    oq.set_group_member( g_id, slot, name, realm, m.class, m.realid, "0", "0" ) ;
  else
    oq.set_group_member( g_id, slot, name, realm, m.class, m.realid, s:sub(36,36), s:sub(37,37) ) ;
  end
  
  -- set overlays
  oq.set_textures( g_id, slot ) ;  
  return g_id, slot, m.level, demos ;
end

function oq.decode_short_stats( s )
  local lvl      = tonumber( s:sub( 1,2 )) ;
  local faction  = s:sub( 3, 3 ) ;
  if (faction == "0") then
    return lvl, faction ;
  end
  local class    = s:sub( 4, 5 ) ;
  local resil    = oq.decode_mime64_digits( s:sub(6, 8)) ;
  local ilevel   = oq.decode_mime64_digits( s:sub(9, 10)) ;
  local role     = tonumber( s:sub(11,11) or 3 ) ;
  local mmr      = oq.decode_mime64_digits( s:sub(12,13) ) ;
  local pvppower = oq.decode_mime64_digits( s:sub(14,16) ) ;
  local spec_id  = oq.decode_mime64_digits( s:sub(17,18) ) ;

  return lvl, faction, class, resil, ilevel, role, mmr, pvppower, spec_id ;
end

function oq.encode_short_stats( level, faction, class, resil, ilevel, role, mmr, pvppower, spec_id )
  local lvl = level ;
  if (lvl < 10) then
    lvl = "0" .. tostring(lvl) ;
  end
  local cls = class ;
  if (cls == nil) or (cls:len() > 2) then
    cls = OQ.SHORT_CLASS[ class ] or "ZZ" ;
  end
  
  local stats = lvl .."".. 
                faction .."".. 
                cls .."".. 
                oq.encode_mime64_3digit( resil  ) ..""..
                oq.encode_mime64_2digit( ilevel ) ..""..
                tostring( role or 3 ) ..""..
                oq.encode_mime64_2digit( mmr ) ..""..
                oq.encode_mime64_3digit( pvppower )  ..""..
                oq.encode_mime64_2digit( spec_id )
                ;
  return stats ;
end

function oq.encode_mime64_6digit( n_ )
  local n = oq.numeric_sanity(n_) ;
  local f = floor( n % 64 ) ;
  n = floor( n / 64 ) ;
  local e = floor( n % 64 ) ;
  n = floor( n / 64 ) ;
  local d = floor( n % 64 ) ;
  n = floor( n / 64 ) ;
  local c = floor( n % 64 ) ;
  n = floor( n / 64 ) ;
  local b = floor( n % 64 ) ;
  n = floor( n / 64 ) ;
  local a = floor( n % 64 ) ;  
  return oq_mime64[ a ] .."".. oq_mime64[ b ] .."".. oq_mime64[ c ] .."".. oq_mime64[ d ] .."".. oq_mime64[ e ] .."".. oq_mime64[ f ] ;
end

function oq.encode_mime64_5digit( n_ )
  local n = oq.numeric_sanity(n_) ;
  local e = floor( n % 64 ) ;
  n = floor( n / 64 ) ;
  local d = floor( n % 64 ) ;
  n = floor( n / 64 ) ;
  local c = floor( n % 64 ) ;
  n = floor( n / 64 ) ;
  local b = floor( n % 64 ) ;
  n = floor( n / 64 ) ;
  local a = floor( n % 64 ) ;  
  return oq_mime64[ a ] .."".. oq_mime64[ b ] .."".. oq_mime64[ c ] .."".. oq_mime64[ d ] .."".. oq_mime64[ e ] ;
end

function oq.encode_mime64_4digit( n_ )
  local n = oq.numeric_sanity(n_) ;
  local d = floor( n % 64 ) ;
  n = floor( n / 64 ) ;
  local c = floor( n % 64 ) ;
  n = floor( n / 64 ) ;
  local b = floor( n % 64 ) ;
  n = floor( n / 64 ) ;
  local a = floor( n % 64 ) ;  
  return oq_mime64[ a ] .."".. oq_mime64[ b ] .."".. oq_mime64[ c ] .."".. oq_mime64[ d ] ;
end

function oq.encode_mime64_3digit( n_ )
  local n = oq.numeric_sanity(n_) ;
  local c = floor( n % 64 ) ;
  n = floor( n / 64 ) ;
  local b = floor( n % 64 ) ;
  n = floor( n / 64 ) ;
  local a = floor( n % 64 ) ;  
  return oq_mime64[ a ] .."".. oq_mime64[ b ] .."".. oq_mime64[ c ] ;
end

function oq.encode_mime64_2digit( n_ )
  local n = oq.numeric_sanity(n_) ;
  local b = floor( n % 64 ) ;
  n = floor( n / 64 ) ;
  local a = floor( n % 64 ) ;  
  return oq_mime64[ a ] .."".. oq_mime64[ b ] ;
end

function oq.encode_mime64_1digit( n_ )
  local n = oq.numeric_sanity(n_) ;
  local a = floor( n % 64 ) ;  
  return oq_mime64[ a ] ;
end

function oq.encode_mime64_flags( f1, f2, f3, f4, f5, f6 )
  local a = 0 ;
  a = oq.bset( a, 0x01, f1 ) ;
  a = oq.bset( a, 0x02, f2 ) ;
  a = oq.bset( a, 0x04, f3 ) ;
  a = oq.bset( a, 0x08, f4 ) ;
  a = oq.bset( a, 0x10, f5 ) ;
  a = oq.bset( a, 0x20, f6 ) ;
  return oq_mime64[ a ] ;
end

function oq.decode_mime64_digits( s )
  if (s == nil) then
    return 0 ;
  end
  local n = 0 ;
  for i=1,#s do
    n = n * 64 + oq_mime64[ s:sub( i,i ) or 'A' ] ;
  end
  return n ;
end

function oq.decode_mime64_flags( data )
  local n = oq_mime64[ data ] ;
  local f1 = oq.is_set( n, 0x01 ) ;
  local f2 = oq.is_set( n, 0x02 ) ;
  local f3 = oq.is_set( n, 0x04 ) ;
  local f4 = oq.is_set( n, 0x08 ) ;
  local f5 = oq.is_set( n, 0x10 ) ;
  return f1, f2, f3, f4, f5 ;
end

function oq.encode_premade_info( raid_token, stat, tm, has_pword, is_realm_specific, is_source, karma )
  local raid = oq.premades[ raid_token ] ;
  if (raid == nil) then
    return ;
  end
  return oq.encode_mime64_flags ( (raid.faction == "H"), has_pword, is_realm_specific, is_source ) ..""..
         oq.encode_mime64_1digit( OQ.SHORT_LEVEL_RANGE[ raid.level_range ] ) ..""..
         oq.encode_mime64_2digit( raid.min_ilevel ) ..""..
         oq.encode_mime64_3digit( raid.min_resil ) ..""..
         oq.encode_mime64_1digit( raid.stats.nMembers ) ..""..
         oq.encode_mime64_1digit( raid.stats.nWaiting ) ..""..
         oq.encode_mime64_1digit( stat ) ..""..
         oq.encode_mime64_6digit( tm ) .."".. 
         oq.encode_mime64_2digit( raid.min_mmr ) ..""..
         oq.encode_mime64_1digit( (karma or 0) + 25 ) ; -- will change it from -25..25 to 0..50
end

function oq.decode_premade_info( data ) 
  local is_horde, has_pword, is_realm_specific, is_source = oq.decode_mime64_flags( data:sub(1,1) ) ;
  local faction = "A" ;
  if (is_horde) then
    faction = "H" ;
  end
  local  range = OQ.SHORT_LEVEL_RANGE[ oq.decode_mime64_digits( data:sub(2,2) ) ] ;
  local  karma = data:sub(19,19) ;
  if (karma == nil) or (karma == "") then
    karma = 0 ;
  else
    karma = oq.decode_mime64_digits( karma ) - 25 ;
  end
  
  return faction, has_pword, is_realm_specific, is_source, 
         range,
         oq.decode_mime64_digits( data:sub( 3, 4) ), -- min ilevel
         oq.decode_mime64_digits( data:sub( 5, 7) ), -- min resil
         oq.decode_mime64_digits( data:sub( 8, 8) ), -- nmembers
         oq.decode_mime64_digits( data:sub( 9, 9) ), -- nwaiting
         oq.decode_mime64_digits( data:sub(10,10) ), -- stat
         oq.decode_mime64_digits( data:sub(11,16) ), -- raid.tm
         oq.decode_mime64_digits( data:sub(17,18) ), -- min mmr
         karma                                       -- karma; must be -25..25
         ;         
end

function oq.echo_party_msg( sender, msg ) 
  if (oq.raid.raid_token == nil) or (my_slot ~= 1) or _inside_bg then
    return ;
  end
  if (oq.raid.type == OQ.TYPE_RBG) or (oq.raid.type == OQ.TYPE_RAID) then
    return ;
  end
  local name  = sender ;
  local realm = player_realm ;
  if (sender:find("-")) then
    name  = sender:sub( 1, sender:find("-")-1 ) ;
    realm = sender:sub( sender:find("-")+1, -1 ) ;
  end
  if (name == player_name) then
    if (msg:find('[[]') == 1) then
      -- most likely a relayed msg, do not echo 
      -- (this is buggy, as any messages sent by the group leader starting with '[' won't be relayed)
      return ;
    end
  end
  oq.boss_announce( "party_msg,".. oq.raid.raid_token ..",".. name ..",".. realm ..",".. oq.encode_note( msg ) ) ;  
end

function oq.on_party_msg( raid_token, name, realm, enc_note ) 
  _ok2relay = nil ;
  if (oq.raid.raid_token == nil) or (my_slot ~= 1) then
    return ;
  end
  if (oq.iam_raid_leader()) then
    _ok2relay = 1 ;
  end
  local n = name ;
  if (realm ~= player_realm) then
    n = n .."-".. realm ;
  end
  local note = "[".. n .."] ".. oq.decode_note( enc_note ) ;

  if (oq.iam_in_a_party()) then
    SendChatMessage( note, "PARTY" ) ;
  else
    SendChatMessage( note, "WHISPER", nil, player_name ) ;
  end
end

function oq.check_party_members()
  if (my_group == 0) then
    return ;
  end
  local grp = oq.raid.group[ my_group ] ;
  local new_mem = nil ;
  local mem_gone = nil ;
  local n_members = oq.GetNumPartyMembers() ;
  local rost = {} ;
  
  for i=1,4 do
    if (grp.member[i].name) and (grp.member[i].name ~= "") and (grp.member[i].name ~= "-") then
      rost[ grp.member[i].name ] = { ndx = i, raidid = 0 } ;
    end
  end

  for i = 1,n_members do
    name = UnitName("party".. i)
    if (rost[name] == nil) then
      new_mem = true ;
    else
      rost[name].raidid = i ;
    end
  end

  for name,v in pairs(rost) do
    if (name ~= nil) and (v.raidid == 0) and (name ~= player_name) then
      mem_gone = true ;
      oq.raid_cleanup_slot( my_group, v.ndx ) ;
    end
  end
  
  if (oq.iam_party_leader() and (new_mem or mem_gone)) then
    local now = utc_time() ;
    if ((last_ident_tm + 5) < now) then
      last_ident_tm = now ;
      oq.party_announce( "identify,".. my_group ) ;
    end
  end
end

function oq.get_party_roles()
  local grp = oq.raid.group[ my_group ] ;
  local m = "" ;
  
  for i=1,5 do
    local p = grp.member[i] ;
    if (p.name == nil) or (p.name == "-") or (p.name == "") then
      m = m .."x" ;
    else
      m = m .."".. UnitGroupRolesAssigned( p.name ):sub(1,1) ;
    end
  end
  return m ;
end

function oq.find_first_empty_slot( gid )
  local grp = oq.raid.group[ my_group ] ;
  for i = 2,5 do
    local p = grp.member[i] ;
    if (p.name == nil) or (p.name == "-") then
      return i ;
    end
  end
  return nil ;
end

-- makes sure slots are filled with party member names to insure someone doesn't 
-- disappear from group
--
function oq.verify_group_members() 
  if (not oq.iam_party_leader() or _inside_bg) then 
    return ;
  end
  if (oq.raid.type == OQ.TYPE_RBG) or (oq.raid.type == OQ.TYPE_RAID) then
    -- short circuit for raids
    return ;
  end
  local i, j ;
  local n_members = oq.GetNumPartyMembers() ;
  local grp = oq.raid.group[ my_group ] ;
  if (grp == nil) or (grp.member == nil) then
    return ; -- ??
  end
  
  -- check for members that left
  for i=2,5 do
    if (grp.member[i].name) and (grp.member[i].name ~= "-") and (grp.member[i].name ~= "") then
      grp.member[i].not_here = true ;
    else
      grp.member[i].not_here = nil ;
    end
  end
  for i=1,4 do
    local n = GetUnitName( "party".. i, true )
    local name  = n ;
    if (name) then
      local realm = player_realm ;
      if (name) and (name:find("-")) then
        name  = n:sub(1,n:find("-")-1) ;
        realm = n:sub(n:find("-")+1, -1) ;
      end
      for j=2,5 do
        if (grp.member[j].name == name) then
          grp.member[j].not_here = nil ;
          break ;
        end
      end
    end
  end
  for i=2,5 do
    if (grp.member[i].not_here) then
      oq.set_group_member( my_group, i, nil, nil, "XX", nil, "0", "0" ) ;
      oq.raid_cleanup_slot( my_group, i ) ;
    end
  end

  -- look for new members  
  for i=1,4 do
    local n = GetUnitName( "party".. i, true )
    local name  = n ;
    local realm = player_realm ;
    if (name ~= nil) and (name:find("-") ~= nil) then
      name  = n:sub(1,n:find("-")-1) ;
      realm = n:sub(n:find("-")+1, -1) ;
    end
    if (name ~= nil) then
      local found = nil ;
      for j=2,5 do
        if (grp.member) then
          local p = grp.member[j] ;
          if (p) and (p.name ~= nil) and (p.name == name) then
            p.realm    = realm ;
            found      = true ;
            p.not_here = nil ;
            break ;
          end
        end
      end
      if (not found) then
        -- new member found; party member not in OQ raid group
        slot = oq.find_first_empty_slot( my_group ) ;
        if (slot) and (grp.member) then
          grp.member[slot].name     = name ; -- reserve the spot for this player
          grp.member[slot].realm    = realm ;
          grp.member[slot].class    = OQ.SHORT_CLASS[ select(2, UnitClass("party".. i)) ] or "ZZ" ;
          grp.member[slot].not_here = nil  ; -- reserve the spot for this player
--          oq.brief_player( slot, name ) ;
          oq.timer( "brief_new_member", 1.0, oq.brief_group_members ) ;
        else
          -- error.  all slots full, unknown people in party
        end
      end
    end
  end
end

function oq.get_party_stats( gid )
  -- create message
  gid = gid or my_group ;
  local msg = "gs,".. gid ; -- changed from "grp_stats"
  local grp = oq.raid.group[ gid ] ;
  
  oq.verify_group_members() ;  
  oq.get_my_stats() ; -- will populate 'me'
  
  for i=1,5 do
    local p = grp.member[i] ;
    local stats ;
    if (p.name == nil) or (p.name == "-") or (p.name == "") then
      stats = oq.encode_slot( gid, i ) .."0" ;
    else
      local n = p.name ;
      if (p.realm ~= nil) and (p.realm ~= player_realm) then
        n = n .."-".. p.realm ;
      end
      if (UnitIsConnected(n) == nil) then
        oq.set_member_stats_offline( p ) ;
      end
      p.hp = floor(UnitHealthMax(n) / 1000) ;      
      if (p.check == nil) then
        p.check = OQ.FLAG_CLEAR ;
      end
      stats = p.stats ;
    end
    if (stats ~= nil) then
      msg = msg ..",".. stats ;
    else
      msg = msg ..",".. oq.encode_slot( gid, i ) .."0"
    end
  end
  
  -- tack on queue_tm
  local s1 = OQ.QUEUE_STATUS[ select(1, GetBattlefieldStatus(1)) ] ;
  local s2 = OQ.QUEUE_STATUS[ select(1, GetBattlefieldStatus(2)) ] ;
  local m  = oq.raid.group[ gid ].member[ 1 ] ;

  msg = msg ..",".. 
        (s1 or "0") ..","..
        oq.encode_mime64_6digit( m.bg[1].queue_ts ) ..","..
        (s2 or "0") ..","..
        oq.encode_mime64_6digit( m.bg[2].queue_ts ) ..","..
        tostring(oq.raid.type or OQ.TYPE_NONE) 
        ;

  -- add on roles
  return msg ;
end

function oq.first_raid_slot()
  local n = oq.nMaxGroups() ;
  for g=1,n do
    for s=1,5 do
      local p = oq.raid.group[g].member[s] ;
      if (p.name == nil) or (p.name == "-") then
        return g, s ;
      end
    end
  end
  return 0,0 ;
end

function oq.get_party_names( gid )
  oq.verify_group_members() ;
  if (gid == nil) then
    gid = my_group ;
  end
  -- create message
  local msg = "party_names,".. gid ;
  local grp = oq.raid.group[ gid ] ;
  local i ;
  local online_stats = "" ;
  
  for i=1,5 do
    local p = grp.member[i] ;
    local name ;
    if (p.name == nil) or (p.name == "-") or (p.name == "") or (p.realm == nil) or (p.realm == "-") then
      name = "-,0,-" ;
      online_stats = online_stats .."A" ;
    else
      local cls = p.class ;
      if (cls == nil) or (cls:len() > 2) then
        cls = OQ.SHORT_CLASS[ cls ] or "YY" ;
      end
--      name = p.name ..",".. tostring(oq.realm_cooked(p.realm)) ..",".. cls ;
      name = p.name ..",".. tostring(p.realm_id) ..",".. cls ;
      if (UnitIsConnected(p.name) == nil) then
        online_stats = online_stats .."A" ;
      else
        online_stats = online_stats .."B" ;
      end
    end
    msg = msg ..",".. name ;
  end
  msg = msg ..",".. online_stats ;
  return msg ;
end

function oq.clear_the_dead()
  if (not oq.iam_raid_leader()) or (oq.raid.type ~= OQ.TYPE_BGS) then
    return ;
  end
  local n = oq.nMaxGroups() ;
  for i=2,n do
    local p = oq.raid.group[i].member[1] ;
    if (p == nil) or (p.name == nil) or (p.name == "") or (p.name == "-") then
      local stats = oq.get_party_stats( i ) ; 
      oq.boss_announce( stats ) ;
      oq.party_announce( stats ) ;
    end
  end
end

function oq.send_party_names() 
  if ((my_group <= 0) or (my_slot <= 0)) then
    return ;
  end
  
  local msg = oq.get_party_names() ;
  
  -- send message
  oq.boss_announce( msg ) ;
  oq.raid.group[ my_group ]._names = msg ; -- used to brief new players  
end

function oq.on_member_join( name, realm, btag )
  if (btag == nil) or (btag == "") then
    return ; -- don't report if no btag
  end
  realm = oq.realm_uncooked(realm) ;
end

function oq.on_member_left( name, realm, btag )
  if (btag == nil) or (btag == "") then
    return ; -- don't report if no btag
  end
  realm = oq.realm_uncooked(realm) ;
end

function oq.set_name( gid, slot, name, realm, class, is_online )
--  oq.set_group_member( gid, slot, name, realm, class, nil, nil, nil ) ;
--  return ;
  if ((gid == 0) or (slot == 0)) then
    return ;
  end
  local realm_id = realm ;
  if(tonumber(realm) ~= nil) then
    realm = oq.realm_uncooked(realm) ;
  else
    realm_id = oq.realm_cooked(realm) ;
  end
  local m = oq.raid.group[ gid ].member[ slot ] ;
  if (name == "-") then
    if (m.name ~= nil) then
      oq.on_member_left( m.name, m.realm, m.realid ) ;
    end
    m.name     = nil ;
    m.realm    = nil ;
    m.realm_id = 0 ;
    m.class    = nil ;
  else
    if (m.name ~= name) then
      oq.on_member_join( name, realm, m.realid ) ; -- use existing realid if already have it, otherwise it'll be nil
    end
    m.name     = name ;
    m.realm    = realm ;
    m.realm_id = realm_id ;
    m.class    = class ;
    if (slot == 1) then
      -- update group leader info
    end
  end
  m.flags = oq.bset( m.flags, OQ.FLAG_ONLINE, (is_online == nil) or (is_online == "B") ) ;
  if (name == player_name) and ((realm == nil) or (realm == "-") or (realm == player_realm)) then
    local force_stats = nil ;
    if ((my_group ~= gid) or (my_slot ~= slot)) then
      force_stats = true ;
    end
    my_group   = gid ;
    my_slot    = slot ;
    m.realm    = player_realm ;
    m.realm_id = player_realm_id ;
    m.class    = player_class ;
    oq.ui_player() ;
    oq.update_my_premade_line() ;
    -- push my stats if needed
    if (force_stats) then
      oq.force_stats() ;
    end
  end
  oq.set_textures( gid, slot ) ;
end

function oq.name_sanity( name, realm_id )
  local realm = oq.realm_uncooked(realm_id) ;
  if (name) and (name ~= "-") and (name:find("-")) then
    realm = name:sub( name:find("-")+1, -1 ) ;
    name  = name:sub( 1, name:find("-")-1 ) ;
    realm_id = oq.realm_cooked( realm ) ;
  end
  return name, realm_id, realm ;
end

function oq.on_party_names( gid, n1, r1, c1, n2, r2, c2, n3, r3, c3, n4, r4, c4, n5, r5, c5, online_stats )
  gid = tonumber(gid) ;
  if (gid == 0) or ((my_group == gid) and (my_slot == 1) and (not oq.is_raid())) then
    return ;
  end
  if (online_stats == nil) then
    online_stats = "BBBBB" ;
  end
  n1, r1 = oq.name_sanity( n1, r1 ) ;
  n2, r2 = oq.name_sanity( n2, r2 ) ;
  n3, r3 = oq.name_sanity( n3, r3 ) ;
  n4, r4 = oq.name_sanity( n4, r4 ) ;
  n5, r5 = oq.name_sanity( n5, r5 ) ;
  
  oq.set_name( gid, 1, n1, r1, c1, online_stats:sub(1,1) ) ;
  oq.set_group_lead( gid, n1, r1, c1, oq.raid.group[gid].member[1].realid ) ;
  
  oq.set_name( gid, 2, n2, r2, c2, online_stats:sub(2,2) ) ;
  oq.set_name( gid, 3, n3, r3, c3, online_stats:sub(3,3) ) ;
  oq.set_name( gid, 4, n4, r4, c4, online_stats:sub(4,4) ) ;
  oq.set_name( gid, 5, n5, r5, c5, online_stats:sub(5,5) ) ;
  
  if (oq.is_raid()) then
    return ;
  end

  if (oq.iam_raid_leader()) then
    local msg = "party_names,".. gid ..",".. 
                 n1 ..",".. r1 ..",".. (c1 or "QQ") ..",".. 
                 n2 ..",".. r2 ..",".. (c2 or "QQ") ..",".. 
                 n3 ..",".. r3 ..",".. (c3 or "QQ") ..",".. 
                 n4 ..",".. r4 ..",".. (c4 or "QQ") ..",".. 
                 n5 ..",".. r5 ..",".. (c5 or "QQ") ;
    if (online_stats) and (online_stats ~= "") then
      msg = msg ..",".. online_stats ;
    end
    oq.boss_announce( msg )
    oq.raid.group[ gid ]._names = msg ; -- used to brief new players
  end  
  
  if (oq.iam_party_leader()) then
    -- tell party
    local msg = "party_names,".. gid ..",".. 
                 n1 ..",".. r1 ..",".. (c1 or "QQ") ..",".. 
                 n2 ..",".. r2 ..",".. (c2 or "QQ") ..",".. 
                 n3 ..",".. r3 ..",".. (c3 or "QQ") ..",".. 
                 n4 ..",".. r4 ..",".. (c4 or "QQ") ..",".. 
                 n5 ..",".. r5 ..",".. (c5 or "QQ") ;
    if (online_stats) and (online_stats ~= "") then
      msg = msg ..",".. online_stats ;
    end
    oq.party_announce( msg ) ;
    oq.raid.group[ gid ]._names = msg ; -- used to brief new players
  end
end

function oq.on_grp_stats( gid, m1, m2, m3, m4, m5, s1, tm1, s2, tm2, raid_type )
  gid = tonumber(gid) ;
  if (gid == 0) or (gid == my_group) then
    return ;
  end
--  if (gid == my_group) and (oq.iam_party_leader()) then
--    return ;
--  end
  local grp = oq.raid.group[ gid ] ;
  tm1 = oq.decode_mime64_digits( tm1 ) ;
  tm2 = oq.decode_mime64_digits( tm2 ) ;

  if (raid_type == OQ.TYPE_NONE) then
    raid_type = OQ.TYPE_BG ;
  end
--  if (oq.raid.type == nil) or (oq.raid.token == nil) then
--    oq.set_premade_type( raid_type ) ;
--  end
  for i=1,5 do
    local m = grp.member[i] ;
    if (m.name) and (m.name ~= "-") and (m.name:find("-")) then
      m.realm    = m.name:sub( m.name:find("-")+1, -1 ) ;
      m.realm_id = oq.realm_cooked( m.realm ) ;
      m.name     = m.name:sub( 1, m.name:find("-")-1 ) ;
    end
  end
  oq.on_stats( grp.member[1].name, grp.member[1].realm_id, m1 ) ;
  oq.on_stats( grp.member[2].name, grp.member[2].realm_id, m2 ) ;
  oq.on_stats( grp.member[3].name, grp.member[3].realm_id, m3 ) ;
  oq.on_stats( grp.member[4].name, grp.member[4].realm_id, m4 ) ;
  oq.on_stats( grp.member[5].name, grp.member[5].realm_id, m5 ) ;
  
  -- deal with queue tms
  oq.on_queue_tm( gid, s1, tm1, s2, tm2 ) ;
  
  if (my_slot == 1) then
    -- changed from "grp_stats"
    local msg = "gs,".. 
                 gid ..",".. 
                 m1 ..",".. 
                 m2 ..",".. 
                 m3 ..",".. 
                 m4 ..",".. 
                 m5 ..",".. 
                 (s1 or "0") ..",".. oq.encode_mime64_6digit(tm1) ..",".. 
                 (s2 or "0") ..",".. oq.encode_mime64_6digit(tm2) ..","..
                 tostring(oq.raid.type or OQ.TYPE_NONE) 
                 ;

    local now = utc_time() ;
    if (grp._stat_tm == nil) then
      grp._stat_tm = 0 ;
    end
    if (grp._stats == msg) and ((now - grp._stat_tm) < 5) then
      _ok2relay = nil ;
    else
      if (my_group == 1) then
        oq.boss_announce( msg ) ;
      end
      oq.party_announce( msg ) ;
      grp._stats = msg ; -- used to brief new players
      grp._stat_tm = now ; -- tm of last update
    end
  end  
end

function oq.on_identify( gid )
  gid = tonumber(gid) ;
  if (gid == 0) then
    gid = nil ;
  end 
  _ok2relay = nil ;
  if (_inside_bg) or ((gid ~= nil) and (gid ~= my_group)) then
    return ;
  end
  local now = utc_time() ;
  if ((last_ident_tm + 5) > now) then
    return ;
  end
  last_ident_tm = now ;
  oq.party_announce( "name,".. my_group ..",".. my_slot ..",".. player_name ..",".. player_realm ) ;
  if (oq.iam_party_leader()) then            
    oq.timer( "party_names", 2, oq.send_party_names ) ;    
  end  
end

function oq.on_name( gid, slot, name, realm )
  gid  = tonumber(gid) ;
  slot = tonumber(slot) ;
  if ((oq.raid.raid_token ~= raid_tok) or _inside_bg or (gid == 0) or (slot == 0)) then
    return ;
  end
  local m = oq.raid.group[ gid ].member[ slot ] ;
  m.name  = name ;
  m.realm = realm ;
end

function oq.get_my_stats()
  oq.gather_my_stats() ;

  -- pack up info and ship
  local m = oq.raid.group[ my_group ].member[ my_slot ] ;
  m.realid = player_realid ; -- just in case
  m.stats = oq.encode_my_stats( m.flags, m.check, m.charm, m.bg[1].status, m.bg[2].status ) ;
  return m.stats ;
end

function oq.force_stats()
  last_stats = nil ;
  lead_ticker = 1 ; -- so the stats pop first
  if (my_group == 0) then
    return ;
  end
  oq.raid.group[ my_group ]._stats = "" ;
  oq.check_stats() ;
end

-- fired on a timer once every 5 seconds.  only send if stats change
--
function oq.check_stats()
  -- if not in an OQ raid, leave
  if (my_group == nil) or (my_slot == nil) or (my_group <= 0) or (my_slot <= 0) or (oq.raid.raid_token == nil) or (_inside_bg) then
    return ;
  end

  -- gather bg queue status
  if (oq.raid.group[ my_group ] == nil) or (oq.raid.group[ my_group ].member[ my_slot ] == nil) then
    return ;
  end
  local me = oq.raid.group[ my_group ].member[ my_slot ] ;
  if (me.bg) then
    me.bg[1].status = OQ.QUEUE_STATUS[ select(1, GetBattlefieldStatus(1)) ] ;
    me.bg[2].status = OQ.QUEUE_STATUS[ select(1, GetBattlefieldStatus(2)) ] ;
  end

  -- if i'm lead, check party stats
  if (my_slot == 1) and (not oq.is_raid()) then
    oq.check_stats_lead() ;
  end

  -- check my stats, post if changed
  local my_stats = oq.get_my_stats() ;
  skip_stats = skip_stats + 1 ;
  if (last_stats == nil) or (my_stats ~= last_stats) or (skip_stats >= 3) then
    last_stats = my_stats ;
    skip_stats = 0 ;
    oq._override = true ;
    oq.on_stats( player_name, oq.realm_cooked(player_realm), my_stats ) ;
    if (oq.raid.type == OQ.TYPE_RBG) or (oq.raid.type == OQ.TYPE_RAID) then
      oq.raid_announce( "stats,".. 
                        player_name ..",".. 
                        tostring(oq.realm_cooked(player_realm)) ..","..
                        my_stats ..","..
                        tostring(player_realid)
                      ) ;
    else
      oq.party_announce( "stats,".. 
                         player_name ..",".. 
                         tostring(oq.realm_cooked(player_realm)) ..","..
                         my_stats ..","..
                         tostring(player_realid)
                       ) ;
    end
  end
end

function oq.lead_send_party_names()
  local grp = oq.raid.group[ my_group ] ;
  local now = utc_time() ;
  --  send_party_names
  local party_names = oq.get_party_names() ;
  if (party_names ~= grp._names) or ((grp._names_tm == nil) or (grp._names_tm < now)) then
    grp._names    = party_names ;
    grp._names_tm = now + random(25,35) ;
    
    local enc_data = oq.encode_data( "abc123", oq.raid.leader, oq.raid.leader_realm, oq.raid.leader_rid ) ;
    oq.party_announce( "party_join,".. 
                       my_group ..","..
                       oq.encode_name( oq.raid.name ) ..",".. 
                       oq.raid.leader_class ..",".. 
                       enc_data ..",".. 
                       oq.raid.raid_token  ..",".. 
                       oq.encode_note( oq.raid.notes )
                     ) ;    
    oq.boss_announce( party_names ) ;
    oq.party_announce( party_names ) ;
  end
end

function oq.lead_send_party_stats()
  local grp = oq.raid.group[ my_group ] ;
  local now = utc_time() ;
  -- send_party_stats() 
  local party_stats = oq.get_party_stats() ;
  if (party_stats ~= grp._stats) or ((grp._stats_tm == nil) or (grp._stats_tm < now)) then
    grp._stats    = party_stats ;
    grp._stats_tm = now + 2 ; -- no need to delay anymore; queue'd msgs help restrict flow
    oq.boss_announce( party_stats ) ;
    oq.party_announce( party_stats ) ;
  end
end

function oq.check_stats_lead()
  lead_ticker = lead_ticker + 1 ;

  -- alternating the sending of party_names and party_stats
  -- in an effort to reduce the number of msgs coming from the lead
  -- at any one moment
  --
  if ((lead_ticker % 2) == 1) then
    oq.lead_send_party_names() ;
  else
    oq.lead_send_party_stats() ;
  end
end

function oq.send_lag_times()
  local msg = "lag_times" ;
  for i=1,8 do
    msg = msg ..",".. (oq.raid.group[i].member[1].lag or 0) ;
  end
  oq.raid_announce( msg ) ;  
end

function oq.set_lag( grp, label, tm )
  tm = tonumber(tm) or 0 ;
  grp.member[1].lag = tm ;
  if (grp.member[1].name == nil) or (grp.member[1].name == "-") then
    label:SetText( "" ) ;
  else
    label:SetText( string.format( "%5.2f", tm/1000 )) ;  
  end
end

function oq.procs_init()
  -- all procs
  --
  oq.proc = {} ;
  oq.proc[ "btag"               ] = oq.on_btag ;
  oq.proc[ "btags"              ] = oq.on_btags ;
  oq.proc[ "disband"            ] = oq.on_disband ;
  oq.proc[ "enter_bg"           ] = oq.on_enter_bg ;
  oq.proc[ "find"               ] = oq.queue_find_request ;
  oq.proc[ "group_hp"           ] = oq.on_group_hp ;
  oq.proc[ "gs"                 ] = oq.on_grp_stats ;  -- changed from "grp_stats"
  oq.proc[ "iam_back"           ] = oq.on_iam_back ;
  oq.proc[ "identify"           ] = oq.on_identify ;
  oq.proc[ "imesh"              ] = oq.on_imesh ; 
  oq.proc[ "invite_accepted"    ] = oq.on_invite_accepted ;
  oq.proc[ "invite_group_lead"  ] = oq.on_invite_group_lead ;
  oq.proc[ "invite_group"       ] = oq.on_invite_group ;
  oq.proc[ "invite_req_response"] = oq.on_invite_req_response ;
  oq.proc[ "join"               ] = oq.on_join ;
  oq.proc[ "leave"              ] = oq.on_leave ;
  oq.proc[ "leave_slot"         ] = oq.on_leave_slot ;
  oq.proc[ "leave_waitlist"     ] = oq.on_leave_waitlist ;  
  oq.proc[ "mbox_bn_enable"     ] = oq.on_mbox_bn_enable ;
  oq.proc[ "member"             ] = oq.on_member ;
  oq.proc[ "mesh_tag"           ] = oq.on_mesh_tag ;
  oq.proc[ "name"               ] = oq.on_name ;
  oq.proc[ "need_btag"          ] = oq.on_need_btag ;
  oq.proc[ "new_lead"           ] = oq.on_new_lead ;
  oq.proc[ "party_join"         ] = oq.on_party_join ;
  oq.proc[ "party_msg"          ] = oq.on_party_msg ;
  oq.proc[ "party_names"        ] = oq.on_party_names ;
  oq.proc[ "party_slot"         ] = oq.on_party_slot ;
  oq.proc[ "party_slots"        ] = oq.on_party_slots ;
  oq.proc[ "party_update"       ] = oq.on_party_update ;
  oq.proc[ "pass_lead"          ] = oq.on_pass_lead ;
  oq.proc[ "ping"               ] = oq.on_ping ;
  oq.proc[ "ping_ack"           ] = oq.on_ping_ack ;
  oq.proc[ "p8"                 ] = oq.on_premade ;
  oq.proc[ "premade_note"       ] = oq.on_premade_note ;
  oq.proc[ "promote"            ] = oq.on_promote ;
  oq.proc[ "proxy_invite"       ] = oq.on_proxy_invite ;
  oq.proc[ "proxy_target"       ] = oq.on_proxy_target ;
  oq.proc[ "queue_tm"           ] = oq.on_queue_tm ;
  oq.proc[ "raid_join"          ] = oq.on_raid_join ;
  oq.proc[ "ready_check"        ] = oq.on_ready_check ;
  oq.proc[ "ready_check_complete"] = oq.on_ready_check_complete ;
  oq.proc[ "remove"             ] = oq.on_remove ;
  oq.proc[ "remove_group"       ] = oq.on_remove_group ;
  oq.proc[ "removed_from_waitlist" ] = oq.on_removed_from_waitlist ;
  oq.proc[ "report_recvd"       ] = oq.on_report_recvd ;
  oq.proc[ "ri"                 ] = oq.on_req_invite ; -- was "req_invite"
  oq.proc[ "req_mesh"           ] = oq.on_req_mesh ;
  oq.proc[ "role_check"         ] = oq.on_role_check ;
  oq.proc[ "stats"              ] = oq.on_stats ;
  oq.proc[ "v8"                 ] = oq.on_vlist ;
  
  -- remove raid-only procs
  oq.procs_no_raid() ;
end

-- in-raid only procs
--
function oq.procs_join_raid()

  -- raid required procs
  --
  oq.proc[ "btag"               ] = oq.on_btag ;
  oq.proc[ "enter_bg"           ] = oq.on_enter_bg ;
  oq.proc[ "group_hp"           ] = oq.on_group_hp ;
  oq.proc[ "gs"                 ] = oq.on_grp_stats ;  -- changed from "grp_stats"
  oq.proc[ "iam_back"           ] = oq.on_iam_back ;
  oq.proc[ "identify"           ] = oq.on_identify ;
  oq.proc[ "join"               ] = oq.on_join ;
  oq.proc[ "lag_times"          ] = oq.on_lag_times ;
  oq.proc[ "leave"              ] = oq.on_leave ;
  oq.proc[ "leave_slot"         ] = oq.on_leave_slot ;
  oq.proc[ "member"             ] = oq.on_member ;
  oq.proc[ "name"               ] = oq.on_name ;
  oq.proc[ "need_btag"          ] = oq.on_need_btag ;
  oq.proc[ "new_lead"           ] = oq.on_new_lead ;
  oq.proc[ "party_msg"          ] = oq.on_party_msg ;
  oq.proc[ "party_names"        ] = oq.on_party_names ;
  oq.proc[ "party_update"       ] = oq.on_party_update ;
  oq.proc[ "pass_lead"          ] = oq.on_pass_lead ;
  oq.proc[ "ping"               ] = oq.on_ping ;
  oq.proc[ "ping_ack"           ] = oq.on_ping_ack ;
  oq.proc[ "premade_note"       ] = oq.on_premade_note ;
  oq.proc[ "promote"            ] = oq.on_promote ;
  oq.proc[ "queue_tm"           ] = oq.on_queue_tm ;
  oq.proc[ "ready_check"        ] = oq.on_ready_check ;
  oq.proc[ "ready_check_complete"] = oq.on_ready_check_complete ;
  oq.proc[ "remove"             ] = oq.on_remove ;
  oq.proc[ "remove_group"       ] = oq.on_remove_group ;
  oq.proc[ "role_check"         ] = oq.on_role_check ;
  oq.proc[ "stats"              ] = oq.on_stats ;
end

-- nulls the in-raid only procs
--
function oq.procs_no_raid()
  -- clear the associated function for raid-only procs
  --
  oq.proc[ "btag"               ] = nil ;
  oq.proc[ "enter_bg"           ] = nil ;
  oq.proc[ "group_hp"           ] = nil ;
  oq.proc[ "gs"                 ] = nil ;   -- changed from "grp_stats"
  oq.proc[ "iam_back"           ] = nil ;
  oq.proc[ "identify"           ] = nil ;
  oq.proc[ "join"               ] = nil ;
  oq.proc[ "lag_times"          ] = nil ;
  oq.proc[ "leave"              ] = nil ;
  oq.proc[ "leave_group"        ] = nil ;
  oq.proc[ "member"             ] = nil ;
  oq.proc[ "name"               ] = nil ;
  oq.proc[ "need_btag"          ] = nil ;
  oq.proc[ "new_lead"           ] = nil ;
  oq.proc[ "party_msg"          ] = nil ;
  oq.proc[ "party_names"        ] = nil ;
  oq.proc[ "party_update"       ] = nil ;
  oq.proc[ "pass_lead"          ] = nil ;
  oq.proc[ "ping"               ] = nil ;
  oq.proc[ "ping_ack"           ] = nil ;
  oq.proc[ "premade_note"       ] = nil ;
  oq.proc[ "promote"            ] = nil ;
  oq.proc[ "queue_tm"           ] = nil ;
  oq.proc[ "ready_check"        ] = nil ;
  oq.proc[ "ready_check_complete"] = nil ;
  oq.proc[ "remove"             ] = nil ;
  oq.proc[ "remove_group"       ] = nil ;
  oq.proc[ "role_check"         ] = nil ;
  oq.proc[ "stats"              ] = nil ;
end

--------------------------------------------------------------------------
--  event handlers
--------------------------------------------------------------------------
function oq.on_addon_event( prefix, msg, channel, sender )
  if ((prefix ~= "OQ") or (sender == player_name)) or ((msg == nil) or (msg == "")) then
    return ;
  end
  if ((channel == "WHISPER") and oq.iam_party_leader() and (sender == oq.raid.leader) and (not OQ_toon.disabled)) then
    -- from the leader and i'm party leader, send only to my party
    oq.SendAddonMessage( "OQ", msg, "PARTY" ) ;
  end

  -- just process, do not send it on
  _local_msg = true ;
  _source    = "addon" ;
  if (channel == "PARTY") then
    _source = "party" ;
  end
  _ok2relay  = nil ;
  oq._sender = sender ;

  oq.process_msg( sender, msg ) ;  
  oq.post_process() ;
end

function tbl.new()
  if (tbl.__pool == nil) then
    tbl.__pool = {} ;
  end
  local t = next(tbl.__pool) ;
  if t then
    tbl.__pool[t] = nil ;
  else
    t = {} 
  end
  return t ;
end

function tbl.delete(t)
  if (t) then
    tbl.clear(t) ;
    tbl.__pool[t] = true ;
  end
  return nil ;
end

function tbl.clear(t)
  if (t) then
    wipe(t) ;
--[[
    for k in pairs(t) do 
      if (type(t[k]) == "table") then
        tbl.delete( t[k] ) ;    -- clear sub tables and be able to reclaim
      end
      t[k] = nil ;
    end
]]--
  end
  return t ;
end

function tbl.size(t)
  if (t == nil) then
    return nil ;
  end
  local n = 0 ;
  for i,v in pairs(t) do
    n = n + 1 ;
  end
  return n ;
end

function tbl.fill( t, ... )
  if (t ~= nil) then
    tbl.clear(t) ;
    for i = 1,select('#', ... ) do
      t[i] = select(i, ...) ;
    end
  end
end

-- returns deep copy of table object
function copyTable( t, copied )
  if (t == nil) then
    return t, copied ;
  end
  copied = copied or tbl.new() ;
  local copy = tbl.new() ;
  copied[t] = copy ;
  for i,v in pairs(t) do
    if (type(v) == "table") then
      if copied[v] then
        copy[i] = copied[v] ;
      else
        copy[i] = copyTable( v, copied ) ;
      end
    else
      copy[i] = v ;
    end
  end
  return copy, copied ;
end

function oq.on_bn_event( ... )
  if (OQ_toon.disabled or (not oq.loaded)) then
    return ;
  end
  tbl.fill( _arg, ... ) ;  
  
  local msg        = _arg[1] ;
  local presenceID = _arg[13] ;
  if (presenceID == nil) or (presenceID == 0) or ((msg == nil) or (msg == "")) then
    oq.post_process() ;
    return ;
  end
  
  tbl.fill( _opts, BNGetToonInfo(presenceID) ) ;
  local toonName   = _opts[2] ;
  local realmName  = _opts[4] ;
  local faction    = _opts[6] ;
  
  if (toonName == nil) or (realmName == nil) then
    oq.post_process() ;
    return ;
  end
  local name = toonName .."-".. realmName ;
  
  oq._sender  = name ;
  _sender_pid = presenceID ;
  _source     = "bnet" ;
  _oq_msg     = nil ;
  _ok2relay   = 1 ; 
  
  oq.check_if_new( presenceID, toonName, realmName ) ;

  oq.process_msg( name, msg ) ;
  
  oq.post_process() ;
end

function oq.on_channel_msg( ... )
  tbl.fill( _arg, ... ) ;  
  
  if ((_arg[2] == player_name) and (oq._iam_scorekeeper == nil)) or ((_arg[1] == nil) or (_arg[1] == "")) then
    oq.post_process() ;
    return ;
  end

  local chan_name = strlower(_arg[9]) ;
  if (not oq.channel_isregistered( chan_name )) then
    oq.post_process() ;
    return ;
  end
  if (chan_name == "oqgeneral") then
    _inc_channel = "oqgeneral" ;
    _local_msg   = true ;
    _source      = "oqgeneral" ;
    oq._sender   = _arg[2] ;
    _ok2relay    = 1 ; 
    oq.process_msg( _arg[2], _arg[1] ) ;
  end
  oq.post_process() ;
end

function oq.forward_msg_raid( msg )
  if (oq.iam_party_leader() and (_source == "party")) then
    oq.whisper_raid_leader( msg ) ;
  elseif (oq.iam_party_leader() and (_source ~= "party")) then
    oq.channel_party( msg ) ;
  end
end

function oq.forward_msg( source, sender, msg_type, msg_id, msg ) 
  if (_source == "bnet") and (not oq.iam_party_leader()) and (msg_type == 'B') then
    _ok2relay = 1 ;
  end
  
  -- no relaying while in a BG.  BATTLEGROUND msgs are BG-wide, everything else stops here
  --
  if (_msg_id == "p8") and (_inc_channel ~= "oqgeneral") and (my_slot ~= 1) and (oq._raid_token ~= oq.raid.raid_token) then
    oq.channel_general( msg ) ;
  end
  if (_inside_bg) then
    return ;
  end
  if (source == "party") and (my_slot ~= 1) then
    return ;
  end
  
  if (_to_realm ~= nil) and (_to_name ~= nil) then
    if (_to_realm == player_realm) and (_msg_id ~= "p8") then
      _ok2relay = nil ;  -- on the realm, just send direct
    end
    if (_to_name == player_name) then
      -- msg was for me, do not forward unless it was an announcement ... then strip off the to & realm fields and send
      if (msg_type == 'A') then
        if (_msg_id == nil) or (_msg_id ~= "p8") then
          oq.announce_relay( _core_msg ) ;
        end
      elseif (msg_type == 'R') then
        -- raid msg coming from raid leader, just send to channel
        oq.forward_msg_raid( msg ) ;
      end
      return ;
    end
    -- delivered
    if (_ok2relay ~= "bnet") then
      oq.SendAddonMessage( "OQ", msg, "WHISPER", _to_name ) ;
      return ;
    end
  end
  if (_ok2relay == "bnet") then
    oq.bnfriends_relay( msg ) ;
    _ok2relay = nil ; -- it's been sent via bnfriends, stop it there
    return ;
  end
  if (not _ok2relay) then
    return ;
  end
  if (oq.iam_raid_leader()) and ((msg_type == 'B') or (msg_type == 'R')) then
    -- relay to group leads
    oq.send_to_group_leads( msg ) ;
    oq.channel_party( msg ) ;
    return ;
  end
  if (source == "bnet") and ((msg_type == 'B') or (msg_type == 'P') or (msg_type == 'R')) and (not oq.iam_raid_leader()) then
    -- receiving msg via an alt (happens with multi-boxers); must send to raid leader
    if (sender ~= oq.raid.leader) then  -- prevent back flow
      oq.whisper_raid_leader( msg ) ;
    end
    oq.whisper_party_leader( msg ) ;
  end
  if ((msg_type == 'A') or ((msg_type == 'W') and (not _received))) then
    oq.bn_echo_raid( msg ) ;
    oq.announce_relay( msg ) ;
  elseif (msg_type == 'P') then
    oq.channel_party( msg ) ;
  elseif (msg_type == 'R') then
    oq.forward_msg_raid( msg ) ;
  end
end

function oq.on_oq_version( version, build )
 return;
end

function oq.check_version( vars )
  local oq_sig   = vars[1] ;
  local oq_ver   = vars[2] ;
--  local token    = vars[3] ;
  local msg_id   = vars[5] ;
  local version  = vars[6] ;
  local build    = vars[7] ;
  if (msg_id == nil) or (oq_sig ~= "OQ") then
    -- definitely not an OQ msg
    return ;
  end  
end

function oq.stricmp(a,b)
  if (a == nil) and (b == nil) then
    return true ;
  end
  if (a == nil) or (b == nil) then
    return nil ;
  end
  if (strlower(a) == strlower(b)) then
    return true ;
  end
  return nil ;
end

function oq.iam_related_to_boss()
  if (player_realm ~= oq.raid.leader_realm) then
    return nil ;
  end
  for i,v in pairs(OQ_toon.my_toons) do
    if (oq.stricmp(v.name, oq.raid.leader)) then
      return true ;
    end
  end
  return nil ;
end

function oq.route_to_boss( msg )
  if (oq._sender ~= oq.raid.leader) then  -- prevent back flow
    oq.whisper_raid_leader( msg ) ;
  end
end

function oq.recover_premades()
  if (OQ_data._premade_info == nil) then
    OQ_data._premade_info = {} ;
  end
  local now = utc_time() ;
  local tm  = nil ;
  local msg = nil ;
  local p1  = nil ;
  local p2  = nil ;
  local f   = nil ;
  for i,v in pairs(OQ_data._premade_info) do
    f = v:sub(1,1) ;
    if (f == player_faction) then
      p1 = 3 ;
      p2 = v:find("%.",p1) ;
      if (p1) then
        tm  = tonumber(v:sub(p1, p2-1)) ;
        msg = v:sub(p2+1, -1) ;
      end
      if (tm) and (msg) and ((now - tm) < OQ_PREMADE_STAT_LIFETIME) then
        _inc_channel = "oqgeneral" ;
        _local_msg   = true ;
        _source      = "oqgeneral" ;
        oq._sender   = "#backup" ;
        _ok2relay    = nil ; 
        oq.process_msg( oq._sender, msg ) ;
        oq.post_process() ;
      else
        OQ_data._premade_info[i] = nil ; -- out of date... clear
      end
    end
    tm  = nil ;
    msg = nil ;
  end
--  tbl.clear( OQ_data._premade_info ) ; 
end

function oq.process_msg( sender, msg )
  local v ;
  local i = 0 ;
  for v in string.gmatch(msg, "([^,]+)") do
    i = i + 1 ;
    _vars[i] = v ;
  end
  _msg = msg ;
  _core_msg, _to_name, _to_realm, _from = oq.crack_bn_msg( msg ) ;
  --
  -- format:  "OQ,".. OQ_VER ..",".. msg_tok ..",".. hop | raid-token ..",".. msg ;
  --
  local oq_sig   = _vars[1] ;
  local oq_ver   = _vars[2] ;
  local token    = _vars[3] ;
  local msg_id   = _vars[5] ;
  local atok     = nil ;

  -- every msg recv'd is counted, not just those processed
  oq.pkt_recv:inc() ;
  
  if (_inside_bg and (oq.bg_msgids[msg_id] == nil)) or (oq._banned) then
    return ;
  end
  if (oq_sig ~= "OQ") or (oq_ver ~= OQ_VER) or (OQ_toon.disabled) then
    -- not the same protocol, cannot proceed
    oq.check_version( _vars ) ;
    return ;
  end
  _msg_type = token:sub(1,1) ;
  _oq_msg   = true ;
  
  if (_msg_type == 'A') then
    atok = _vars[6] ; -- announce token
    if (not oq.atok_ok2process( atok )) then
      return ;
    end
  end
  
  --
  -- squash any echo
  --
  if ((token ~= "W1") and oq.token_was_seen( token )) then
    return ;
  end
  if ((token == "W1") and (_source == "oqgeneral")) then
    -- these messages cannot come from OQgen
    return ;
  elseif (token == "W1") then
    _ok2relay = nil ;
  end
  _msg_token     = token ;
  _msg_id        = msg_id ;
  _received      = nil ;
  oq.pkt_processed:inc() ;

  if ((_msg_id ~= "scores") and (_msg_id ~= "p8")) then
    if (_source == "bnet") and (_to_name ~= nil) and (_to_name ~= player_name) and
       (_to_realm ~= nil) and (_to_realm == player_realm) then
      oq.SendAddonMessage( "OQ", _core_msg, "WHISPER", _to_name ) ;
      return ;
    end
    if (_source == "bnet") and (not oq.iam_raid_leader()) and oq.iam_related_to_boss() then
      oq.route_to_boss( _core_msg ) ;
      return ;
    end
  end
  
  -- hang onto token to reduce echo
  -- note: hold token after sending to boss as multi-acct bnets will route the data back 
  --       and dont want to ignore it when it comes back
  oq.token_push( token ) ;
  --
  -- unseen message-token.  ok to process
  --
  local inc_channel = _inc_channel ;
  _inc_channel = nil ;  -- suspend the nonsending for processing.  afterwards, put it back for relaying
  -- raid, party or boss msgs
  if ((_msg_type == 'R') or (_msg_type == 'P') or (_msg_type == 'B')) then
    local raid_token = _vars[4] ;
    -- check to see if it's my raid token
    if (((oq.raid.raid_token == nil) or (raid_token == oq.raid.raid_token) or (msg_id == "party_join") or (msg_id == "raid_join")) and (oq.proc[ msg_id ] ~= nil)) then
      oq.proc[ msg_id ]( _vars[ 6], _vars[ 7], _vars[ 8], _vars[ 9], _vars[10], 
                         _vars[11], _vars[12], _vars[13], _vars[14], _vars[15], 
                         _vars[16], _vars[17], _vars[18], _vars[19], _vars[20],
                         _vars[21], _vars[22], _vars[23], _vars[24], _vars[25],
                         _vars[26], _vars[27], _vars[28], _vars[29], _vars[30],
                         _vars[31], _vars[32], _vars[33], _vars[34], _vars[35]
                        ) ;
    end
  elseif ((_msg_type == 'A') or (_msg_type == 'W')) then
    _hop = tonumber(_vars[4]) ;
    if (oq.proc[ msg_id ] ~= nil) then
      oq.proc[ msg_id ]( _vars[ 6], _vars[ 7], _vars[ 8], _vars[ 9], _vars[10], 
                         _vars[11], _vars[12], _vars[13], _vars[14], _vars[15], 
                         _vars[16], _vars[17], _vars[18], _vars[19], _vars[20],
                         _vars[21], _vars[22], _vars[23], _vars[24], _vars[25],
                         _vars[26], _vars[27], _vars[28], _vars[29], _vars[30],
                         _vars[31], _vars[32], _vars[33], _vars[34], _vars[35]
                        ) ;
    else
      _ok2relay = nil ;
    end
    -- rebuild msg for transport, incrementing #hops
    if ((_msg_type == 'A') and (_hop > 0) and (_hop <= OQ_TTL)) then
      if (_source ~= "oqgeneral") then
        -- only decrement when crossing realms, not crossing the realm channel
        _vars[4] = _hop - 1 ;
      end
      msg = "" ;
      for i=1,#_vars do
        if (i == 1) then
          msg = _vars[i] ;
        else
          msg = msg ..",".. _vars[i] ;
        end
      end
      -- re-crack to get update the core_msg
      _core_msg, _to_name, _to_realm, _from = oq.crack_bn_msg( msg ) ;      
    elseif (_msg_type == 'A') then
      _ok2relay = nil ;
    end
  end

  -- reset the inc channel
  _inc_channel = inc_channel ;

  --
  -- spread message 
  --
  if (token ~= "W1") or ((token == "W1") and (_to_name ~= nil) and (_to_name ~= player_name)) then
    if (_msg_type == 'A') and (not _ok2relay) then
      -- # hops exceeded, do nothing and return 
    else
      oq.forward_msg( _source, sender, _msg_type, msg_id, msg ) ;
    end
  end
end

function oq.post_process()
  oq._sender   = nil ;
  _sender_pid  = nil ;
  _local_msg   = nil ;
  _source      = nil ;
  _ok2relay    = 1 ; 
  _dest_realm  = nil ;
  _msg_type    = nil ;
  _msg_id      = nil ;
  _core_msg    = nil ;
  _to_name     = nil ;
  _to_realm    = nil ;  
  _inc_channel = nil ;
  _msg         = nil ;
  _core_msg    = nil ;
  oq._raid_token  = nil ;
  tbl.clear(_opts) ;
  tbl.clear(_vars) ;
  tbl.clear(_arg) ;
end

function oq.send_queue_tm( g_id, s1, tm1, s2, tm2 ) 
  if (oq.raid.raid_token == nil) then
    return ; 
  end
  if (not oq.iam_party_leader() or _inside_bg) then
    return ;
  end
  oq.raid_announce( "queue_tm,".. 
                     g_id ..",".. 
                     (s1 or "0") ..","..
                     (tm1 or 0) ..","..
                     (s2 or "0") ..","..
                     (tm2 or 0) 
                  ) ;  
                  
end

-- TODO: subtract off leader timestamp to show time difference
--

function oq.on_queue_tm( g_id, s1, tm1, s2, tm2 ) 
  g_id   = tonumber( g_id ) ;

  local bg1    = oq.raid.group[ g_id ].member[1].bg[ 1 ] ;
  bg1.queue_ts = tonumber(tm1) ;

  local bg2    = oq.raid.group[ g_id ].member[1].bg[ 2 ] ;
  bg2.queue_ts = tonumber(tm2) ;
  
  oq.update_status_txt() ;
end

function oq.on_bg_event(event,...)
  if (my_group < 1) or (my_slot < 1) then
    return ;
  end
  local me = oq.raid.group[my_group].member[my_slot] ;
  for i = 1,2 do
    if (oq.tab1_bg[i].status == "1") then
      oq.tab1_bg[i].status = "2" ; -- queue'd
      me.bg[i].start_tm = GetTime() ;
      return ;
    end
  end
end

function oq.bn_enabled( toonName, realm, faction, presenceID, isOnline, enabled )
  local name = toonName .."-".. realm ;
  local friend = OQ_data.bn_friends[name] ;
  
  if (friend == nil) then
    OQ_data.bn_friends[name] = {} ;
  elseif (friend.oq_enabled == enabled) then
    friend.presenceID = presenceID ;
    friend.isOnline   = isOnline ;
    return ;
  end
  friend = OQ_data.bn_friends[name] ;
 
  friend.toonName      = toonName ;
  friend.realm         = realm ;
  friend.faction       = faction ;
  friend.presenceID    = presenceID ;
  friend.isOnline      = isOnline ;
  if (enabled ~= "unk") then
    friend.oq_enabled    = enabled ;
    if (enabled) then
      oq.mbnotify_bn_enable( friend.toonName, friend.realm, 1 ) ;
    else
      oq.mbnotify_bn_enable( friend.toonName, friend.realm, 0 ) ;
    end
  end
  oq.n_connections() ;
end

function oq.isNewPresenceID( pid )
  if (pid ~= nil) then
    for i,v in pairs(OQ_data.bn_friends) do
      if (v.presenceID == pid) then
        return true ;
      end
    end
  end
  return nil ;
end

function oq.check_if_new( pid, toonName, realmName )
  local name = toonName .."-".. realmName ;
  local friend = OQ_data.bn_friends[ name ] ;
  --
  -- only does the check if more then 30 seconds have passed or the name is new
  --
  if (friend ~= nil) then
    local now = utc_time() ;
    if (next_bn_check > now) then
      return ;
    end
  else
    OQ_data.bn_friends[ name ] = tbl.new() ;
    friend = OQ_data.bn_friends[ name ] ;
    friend.isOnline      = true ;
    friend.toonName      = toonName ;
    friend.realm         = realmName ;
    friend.presenceID    = pid ;
  end
 
  friend.oq_enabled    = nil ;
  tbl.fill( _f, BNGetFriendInfoByID( pid ) ) ;
  local broadcast  = _f[12] ;
  if (broadcast ~= nil) and (broadcast:sub(1, #OQ_BNHEADER ) == OQ_BNHEADER) then
    friend.oq_enabled = true ;
  end
  if (broadcast ~= nil) and (broadcast:sub(1, #OQ_SKHEADER ) == OQ_SKHEADER) then
    friend.sk_enabled = true ;
  end
  oq.n_connections() ;
end


function oq.on_addon_loaded( name )
--  if (name == "oqueue") then
--    oq.on_init( GetTime() ) ;
--  end
end

function oq.good_region_info()
  if (string.sub(GetCVar("realmList"),1,2) == "us") then
    return true ;
  end
  if (string.sub(GetCVar("realmList"),1,2) == "eu") then
    return true ;
  end
  return nil ;
end

function oq.on_player_enter_world()
  if (oq.loaded) then
    return ;
  end
  if (oq.good_region_info()) and (oq.get_raid_progression ~= nil) then
    oq.on_init( GetTime() ) ;
  elseif (not oq.good_region_info()) then
    -- no region info.
    print( OQ_REDX_ICON ) ;
    print( OQ_REDX_ICON .." Error : oQueue disabled" ) ;
    print( OQ_REDX_ICON .." Reason: Invalid realmlist information (".. GetCVar("realmList") ..")" ) ;
    print( OQ_REDX_ICON .." Reason: This usually happens due to private server use." ) ;
    print( OQ_REDX_ICON .." Action: Please exit wow, delete your config.wtf, and restart your wow" ) ;
    print( OQ_REDX_ICON ) ;
  else
    print( OQ_REDX_ICON ) ;
    print( OQ_REDX_ICON .." Error : oQueue did not load all modules properly." ) ;
    print( OQ_REDX_ICON .." Reason: If you recently updated, a full restart of your wow may be required" ) ;
    print( OQ_REDX_ICON .." Action: If a restart does not resolve it, try re-installing oQueue" ) ;
    print( OQ_REDX_ICON .." Action: If you're still having problems, find tiny in public vent" ) ;
    print( OQ_REDX_ICON .." Action: wow.publicvent.org : 4135" ) ;
  end
  oq.loaded = true ;
end

--------------------------------------------------------------------------
-- initialization functions & event handlers
--------------------------------------------------------------------------
function oq.on_event(self,event,...)
  if (oq.msg_handler[event] ~= nil) then
    oq.msg_handler[event]( ... ) ;
  end  
end

function oq.on_bn_friend_invite_added( ... )
  oq.on_bnet_friend_invite( ... ) ;
  oq.bn_check_online() ;
end

function oq.get_seat( name )
  if (name:find('-')) then
    name = name:sub(1, (name:find('-') or 0)-1 ) ;
  end
  for gid=1,8 do
    for slot=1,5 do
      local m = oq.raid.group[gid].member[slot] ;
      if (m.name == name) then
        return gid, slot ;
      end
    end
  end
  return 0, 0 ;
end

function oq.check_seat( name, group_id, slot )
  if (name:find('-')) then
    name = name:sub(1, (name:find('-') or 0)-1 ) ;
  end
  local m = oq.raid.group[group_id].member[slot] ;
  return (m.name == name) ;
end

function oq.first_open_seat( gid )
  for j=1,5 do
    if ((oq.raid.group[gid].member[j].name == nil) or (oq.raid.group[gid].member[j].name == "-")) then
      return gid, j ;
    end
  end
  return gid, 0 ;
end

function oq.swap_seats( m, x ) 
  local tmp1 = copyTable( m ) ;
  local tmp2 = copyTable( x ) ;
  m = copyTable( tmp2 ) ;
  x = copyTable( tmp1 ) ;
end

function oq.move_member( name, new_gid, new_slot ) 
  local old_gid, old_slot = oq.get_seat( name ) ;
  
  if (old_slot ~= 0) then
    local m = oq.raid.group[new_gid].member[new_slot] ;
    local x = oq.raid.group[old_gid].member[old_slot] ;
    oq.raid_announce( "party_slot,".. 
                       x.name ..","..
                       new_gid ..","..
                       new_slot
                    ) ;
--[[
    if (m.name ~= nil) and (m.name ~= "-") then
      oq.raid_announce( "party_slot,".. 
                         m.name ..","..
                         old_gid ..","..
                         old_slot
                      ) ;
    end
]]--
    oq.swap_seats( m, x ) ;
--    oq.raid_cleanup_slot( old_gid, old_slot ) ;  
  end 
--[[  
  local enc_data = oq.encode_data( "abc123", oq.raid.leader, oq.raid.leader_realm, oq.raid.leader_rid ) ;
  oq.raid_announce( "party_join,".. 
                      new_gid ..","..
                      oq.encode_name( oq.raid.name ) ..",".. 
                      oq.raid.leader_class ..",".. 
                      enc_data ..",".. 
                      oq.raid.raid_token  ..",".. 
                      oq.encode_note( oq.raid.notes )
                   ) ;
]]--
end

function oq.find_member( table, name )
  if (name == nil) or (name == "-") then
    return nil ;
  end
  for i=1,8 do
    for j=1,5 do
      local m = table[i].member[j] ;
      if (m.name ~= nil) and (m.name == name) then
        return m ;
      end
    end
  end
  return nil ;
end

function oq.assign_raid_seats()
  local n = GetNumGroupMembers() ;
  local slot = 0 ;
  local i, j ;
  local cur = copyTable( oq.raid.group ) ;
  local grp = tbl.new() ;
  my_group = 1 ;
  my_slot  = 1 ;
  for i=1,8 do
    grp[i] = 0 ;
  end

  for i=1,n do
    local name, _, gid = GetRaidRosterInfo(i) ;
    local realm ;
    name, realm = oq.crack_name( name ) ;

    grp[ gid ] = grp[ gid ] + 1 ;
    slot = grp[ gid ] ;
    if (name ~= nil) then
      local m = oq.find_member( cur, name ) ;
      if (m ~= nil) then
        oq.raid.group[gid].member[ slot ] = copyTable( m ) ;
        oq.raid.group[gid].member[ slot ].realm = realm ;
        oq.raid.group[gid].member[ slot ].realm_id = oq.realm_cooked(realm) ;
        oq.set_textures( gid, slot ) ;
      else
        oq.raid.group[gid].member[ slot ].name  = name ;
        oq.raid.group[gid].member[ slot ].realm = realm ;
        oq.raid.group[gid].member[ slot ].realm_id = oq.realm_cooked(realm) ;
      end
    end
  end
  if (n == 0) then
    -- only one person in the 'raid'
    local m = oq.find_member( cur, player_name ) ;
    gid = 1 ;
    grp[ gid ] = grp[ gid ] + 1 ;
    slot = grp[ gid ] ;
    oq.raid.group[gid].member[ slot ] = copyTable( m ) ;
    oq.set_textures( gid, slot ) ;    
  end
  -- make sure everyone knows we're in the raid
  local enc_data = oq.encode_data( "abc123", oq.raid.leader, oq.raid.leader_realm, oq.raid.leader_rid ) ;
  oq.raid_announce( "raid_join,".. 
                     oq.encode_name( oq.raid.name ) ..",".. 
                     tostring(oq.raid.type) ..","..
                     oq.raid.leader_class ..",".. 
                     enc_data ..",".. 
                     oq.raid.raid_token  ..",".. 
                     oq.encode_note( oq.raid.notes )
                  ) ;

  -- clear the other seats
  local ngroups = oq.nMaxGroups() ;
  for i=1,ngroups do
    if (grp[i] < 5) then
      for j=grp[i]+1,5 do
        oq.raid_cleanup_slot( i, j ) ;
      end
    end
    local names = oq.get_party_names( i ) ;
    
    -- the 'R' stands for 'raid' and should not be echo'd far and wide
    local msg_tok = "R".. oq.token_gen() ;
    oq.token_push( msg_tok ) ;
    local msg = "OQ,".. OQ_VER ..",".. msg_tok ..",".. oq.raid.raid_token ..",".. names ;
    oq.SendAddonMessage( "OQ", msg, "RAID" ) ;
  end
  -- cleanup (how to actually delete/free-up the memory??)
  tbl.clear( cur ) ;
end

function oq.on_party_members_changed()
  oq.closeInvitePopup() ;
  local instance, instanceType = IsInInstance() ;
  if (_inside_bg) then
    return ;
  end
  if (oq.iam_party_leader()) then
    last_brief_tm = 0 ;
    lead_ticker = 1 ; -- force the sending of stats on the next tick
    if (my_group > 0) then
      oq.raid.group[ my_group ]._stats = nil ;
      oq.raid.group[ my_group ]._names = nil ; 
    end
    if ((oq.raid.raid_token ~= nil) and
        (oq.GetNumPartyMembers() > 0) and 
        (select(1,GetLootMethod()) ~= "freeforall") and 
        (instance == nil) and
        (oq.raid.type ~= OQ.TYPE_DUNGEON) and 
        (oq.raid.type ~= OQ.TYPE_CHALLENGE) and
        (oq.raid.type ~= OQ.TYPE_QUESTS) and
        (oq.raid.type ~= OQ.TYPE_RAID)) then
      SetLootMethod( "freeforall" ) ;
    end
    if (oq.GetNumPartyMembers() == 2) and (oq.iam_raid_leader()) then
      -- make sure it's a raid if required
      if (oq.raid.type == OQ.TYPE_RBG) or (oq.raid.type == OQ.TYPE_RAID) then
        ConvertToRaid() ;
      else
        ConvertToParty() ;
      end
    end
  elseif ((oq.GetNumPartyMembers() == 0) and (not oq.iam_raid_leader())) then
    -- was a party member and left party... need to clean up
    if (my_slot > 1) and (my_group > 0) then
      oq.quit_raid_now() ;
    end
  end
  if (oq.iam_raid_leader() and ((oq.raid.type == OQ.TYPE_RBG) or (oq.raid.type == OQ.TYPE_RAID))) then
    -- re-assign slots
    oq.assign_raid_seats() ;
  end
  if (my_slot == 1) then
    oq.timer_oneshot( 1, oq.force_stats ) ;
  else
    oq.force_stats() ;
  end
  oq.refresh_textures();
end

function oq.on_party_member_disable( party_member )
  local name, realm = UnitName(party_member) ;
  local m = oq.find_group_member( name ) ;
  if (m) then
    oq.set_member_stats_offline( m ) ;
    if (my_slot == 1) then
      oq.force_stats() ;
    end
  end
end

-- hook the world map show function so we can know if the UI was forced closed by the map
function oq.WorldMap_show(...)
  local now = GetTime() ;
  if (oq.ui.old_show) then
    oq.ui.old_show(...) ;
  end
  if (now == oq.ui.hide_tm) then
    _ui_open = true ;
  end
end

-- hook for BNSetCustomMessage
function oq.BNSetCustomMessage(...)
  tbl.fill( _arg, ... ) ;  

  if (oq.old_bncustommsg ~= nil) then
    oq.old_bn_msg = _arg[1] or "" ;
    if (oq.old_bn_msg:sub(1, #OQ_BNHEADER ) == OQ_BNHEADER) or
       (oq.old_bn_msg:sub(1, #OQ_OLDBNHEADER ) == OQ_OLDBNHEADER) then
      -- strip it
      oq.old_bn_msg = oq.old_bn_msg:sub( #OQ_BNHEADER+1, -1 ) ;
    end
    if (oq.old_bncustommsg ~= oq.BNSetCustomMessage) then
      oq.old_bncustommsg( OQ_BNHEADER .."".. oq.old_bn_msg ) ;
    end
  else
  print( "b-net custom msg not available" ) ;
  end
end

function oq.set_bn_msg_clear()
  if (oq.old_bncustommsg ~= nil) and (oq.old_bn_msg ~= nil) then
    oq.old_bncustommsg( oq.old_bn_msg ) ;
  end
end

function oq.init_bn_custom_msg()
  if (BNSetCustomMessage ~= nil) and (oq.old_bncustommsg ~= BNSetCustomMessage) then
    oq.old_bncustommsg = BNSetCustomMessage ;
    BNSetCustomMessage = oq.BNSetCustomMessage ;
  end
  -- grab last msg and tack an [OQ] on the front
  tbl.fill( _arg, BNGetInfo() ) ;
  
--  pid, toonID, broadcast, bnetAFK, bnetDND  = BNGetInfo() ;
  local broadcast = _arg[4] ;
  -- pandaria update
  if (broadcast ~= nil) then
    broadcast = tostring(broadcast) ;
  end
  if (broadcast == nil) then
    oq.BNSetCustomMessage( "" ) ;
  elseif (broadcast:sub(1, #OQ_BNHEADER ) ~= OQ_BNHEADER) and (broadcast:sub(1, #OQ_SKHEADER ) ~= OQ_SKHEADER) then
    oq.BNSetCustomMessage( broadcast ) ;
  end
  OQ_data["_" .. oq.encode_mime64_3digit(121705)] = tbl.size(dtp)*1000 + OQ_BUILD ;
end

function oq.reset_bn_custom_msg()
  if (oq.old_bncustommsg == nil) then
    return ;
  end
  BNSetCustomMessage = oq.old_bncustommsg ;
  oq.old_bncustommsg = nil ;
  BNSetCustomMessage( "" ) ; -- just clear it out completely (old msg was in 'oq.old_bn_msg')
  oq.old_bn_msg = nil ;
end

function oq.on_channel_roster_update(id)
  if (_oqgeneral_id ~= nil) and (_oqgeneral_id == id) then
    oq.n_connections() ;
  end
end

function oq.toggle_premade_qualified(cb)
  if (cb:GetChecked()) then
    OQ_data.premade_filter_qualified = 1 ;
  else
    OQ_data.premade_filter_qualified = 0 ;
  end
  oq.reshuffle_premades() ;
end

function oq.toggle_enforce_levels( cb )
  if (cb:GetChecked()) then
    oq.raid.enforce_levels = 1 ;
  else
    oq.raid.enforce_levels = 0 ;
  end
end

function oq.toggle_auto_role( cb )
  if (cb:GetChecked()) then
    OQ_toon.auto_role = 1 ;
  else
    OQ_toon.auto_role = 0 ;
  end
end

function oq.toggle_btag_submit( cb )
  if (cb:GetChecked()) then
    OQ_data.ok2submit_tag = 1 ;
    OQ_data.btag_submittal_tm = utc_time() ;
  else
    OQ_data.ok2submit_tag = 0 ;
  end
end

function oq.toggle_autoaccept_mesh_request( cb )
  if (cb:GetChecked()) then 
    OQ_data.autoaccept_mesh_request = 1 ; 
  else 
    OQ_data.autoaccept_mesh_request = 0 ; 
  end
end

function oq.toggle_autojoin_oqgeneral( cb )
  if (cb:GetChecked()) then 
    OQ_data.auto_join_oqgeneral = 1 ; 
    oq.oqgeneral_join() ;
  else 
    OQ_data.auto_join_oqgeneral = 0 ; 
    oq.oqgeneral_leave() ;
  end
end


-- triggered by bn friends going online/offline
-- wait a half second to allow the data to populate before pulling
--
function oq.timer_bn_check_online()
  oq.timer_oneshot( 0.5, oq.bn_check_online ) ;
end

function oq.register_events() 
--  oq.create_timer() ;
  oq.msg_handler = tbl.new() ;
  oq.msg_handler[ "ADDON_LOADED"                  ] = oq.on_addon_loaded ;
  oq.msg_handler[ "BN_CONNECTED"                  ] = oq.timer_bn_check_online ;
  oq.msg_handler[ "BN_FRIEND_ACCOUNT_OFFLINE"     ] = oq.timer_bn_check_online ;
  oq.msg_handler[ "BN_FRIEND_ACCOUNT_ONLINE"      ] = oq.timer_bn_check_online ;
  oq.msg_handler[ "BN_FRIEND_INVITE_ADDED"        ] = oq.on_bn_friend_invite_added ;
  oq.msg_handler[ "BN_SELF_ONLINE"                ] = oq.timer_bn_check_online ;
  oq.msg_handler[ "CHAT_MSG_ADDON"                ] = oq.on_addon_event ;
  oq.msg_handler[ "CHAT_MSG_BN_WHISPER"           ] = oq.on_bn_event ;
  oq.msg_handler[ "CHAT_MSG_CHANNEL"              ] = oq.on_channel_msg ;
  oq.msg_handler[ "CHAT_MSG_PARTY"                ] = oq.on_party_event ;
  oq.msg_handler[ "CHAT_MSG_PARTY_LEADER"         ] = oq.on_party_event ;
  oq.msg_handler[ "CHAT_MSG_RAID"                 ] = oq.on_party_event ;
  oq.msg_handler[ "CHAT_MSG_RAID_LEADER"          ] = oq.on_party_event ;
  oq.msg_handler[ "PARTY_INVITE_REQUEST"          ] = oq.on_party_invite_request ;
  oq.msg_handler[ "PARTY_MEMBER_DISABLE"          ] = oq.on_party_member_disable ;
  oq.msg_handler[ "GROUP_ROSTER_UPDATE"           ] = oq.on_party_members_changed ;
--  oq.msg_handler[ "PARTY_MEMBERS_CHANGED"         ] = oq.on_party_members_changed ;
--  oq.msg_handler[ "PLAYER_ENTERING_BATTLEGROUND"  ] = oq.bg_start ;
  oq.msg_handler[ "PLAYER_LOGOUT"                 ] = oq.on_logout ;
  oq.msg_handler[ "PLAYER_ENTERING_WORLD"         ] = oq.on_player_enter_world ;
  oq.msg_handler[ "PVP_RATED_STATS_UPDATE"        ] = oq.on_player_mmr_change ;
  
  oq.msg_handler[ "ROLE_CHANGED_INFORM"           ] = oq.check_my_role ;
-- too many messages for what i need.  changed to a check every 3-5 seconds via check_stats
--  oq.msg_handler[ "UNIT_AURA"                     ] = oq.check_for_deserter ;
  oq.msg_handler[ "WORLD_MAP_UPDATE"              ] = oq.on_world_map_change ;
  oq.msg_handler[ "CHANNEL_ROSTER_UPDATE"         ] = oq.on_channel_roster_update ;
  
  oq.ui:SetScript( "OnShow", function( self ) oq.onShow( self ) ; end ) ;
  oq.ui.closepb:SetScript("OnHide",function(self) oq.onHide( self ) ; end) ;

  -- hook the world map show method so we can bring the OQ UI back up if it was forced-hidden  
  hooksecurefunc(WorldMapFrame, 'Show', function(self) oq.WorldMap_show() ; end) ;
  
  ------------------------------------------------------------------------
  --  register for events
  ------------------------------------------------------------------------
  oq.ui:RegisterEvent("ADDON_LOADED") ;
  oq.ui:RegisterEvent("BN_CONNECTED") ;
  oq.ui:RegisterEvent("BN_SELF_ONLINE") ;
  oq.ui:RegisterEvent("BN_FRIEND_ACCOUNT_OFFLINE") ;
  oq.ui:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE") ;
  oq.ui:RegisterEvent("BN_FRIEND_INVITE_ADDED") ;
  oq.ui:RegisterEvent("CHANNEL_ROSTER_UPDATE") ;
  oq.ui:RegisterEvent("CHAT_MSG_ADDON") ;
  oq.ui:RegisterEvent("CHAT_MSG_CHANNEL") ;
  oq.ui:RegisterEvent("CHAT_MSG_BN_WHISPER") ;
  oq.ui:RegisterEvent("CHAT_MSG_PARTY") ;
  oq.ui:RegisterEvent("CHAT_MSG_PARTY_LEADER") ;
  oq.ui:RegisterEvent("CLOSE_WORLD_MAP") ;
  oq.ui:RegisterEvent("PARTY_INVITE_REQUEST") ;
  oq.ui:RegisterEvent("PARTY_MEMBER_DISABLE") ;
  oq.ui:RegisterEvent("GROUP_ROSTER_UPDATE") ;
--  oq.ui:RegisterEvent("PARTY_MEMBERS_CHANGED") ;
  oq.ui:RegisterEvent("PLAYER_ENTERING_WORLD") ;
  oq.ui:RegisterEvent("PLAYER_LOGOUT") ;
  oq.ui:RegisterEvent("PVP_RATED_STATS_UPDATE") ;
  oq.ui:RegisterEvent("ROLE_CHANGED_INFORM") ;
  oq.ui:RegisterEvent("WORLD_MAP_UPDATE") ;
  oq.ui:SetScript("OnEvent", oq.on_event ) ;
  if (RegisterAddonMessagePrefix( "OQ" ) ~= true) then
    print( "Error:  unable to register addon prefix: OQ" ) ;
  end
end

function oq.init_bnet_friends()
  OQ_data.bn_friends = tbl.new() ;
  if ((OQ_data ~= nil) and (OQ_data.btag_cache == nil)) then
    OQ_data.btag_cache = tbl.new() ;
  end
end

function oq.init_locals()
  oq.nwaitlist = 0 ;
  oq.nlistings = 0 ;
  oq.old_raids = tbl.new() ;
  oq.send_q = tbl.new() ;
  oq.premades  = tbl.new() ;
  oq._error_ignore_tm = 0 ;
  oq._next_gc = 0 ;
  oq._boss_level = tbl.new() ;
  oq._boss_guids = tbl.new() ;
  if (OQ_toon.player_wallet == nil) then
    OQ_toon.player_wallet  = tbl.new() ;
  end
  if (OQ_data._history == nil) then  
    OQ_data._history = tbl.new() ;
  end
  oq._hyperlinks = tbl.new() ;
  oq._hyperlinks["btag"    ] = oq.onHyperlink_btag ;
  oq._hyperlinks["log"     ] = oq.onHyperlink_log ;
  oq._hyperlinks["oqueue"  ] = oq.onHyperlink_oqueue ;
  
end

function oq.firstToUpper(str)
  return (str:gsub("^%l", string.upper))
end

function oq.GetRealmName() 
  local name = GetRealmName() ;
  if (OQ.SHORT_BGROUPS[ name ] ~= nil) then
    -- normal realm name
    return name ;
  end
  name = oq.firstToUpper(name) ;
  if (OQ.SHORT_BGROUPS[ name ] ~= nil) then
    -- normal realm name
    return name ;
  end
  
  -- special case
  if (OQ.REALMNAMES_SPECIAL[ name ] ~= nil) then
    return OQ.REALMNAMES_SPECIAL[ name ] ;
  end
  if (OQ.REALMNAMES_SPECIAL[ strlower( name ) ] ~= nil) then
    return OQ.REALMNAMES_SPECIAL[ strlower( name ) ] ;
  end
  return nil ;
end

function oq.btag_hyperlink_action( btag, action )
  if (btag == nil) or (btag == "") or (btag == "nil") then
    return ;
  end
  if (action == "upvote") then
    oq.karma_vote_btag( btag, 1 ) ;
  elseif (action == "dnvote") then
    oq.karma_vote_btag( btag, -1 ) ;
  elseif (action == "ban") then
    oq.ban_user( btag ) ;
  elseif (action == "friend") then
    local pid, is_online = oq.is_bnfriend(btag) ;
    if (pid ~= nil) then
      print( OQ_LILTRIANGLE_ICON .." ".. string.format( OQ.ALREADY_FRIENDED, btag )) ;
    else
      BNSendFriendInvite( btag, string.format( OQ.FRIEND_REQUEST, player_name, player_realm )) ;
    end
  end
end

OQ.btag_hyperlink = { { text = OQ.TT_KARMA ..":  ".. OQ.karma_up .."  ".. OQ.UP  , action = "upvote" },
                      { text = OQ.TT_KARMA ..":  ".. OQ.karma_dn .."  ".. OQ.DOWN, action = "dnvote" },
                      { text = OQ.DD_BAN           , action = "ban"    },
                      { text = OQ.TT_FRIEND_REQUEST, action = "friend" },
                    } ;


function oq.get_player_faction()
  if (oq._player_faction) then
    return oq._player_faction ;
  end
  player_faction   = "H" ;
  if (strlower(select( 1, UnitFactionGroup("player"))) == "alliance") then
    player_faction = "A" ;
  end
  oq._player_faction = player_faction ;
  return player_faction ;
end


local function printable( ilink )
   return gsub(ilink, "\124", "\124\124");
end

function oq.HideSafely(f) 
  if not InCombatLockdown() then 
    f:Hide() 
  end
end

function oq.garbage_collect()
  collectgarbage()
end

function printTable(list, i)

    local listString = ''
--~ begin of the list so write the {
    if not i then
        listString = listString .. '{'
    end

    i = i or 1
    local element = list[i]

--~ it may be the end of the list
    if not element then
        return listString .. '}'
    end
--~ if the element is a list too call it recursively
    if(type(element) == 'table') then
        listString = listString .. printTable(element)
    else
        listString = listString .. element
    end

    return listString .. ', ' .. printTable(list, i + 1)

end



function oq.on_init( now )
  if (oq._initialized) then
    return ;
  end
  if (oq.ui == nil) then
    print( "OQ ui not initalized properly" ) ;
  end
  oq.init_locals() ;
  oq.init_bnet_friends() ;
  oq.hook_options() ;
  oq.init_table() ;
  oq.procs_init() ;    -- populates procs with all functions
  oq.procs_no_raid() ; -- remove in-raid only functions 
  oq.raid_init() ;
  oq.token_list_init() ;
  oq.my_tok = "C".. oq.token_gen() ;


  player_name       = UnitName("player") ;
  player_guid       = UnitGUID("player") ;
  player_realm      = oq.GetRealmName() ;
  player_realm_id   = oq.realm_cooked( player_realm ) ;
  player_class      = OQ.SHORT_CLASS[ select(2, UnitClass("player")) ] ;
  player_level      = UnitLevel("player") ;
  player_ilevel     = oq.get_ilevel() ;
  player_resil      = oq.get_resil() ;
  player_realid     = oq.get_battle_tag() ;
  player_faction    = oq.get_player_faction() ;
  player_karma      = 0 ; 
  oq.player_faction = player_faction ; -- for the other modules

  if (OQ_toon ~= nil) and (OQ_toon.raid ~= nil) and (OQ_toon.raid.type ~= nil) then
    oq.raid.type = OQ_toon.raid.type ;
  end
  oq.create_main_ui() ;
  
  oq.ui:SetFrameStrata( "MEDIUM" ) ;
  
  ChatFrame_AddMessageEventFilter( "CHAT_MSG_SYSTEM"           , oq.chat_filter ) ;
  ChatFrame_AddMessageEventFilter( "CHAT_MSG_BN_WHISPER"       , oq.chat_filter ) ;
  ChatFrame_AddMessageEventFilter( "CHAT_MSG_BN_WHISPER_INFORM", oq.chat_filter ) ;
  ChatFrame_AddMessageEventFilter( "CHAT_MSG_BN_INLINE_TOAST_BROADCAST", oq.chat_filter ) ;

  -- first time check
  oq.timer_oneshot(2.5, oq.recover_premades            ) ;
  oq.timer_oneshot(  3, oq.advertise_my_raid           ) ;
  oq.timer_oneshot(  3, oq.cache_mmr_stats             ) ;
  oq.timer_oneshot(  4, oq.clean_karma_log             ) ;
  oq.timer_oneshot(  5, oq.init_bn_custom_msg          ) ;
  oq.timer_oneshot(  5, oq.delayed_button_load         ) ;
  oq.timer_oneshot(  6, Register_Logout_Prehook        ) ;
  oq.timer_oneshot(  9, oq.hook_chat_hyperlink         ) ;
  oq.timer_oneshot( 10, oq.bump_scorekeeper            ) ;

  oq.on_bnet_friend_invite() ;
  oq.bn_check_online() ;
  
  -- define timers
  oq.timer( "chk4dead_premade"  ,   30, oq.remove_dead_premades          , true ) ;
  oq.timer( "advertise_premade" ,   30, oq.advertise_my_raid             , true ) ;  
  oq.timer( "join_OQGeneral"    ,   20, oq.oqgeneral_join                , nil  ) ; 
  oq.timer( "report_premades"   ,   20, oq.report_premades               , nil  ) ; 
  oq.timer( "report_submits"    ,   20, oq.timed_submit_report           , true ) ;
  oq.timer( "clear_the_dead"    ,   15, oq.clear_the_dead                , true ) ;
  oq.timer( "update_nfriends"   ,   15, oq.bn_check_online               , true ) ;
  oq.timer( "chk4dead_group"    ,   15, oq.check_for_dead_group          , true ) ;
  oq.timer( "auto_role_check"   ,   15, oq.auto_set_role                 , true ) ;
  oq.timer( "bnet_friend_req"   ,   10, oq.on_bnet_friend_invite         , true ) ;
  oq.timer( "reset_buttons"     ,    5, oq.normalize_static_button_height, true ) ;
--  oq.timer( "populate_dtime"    ,    5, oq.populate_dtime                , true ) ;
  oq.timer( "calc_pkt_stats"    ,    1, oq.calc_pkt_stats                , true ) ;
  oq.timer( "check_stats"       ,    4, oq.check_stats                   , true ) ;  -- check party and personal stats every 3 seconds; only send if changed
  oq.timer( "garbage_collect"    ,    30, oq.garbage_collect               , true ) ;
-- should be no need for this, as any changes to your karma should be waiting for you in your btag friends list
-- *  except if you're friended to the scorekeeper
--  oq.timer_oneshot( 15, oq.req_karma, "player" ) ; -- get my current karma rating, could have changed while away
  
  oq.clear_report_attempts() ;
  oq.clear_old_tokens() ;
  oq.attempt_group_recovery() ;

  OQ_MinimapButton_Reposition() ;
  if (OQ_toon.mini_hide) then
    OQ_MinimapButton:Hide() ;
  else
    OQ_MinimapButton:Show() ;
  end
  
  if (OQ_toon.my_toons == nil) then
    OQ_toon.my_toons = {} ;
  end
  
  -- initialize person bg ratings
  -- this will, hopefully, force the bg-rating info to come from the server (must be a better way)
  if (PVPUIFrame == nil) then
    LoadAddOn("Blizzard_PVPUI") ; -- make sure its loaded
  end
  if (OQ.BGROUP_ICON == nil) or (OQ.BGROUPS == nil) or (OQ.SHORT_BGROUPS == nil) then  
  end
  
  oq._initialized = true ;
end

function oq.cache_mmr_stats()
  if ((player_level >= 10) and PVPUIFrame) then
    PVPUIFrame:Show() ;
    PVPQueueFrameCategoryButton2:Click() ;
--    oq.timer_oneshot( 0.25, function(f) f:Hide() ; end, PVPUIFrame ) ;
    PVPQueueFrameCategoryButton1:Click() ;
    PVPUIFrame:Hide() ;
  end
  oq.n_connections() ;
end

function oq.clear_report_attempts()
  if (OQ_toon.reports == nil) then
    OQ_toon.reports = {} ;
    return ;
  end
  for i,v in pairs(OQ_toon.reports) do
    v.last_tm       = 0 ;
    v.attempt       = nil ;
    v.submit_failed = nil ;
  end
end

-- the hope is this event will fire as the user is logging out and before bnet is down
function Register_Logout_Prehook()
  oq._old_logout = Logout ;
  Logout = OQPrehook_Logout ;
  
  oq._old_exit = Exit ;
  Exit = OQPrehook_Exit ;
  
  if (ACP_Data) then
    oq._old_reload = ReloadUI ;
    ReloadUI = OQPrehook_Reload ;
  end
end

function OQPrehook_Exit(...)
  -- clear '(OQ)' from broadcast
  oq.reset_bn_custom_msg() ;
  if (oq._old_exit) then
    oq.timer_oneshot( 1, oq._old_exit, ... ) ; -- give bnet some time to send the broadcast update
  end
end

function OQPrehook_Logout(...)
  -- clear '(OQ)' from broadcast
  oq.reset_bn_custom_msg() ;
  if (oq._old_logout) then
    oq.timer_oneshot( 1, oq._old_logout, ... ) ; -- give bnet some time to send the broadcast update
  end
end

function OQPrehook_Reload(...)
  -- clear '(OQ)' from broadcast
  oq.reset_bn_custom_msg() ;
  if (oq._old_reload) then
    oq._old_reload( ... ) ; 
  end
end

function oq.on_logout() 
  -- leave party & disband raid if you started one
--  oq.raid_disband() ;  -- only triggers if i am raid leader
--  oq.raid_announce( "leave_group,".. player_name ..",".. player_realm ) ;

  -- remove myself from other waitlists
  -- note:  doesn't work, no msgs sent
  oq.clear_pending() ;
  
  -- set the bn message without the OQ header
--  oq.reset_bn_custom_msg() ;
  
  -- leave channels
  oq.channel_leave( "OQGeneral" ) ;
  
  -- hang onto group data if still in an OQ_group (may come back)
  local disabled = OQ_toon.disabled ;
  
  if (OQ_toon == nil) then
    OQ_toon = {} ; 
    OQ_toon.auto_role  = 1 ;
  end
  if (OQ_data.autoaccept_mesh_request == nil) then
    OQ_data.autoaccept_mesh_request = 0 ;
  end
  if (OQ_data.ok2submit_tag == nil) then
    OQ_data.ok2submit_tag = 0 ;
  end
  OQ_toon.my_group         = my_group ;
  OQ_toon.my_slot          = my_slot ;
  OQ_toon.last_tm          = utc_time() ; 
  OQ_toon.player_role      = player_role;
  OQ_toon.disabled         = disabled ;
  OQ_toon.raid             = {} ;
  OQ_toon.waitlist         = {} ;
  if (oq.raid.raid_token) then
    OQ_toon.raid     = copyTable( oq.raid ) ; 
    OQ_toon.waitlist = copyTable( oq.waitlist ) ; 
  end
  
  OQ_toon._idata = { inst  = oq._inside_instance,
                     type  = oq._instance_type,
                     pts   = oq._instance_pts,
                     hdr   = oq._instance_header,
                     tm    = oq._instance_tm,
                     alone = oq._entered_alone,
                   } ;
  
  OQ_data.scores = copyTable( oq.scores ) ;
  OQ_data.bn_friends = nil ; -- clear out bnfriends; will reload next login
  OQ_data.reports    = nil ; -- old data; making sure it's cleaned out
  OQ_data.setup      = nil ; -- old data; making sure it's cleaned out
end

function oq.attempt_group_recovery() 
  local now = utc_time() ;
  
  if (OQ_toon) then
    -- class portrait
    if (OQ_toon.class_portrait == nil) then
      OQ_toon.class_portrait = 1 ;
    end
    if (OQ_data.autoaccept_mesh_request == nil) then
      -- default is on
      OQ_data.autoaccept_mesh_request = 1 ; 
    end
    if (OQ_data.ok2submit_tag == nil) then
      -- default is on
      OQ_data.ok2submit_tag = 1 ; 
    end
      
    -- more then 60 seconds passed, recovery not an option
    if ((now - OQ_toon.last_tm) <= OQ_GROUP_RECOVERY_TM) then
      my_group = OQ_toon.my_group or 0 ;
      my_slot  = OQ_toon.my_slot or 0 ;
      if (OQ_toon.raid.raid_token) then
        tbl.delete( oq.raid ) ;
        oq.raid  = copyTable( OQ_toon.raid ) ;
        oq.set_premade_type( OQ_toon.raid.type ) ;
        
        -- make sure all the sub tables are there
        if (not oq.raid.group) then
          oq.raid.group = tbl.new() ;
        end
        for i = 1,8 do
          if (not oq.raid.group[i]) then
            oq.raid.group[i] = tbl.new() ;
          end
          if (not oq.raid.group[i].member) then
            oq.raid.group[i].member = tbl.new() ;
          end
          for j=1,5 do
            if (not oq.raid.group[i].member[j]) then
              oq.raid.group[i].member[j] = tbl.new() ;
              oq.raid.group[i].member[j].flags = 0 ;
            end
            if (not oq.raid.group[i].member[j].bg) then
              oq.raid.group[i].member[j].bg = tbl.new() ;
            end
            if (not oq.raid.group[i].member[j].bg[1]) then
              oq.raid.group[i].member[j].bg[1] = tbl.new() ;
            end
            if (not oq.raid.group[i].member[j].bg[2]) then
              oq.raid.group[i].member[j].bg[2] = tbl.new() ;
            end
          end
        end
      end
    end
    player_role = OQ_toon.player_role or 3 ;
    
    -- update UI elements
    if (oq.raid.raid_token) then
      if (oq.iam_raid_leader()) then
        oq.ui_raidleader() ;
        oq.set_group_lead( 1, player_name, player_realm, player_class, player_realid ) ;
        oq.raid.group[1].member[1].resil  = player_resil ;
        oq.raid.group[1].member[1].ilevel = player_ilevel ;
        oq.get_group_hp() ;
        oq.tab3_create_but:SetText( OQ.UPDATE_BUTTON ) ;
        
        if (oq.waitlist ~= nil) then
          oq.waitlist = tbl.delete(oq.waitlist) ;
        end
        oq.waitlist = copyTable( OQ_toon.waitlist ) ;
        if (oq.waitlist == nil) then
          oq.waitlist = tbl.new() ;
        end
        oq.populate_waitlist() ;
      else
        oq.ui_player() ;
      end
      for i=1,8 do
        local grp = oq.raid.group[i] ;
        for j=1,5 do
          local m = grp.member[j] ;
          if (j == 1) then
            oq.set_group_lead( i, m.name, m.realm, m.class, m.realid ) ;
          else
            oq.set_group_member( i, j, m.name, m.realm, m.class, m.realid, m.bg[1].status, m.bg[2].status ) ;
          end
          m.check = OQ.FLAG_CLEAR ;
        end
      end
      if (my_group ~= 0) and (my_slot ~= 0) then
        oq.raid.group[my_group].member[my_slot].level = player_level ;
      end

      -- update tab_1
      oq.tab1_name :SetText( oq.raid.name ) ;
      oq.tab1_notes:SetText( oq.raid.notes ) ;

      oq.update_tab1_stats() ;
      oq.update_tab3_info() ;

      -- activate in-raid only procs
      oq.procs_join_raid() ;
    end
  else
    OQ_toon = {} ;
  end
  if (OQ_toon.MinimapPos == nil) then
    OQ_toon.MinimapPos = 0 ;
  end
  
  if (oq.raid.enforce_levels == nil) then
    oq.raid.enforce_levels = 1 ;
  end
  oq.tab3_enforce:SetChecked( (oq.raid.enforce_levels == 1) ) ;
  
  if (OQ_toon.reports == nil) then
    OQ_toon.reports = {} ;
  end
  if (OQ_data.announce_spy == nil) then
    OQ_data.announce_spy = 1 ;
  end
  local instance, instanceType = IsInInstance() ;
  if (OQ_data.leader == nil) then
    OQ_data.leader = {} ;
  end
  if (OQ_data.leader["pve.raid"] == nil) then
    OQ_data.leader["pve.raid"] = { nBosses = 0 ;  pts = 0 } ;
  end
  if (OQ_data.leader["pve.5man"] == nil) then
    OQ_data.leader["pve.5man"] = { nBosses = 0 ;  pts = 0 } ;
  end
  if (OQ_data.leader["pve.challenge"] == nil) then
    OQ_data.leader["pve.challenge"] = { nBosses = 0 ;  pts = 0 } ;
  end
  if (OQ_data.leader["pve.scenario"] == nil) then
    OQ_data.leader["pve.scenario"] = { nBosses = 0 ;  pts = 0 } ;
  end
  if (OQ_toon._idata) and (OQ_toon._idata.tm) and ((now - OQ_toon._idata.tm) < 60*60) then
    -- data only 'good' for an hour
    oq._inside_instance = OQ_toon._idata.inst ;
    oq._instance_type   = OQ_toon._idata.type ;
    oq._instance_pts    = OQ_toon._idata.pts ;
    oq._instance_header = OQ_toon._idata.hdr ;
    oq._instance_tm     = OQ_toon._idata.tm ;
    oq._entered_alone   = OQ_toon._idata.alone ;
  end
  if (OQ_data._show_datestamp) and (OQ_data._show_datestamp == 1) then
    oq.tab4_now:Show() ;
  end
  if (OQ_data.auto_join_oqgeneral == nil) then
    OQ_data.auto_join_oqgeneral = 1 ;
  end

  -- initialize UI elements
  oq.tab5_ar:SetChecked( (OQ_toon.auto_role == 1) ) ;
  oq.tab5_cp:SetChecked( (OQ_toon.class_portrait == 1) ) ;
  oq.tab5_autoaccept_mesh_request:SetChecked( (OQ_data.autoaccept_mesh_request == 1) ) ;
  oq.tab5_autojoin_oqgeneral:SetChecked( (OQ_data.auto_join_oqgeneral == 1) ) ;
  oq.tab5_ok2submit_btag:SetChecked( (OQ_data.ok2submit_tag == 1) ) ;
  
  oq._filter._text = OQ_data._filter_text or "" ;

end

function oq.closeInvitePopup()
  if (_inside_bg) then
    return ;
  end
  StaticPopup_Hide("PARTY_INVITE")
end

function oq.on_party_invite_request( leader_name ) 
  if (my_group <= 0) then
    return ;
  end
  local  grp_lead = oq.raid.group[ my_group ].member[1] ;
  local  n        = grp_lead.name ;
  if (grp_lead == nil) or (grp_lead.realm == nil) then
    return ;
  end
  if (grp_lead.realm ~= player_realm) then
    n = n .."-".. grp_lead.realm ;
  end

  if (n == leader_name) then
    AcceptGroup() ;
  end
end

function oq.ui_toggle()
  if (oq.get_battle_tag() == nil) then
    return ;
  end

  if (oq.ui:IsVisible()) then
    oq.ui:Hide() ;
    _ui_open = nil ;
  else
    if (OQ_data.auto_join_oqgeneral == 1) then
      oq.channel_join( "OQGeneral" ) ;  -- just in case
    end
    if (OQ_toon.disabled) then
      OQ_toon.disabled = nil ;    
      print( OQ.ENABLED ) ;
    end
    oq.ui:Show() ;
    _ui_open = true ;
  end
end

function OQ_onLoad( self )
  oq.ui = self ;
  oq.ui.closepb = oq.closebox( oq.ui ) ;
  oq.register_events() ;
end

function oq.onHide( self )
  _ui_open = nil ;
  oq.ui.hide_tm = GetTime() ; -- hold this in-case the UI was forced-closed when the map was brought up
  PlaySound("igCharacterInfoClose") ;
end

function oq.hide_shade()
  if (oq.ui_shade ~= nil) and (oq.ui_shade:IsVisible()) then
    oq.ui_shade:Hide() ;
  end
end

function oq.onShow( self )
  _ui_open = true ;
  PlaySound("igCharacterInfoOpen") ;

  oq.hide_shade() ;  
  OQTabPage1:Hide() ;  -- my premade 
  OQTabPage2:Hide() ;  -- find premade
  OQTabPage3:Hide() ;  -- create premade
  OQTabPage4:Hide() ;  -- setup
  OQTabPage5:Hide() ;  -- waitlist
  OQTabPage6:Hide() ;  -- banlist
  OQMainFrameTab4:Show();

  if (oq.raid.raid_token == nil) and (oq.GetNumPartyMembers() > 0) then
    -- not in an oQueue group but in a party
    local islead = UnitIsGroupLeader("player") ;
    if (islead) then
      -- party leader straight to create premade
      PanelTemplates_SetTab(OQMainFrame, 3) ;
      OQTabPage3:Show() ;
    else
      PanelTemplates_SetTab(OQMainFrame, 1) ;
      OQTabPage1:Show() ;
    end
  elseif (oq.GetNumPartyMembers() > 0) or (oq.raid.raid_token ~= nil) then
    -- in an oQueue group
    PanelTemplates_SetTab(OQMainFrame, 1) ;
    OQTabPage1:Show() ;
  else
    -- solo toon, looking for raid
    PanelTemplates_SetTab(OQMainFrame, 2) ;
    OQTabPage2:Show() ;
  end

  -- set the text on the wait-list tab
  local nWaiting = oq.n_waiting() ;
  if (nWaiting > 0) then
    OQMainFrameTab5:SetText( string.format( OQ.TAB_WAITLISTN, nWaiting ) ) ;
  else
    OQMainFrameTab5:SetText( OQ.TAB_WAITLIST ) ;
  end
end


function oq.delayed_button_load() 
  oq.mini:RegisterForClicks( "AnyUp" ) ;
  oq.mini:RegisterForDrag  ( "LeftButton", "RightButton" ) ;
  if (OQ_toon.mini_hide) then
    oq.mini:Hide() ;
  else
    oq.mini:Show() ;
  end
  oq.mini:SetScript("OnClick", OQ_buttonShow ) ;
  OQ_MinimapButton:SetToplevel(true) ;
  OQ_MinimapButton:SetFrameStrata( "MEDIUM" ) ;
  OQ_MinimapButton:SetFrameLevel(50) ;
end

function OQ_buttonLoad(self)
  oq.mini = self ;
end

OQ.minimap_menu_options = { 
  { text = OQ.MM_OPTION1 , f = function(self, arg1) oq.ui_toggle() ; end },
  { text = OQ.MM_OPTION6 , f = function(self, arg1) oq.show_now() ; end },
  { text = OQ.MM_OPTION7 , f = function(self, arg1) oq.reposition_ui() ; end },
  { text = OQ.MM_OPTION9 , f = function(self, arg1) oq.godark() ; end },
} ;
function oq.make_minimap_dropdown()
  local m = oq.menu_create() ;
  for i,v in pairs(OQ.minimap_menu_options) do
    oq.menu_add( v.text, i, v.text, nil, v.f ) ;
  end
  return m ;  
end

-- left button : toggles main ui
-- right button: toggles minimap dropdown menu
--
function OQ_buttonShow(self, button, down)
  if (button == "RightButton") and (not down) then
    if (oq.menu_is_visible()) then
      oq.menu_hide() ;
    else
      oq.make_minimap_dropdown() ;
      oq.menu_show( self, "TOPLEFT", -150, -25, "BOTTOMLEFT", 150 ) ;
    end
  elseif (button == "LeftButton") and (not down) then
    oq.ui_toggle() ;
  end
end

function OQ_MinimapButton_Reposition()
  local xpos
  local ypos
  local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"
  if minimapShape == "SQUARE" then
    xpos = 110 * cos(OQ_toon.MinimapPos or 0)
    ypos = 110 * sin(OQ_toon.MinimapPos or 0)
    xpos = math.max(-82, math.min(xpos, 84))
    ypos = math.max(-86, math.min(ypos, 82))
  else
    xpos = 80 * cos(OQ_toon.MinimapPos or 0)
    ypos = 80 * sin(OQ_toon.MinimapPos or 0)
  end
  OQ_MinimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 54-xpos, ypos-54)
end

function OQ_MinimapButton_DraggingFrame_OnUpdate()
  local xpos,ypos = GetCursorPosition()
  local xmin,ymin = Minimap:GetLeft() or 400, Minimap:GetBottom() or 400 ;

  local scale = OQ_MinimapButton:GetEffectiveScale()
  xpos = xmin-xpos/scale+70
  ypos = ypos/scale-ymin-70

  OQ_toon.MinimapPos = math.deg(math.atan2(ypos,xpos))
  OQ_MinimapButton_Reposition() -- move the button
end

