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

OQ.TRANSLATED_BY["itIT"] = "" ;
if ( GetLocale() ~= "itIT" ) then
  return ;
end
local L = OQ._T ; -- for literal string translations

local DK = {
["Sangue"]          = "Tank",
["Gelo"]            = "Melee",
["Empietà"]         = "Melee",
}

local DRUID = {
["Equilibrio"]          = "Knockback",
["Aggressore Ferino"]   = "Melee",
["Rigenerazione"]       = "Healer",
["Guardiano Ferino"]    = "Tank",
}

local HUNTER = {
["Affinità Animale"]    = "Knockback",
["Precisione Di tiro"]  = "Ranged",
["Sopravvivenza"]       = "Ranged",
}

local MAGE = {
["Arcano"]        = "Knockback",
["Fuoco"]         = "Ranged",
["Gelo"]          = "Ranged",
}

local MONK = {
["Mastro Birraio"] = "Tank",
["Misticismo"]     = "Healer",
["Impeto"]         = "Melee",
}

local PALADIN = {
["Sacro"]        = "Healer",
["Protezione"]   = "Tank",
["Castigo"]      = "Melee",
}

local PRIEST = {
["Disciplina"]     = "Healer",
["Sacro"]          = "Healer",
["Ombra"]          = "Ranged",
}

local ROGUE = {
["Assassinio"]       = "Melee",
["Combattimento"]    = "Melee",
["Scaltrezza"]       = "Melee",
}

local SHAMAN = {
["Elementale"]      = "Knockback",
["Potenziamento"]   = "Melee",
["Rigenerazione"]   = "Healer",
}

local WARLOCK = {
["Afflizione"]   = "Knockback",
["Demonologia"]  = "Knockback",
["Distruzione"]  = "Knockback",
}

local WARRIOR = {
["Armi"]         = "Melee",
["Furia"]        = "Melee",
["Protezione"]   = "Tank",
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
