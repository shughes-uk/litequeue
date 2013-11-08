--[[ 
  @file       oqueue.es.lua
  @brief      localization for oqueue addon (spanish)

  @author     rmcinnis
  @date       june 11, 2012
  @par        copyright (c) 2012 Solid ICE Technologies, Inc.  All rights reserved.
              this file may be distributed so long as it remains unaltered
              if this file is posted to a web site, credit must be given to me along with a link to my web page
              no code in this file may be used in other works without expressed permission  
]]--
local addonName, OQ = ... ;

OQ.TRANSLATED_BY["frFR"] = "Shamallo" ;
OQ.TRANSLATED_BY["frFR"] = "" ;
if ( GetLocale() ~= "frFR" ) then
  return ;
end
local L = OQ._T ; -- for literal string translations

local DK = {
["Sang"]          = "Tank",
["Givre"]         = "Melee",
["Impie"]         = "Melee",
}

local DRUID = {
["Équilibre"]     = "Knockback",
["Farouche"]      = "Melee",
["Restauration"]  = "Healer",
["Gardien"]       = "Tank",
}

local HUNTER = {
["Maîtrise des bêtes"] = "Knockback",
["Précision"]          = "Ranged",
["Survie"]             = "Ranged",
}

local MAGE = {
["Arcanes"]       = "Knockback",
["Feu"]           = "Ranged",
["Givre"]         = "Ranged",
}

local MONK = {
["Maître brasseur"] = "Tank",
["Tisse-brume"]     = "Healer",
["Marche-vent"]     = "Melee",
}

local PALADIN = {
["Sacré"]        = "Healer",
["Protection"]   = "Tank",
["Vindicte"]     = "Melee",
}

local PRIEST = {
["Discipline"]    = "Healer",
["Sacré"]         = "Healer",
["Ombre"]         = "Ranged",
}

local ROGUE = {
["Assassinat"]  = "Melee",
["Combat"]      = "Melee",
["Finesse"]     = "Melee",
}

local SHAMAN = {
["Élementaire"]    = "Knockback",
["Amélioration"]   = "Melee",
["Restauration"]   = "Healer",
}

local WARLOCK = {
["Affliction"]   = "Knockback",
["Démonologie"]  = "Knockback",
["Destruction"]  = "Knockback",
}

local WARRIOR = {
["Armes"]        = "Melee",
["Fureur"]       = "Melee",
["Protection"]   = "Tank",
}

OQ.BG_ROLES["DEATHKNIGHT" ] = DK ;
OQ.BG_ROLES["DRUID"       ] = DRUID ;
OQ.BG_ROLES["HUNTER"      ] = HUNTER ;
OQ.BG_ROLES["MAGE"        ] = MAGE ;
OQ.BG_ROLES["MONK"        ] = MONK ;
OQ.BG_ROLES["PALADIN"     ] = PALADIN ;
OQ.BG_ROLES["PRIEST"      ] = PRIEST ;
OQ.BG_ROLES["ROGUE"       ] = ROGUE ;
OQ.BG_ROLES["SHAMAN"      ] = SHAMAN ;
OQ.BG_ROLES["WARLOCK"     ] = WARLOCK ;
OQ.BG_ROLES["WARRIOR"     ] = WARRIOR ;
