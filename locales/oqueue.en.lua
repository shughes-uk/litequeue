--[[ 
  @file       oqueue.en.lua
  @brief      localization for oqueue addon (english - default)

  @author     rmcinnis
  @date       june 11, 2012
  @par        copyright (c) 2012 Solid ICE Technologies, Inc.  All rights reserved.
              this file may be distributed so long as it remains unaltered
              if this file is posted to a web site, credit must be given to me along with a link to my web page
              no code in this file may be used in other works without expressed permission  
]]--
local addonName, OQ = ... ;

OQ._T = {} ; -- used for literal string conversations
local function defaultFunc(L, key)
 -- If this function was called, we have no localization for this key.
 -- We could complain loudly to allow localizers to see the error of their ways, 
 -- but, for now, just return the key as its own localization. This allows you to—avoid writing the default localization out explicitly.
 return key;
end
setmetatable(OQ._T, {__index=defaultFunc}) ;
local L = OQ._T ;


OQ.TITLE_LEFT         = "oQueue v" ;
OQ.TITLE_RIGHT        = " - Premade finder" ;
OQ.BNET_FRIENDS       = "%d  b-net friends" ;
OQ.PREMADE            = "Premade" ;
OQ.FINDPREMADE        = "Find Premade" ;
OQ.CREATEPREMADE      = "Create Premade" ;
OQ.CREATE_BUTTON      = "create premade" ;
OQ.UPDATE_BUTTON      = "update premade" ;
OQ.WAITLIST           = "Wait List" ;
OQ.HONOR_BUTTON       = "OQ premade" ;
OQ.SETUP              = "Setup" ;
OQ.PLEASE_SELECT_BG   = "Please select a battleground" ;
OQ.BAD_REALID         = "Invalid real-id or battle-tag.\n" ;
OQ.QUEUE1_SELECTBG    = "<select a battleground>" ;
OQ.NOLEADS_IN_RAID    = "There are no group leads in a raid" ;
OQ.NOGROUPS_IN_RAID   = "Cannot invite group into a raid directly" ;
OQ.BUT_INVITE         = "invite" ;
OQ.BUT_GROUPLEAD      = "group lead" ;
OQ.BUT_INVITEGROUP    = "group (%d)" ;
OQ.BUT_WAITLIST       = "wait list" ;
OQ.BUT_INGAME         = "in game" ;
OQ.BUT_PENDING        = "pending" ;
OQ.BUT_INPROGRESS     = "in battle" ;
OQ.BUT_NOTAVAILABLE   = "pending" ;
OQ.BUT_FINDMESH       = "find mesh" ;
OQ.BUT_SUBMIT2MESH    = "submit b-tag" ;
OQ.BUT_PULL_BTAG      = "remove b-tag" ;
OQ.BUT_BAN_BTAG       = "ban b-tag" ;
OQ.TT_LEADER          = "leader" ;
OQ.TT_REALM           = "realm" ;
OQ.TT_BATTLEGROUP     = "battlegroup" ;
OQ.TT_MEMBERS         = "members" ;
OQ.TT_WAITLIST        = "wait list" ;
OQ.TT_RECORD          = "record (win - loss)" ;
OQ.TT_AVG_HONOR       =  "avg honor/game" ;
OQ.TT_AVG_HKS         = "avg hks/game" ;
OQ.TT_AVG_GAME_LEN    = "avg game length" ;
OQ.TT_AVG_DOWNTIME    = "avg down time" ;
OQ.TT_RESIL           = "resil" ;
OQ.TT_ILEVEL          = "ilevel" ;
OQ.TT_MAXHP           = "max hp" ;
OQ.TT_WINLOSS         = "win - loss" ;
OQ.TT_HKS             = "total hks" ;
OQ.TT_OQVERSION       = "version" ;
OQ.TT_TEARS           = "tears" ;
OQ.TT_PVPPOWER        = "pvp power" ;
OQ.TT_MMR             = "rbg rating" ;
OQ.JOIN_QUEUE         = "join queue" ;
OQ.LEAVE_QUEUE        = "leave queue" ;
OQ.LEAVE_QUEUE_BIG    = "LEAVE QUEUE" ;
OQ.DAS_BOOT           = "DAS BOOT !!" ;
OQ.DISBAND_PREMADE    = "disband premade group" ;
OQ.LEAVE_PREMADE      = "leave premade group" ;
OQ.RELOAD             = "reload" ;
OQ.ILL_BRB            = "be right back" ;
OQ.LUCKY_CHARMS       = "lucky charms" ;
OQ.IAM_BACK           = "I'm back" ;
OQ.ROLE_CHK           = "role check" ;
OQ.READY_CHK          = "ready check" ;
OQ.APPROACHING_CAP    = "APPROACHING CAP" ;
OQ.CAPPED             = "CAPPED" ;
OQ.HDR_PREMADE_NAME   = "premades" ;
OQ.HDR_LEADER         = "leader" ;
OQ.HDR_LEVEL_RANGE    = "level(s)" ;
OQ.HDR_ILEVEL         = "ilevel" ;
OQ.HDR_RESIL          = "resil" ;
OQ.HDR_POWER          = "pvp power" ;
OQ.HDR_TIME           = "time" ;
OQ.QUALIFIED          = "qualified" ;
OQ.PREMADE_NAME       = "Premade name" ;
OQ.LEADERS_NAME       = "Leader's name" ;
OQ.REALID             = "Real-Id or B-tag" ;
OQ.REALID_MOP         = "Battle-tag" ;
OQ.MIN_ILEVEL         = "Minimum ilevel" ;
OQ.MIN_RESIL          = "Minimum resil" ;
OQ.MIN_MMR            = "Minimum BG rating" ;
OQ.BATTLEGROUNDS      = "Description" ;
OQ.ENFORCE_LEVELS     = "enforce level bracket" ;
OQ.NOTES              = "Notes" ;
OQ.PASSWORD           = "Password" ;
OQ.CREATEURPREMADE    = "Create your own premade" ;
OQ.LABEL_LEVEL        = "Level" ;
OQ.LABEL_LEVELS       = "Levels" ;
OQ.HDR_BGROUP         = "bgroup" ;
OQ.HDR_TOONNAME       = "toon name" ;
OQ.HDR_REALM          = "realm" ;
OQ.HDR_LEVEL          = "level" ;
OQ.HDR_ILEVEL         = "ilevel" ;
OQ.HDR_RESIL          = "resil" ;
OQ.HDR_MMR            = "rating" ;
OQ.HDR_PVPPOWER       = "power" ;
OQ.HDR_HASTE          = "haste" ;
OQ.HDR_MASTERY        = "mastery" ;
OQ.HDR_HIT            = "hit" ;
OQ.HDR_DATE           = "date" ;
OQ.HDR_BTAG           = "battle.tag" ;
OQ.HDR_REASON         = "reason" ;
OQ.RAFK_ENABLED       = "rafk enabled" ;
OQ.RAFK_DISABLED      = "rafk disabled" ;
OQ.SETUP_HEADING      = "Setup and various commands" ;
OQ.SETUP_BTAG         = "Battlenet email address" ;
OQ.SETUP_GODARK_LBL   = "Tell all OQ friends you're going dark" ;
OQ.SETUP_CAPCHK       = "Force OQ capability check" ;
OQ.SETUP_REMOQADDED   = "Remove OQ-added B.net friends" ;
OQ.SETUP_REMOVEBTAG   = "Remove b-tag from scorekeeper" ;
OQ.SETUP_ALTLIST      = "list of alts on this battle.net account:\n(only for multi-boxers)" ;
OQ.SETUP_AUTOROLE     = "Auto set role" ;
OQ.SETUP_CLASSPORTRAIT = "Use class portraits" ;
OQ.SETUP_SAYSAPPED    = "Say Sapped" ;
OQ.SETUP_WHOPOPPED    = "Who Popped Lust?" ;
OQ.SETUP_GARBAGE      = "garbage collect (30 sec intervals)" ;
OQ.SETUP_SHOUTKBS     = "Announce killing blows" ;
OQ.SETUP_SHOUTCAPS    = "Announce BG objectives" ;
OQ.SETUP_SHOUTADS     = "Announce premades" ;
OQ.SETUP_AUTOACCEPT_MESH_REQ = "Auto accept b-tag mesh requests" ;
OQ.SETUP_ANNOUNCE_RAGEQUIT   = "Announce rage quitters" ;
OQ.SETUP_OK2SUBMIT_BTAG      = "Submit b-tag every 4 days" ;
OQ.SETUP_AUTOJOIN_OQGENERAL  = "Auto join oqgeneral channel" ;
OQ.SETUP_ADD          = "add" ;
OQ.SETUP_MYCREW       = "my crew" ;
OQ.SETUP_CLEAR        = "clear" ;
OQ.SETUP_COLORBLIND   = "Color Blind Support" ;
OQ.SAPPED             = "{rt8}  Sapped  {rt8}" ;
OQ.BN_FRIENDS         = "OQ enabled friends" ;
OQ.LOCAL_OQ_USERS     = "OQ enabled locals" ;
OQ.PPS_SENT           = "pkts sent/sec" ;
OQ.PPS_RECVD          = "pkts recvd/sec" ;
OQ.PPS_PROCESSED      = "pkts processed/sec" ;
OQ.MEM_USED           = "memory used (kB)" ;
OQ.BANDWIDTH_UP       = "upload (kBps)" ;
OQ.BANDWIDTH_DN       = "download (kBps)" ;
OQ.OQSK_DTIME         = "time variance" ;
OQ.SETUP_CHECKNOW     = "check now" ;
OQ.SETUP_GODARK       = "go dark" ;
OQ.SETUP_REMOVENOW    = "remove now" ;
OQ.STILL_IN_PREMADE   = "please leave your current premade before creating a new one" ;
OQ.DD_PROMOTE         = "promote to group lead" ;
OQ.DD_KICK            = "remove member" ;
OQ.DD_BAN             = "BAN user's battle.tag" ;
OQ.DISABLED           = "oQueue disabled" ;
OQ.ENABLED            = "oQueue enabled" ;
OQ.THETIMEIS          = "the time is %d (GMT)" ;
OQ.RAGEQUITSOFAR      = " rage quit: %s  after %d:%02d  (%d so far)" ;
OQ.RAGEQUITTERS       = "%d rage quit over %d:%02d" ;
OQ.RAGELASTGAME       = "%d rage quit last game (bg lasted %d:%02d)" ;
OQ.NORAGEQUITS        = "you are not in a battleground" ;
OQ.RAGEQUITS          = "%d rage quit so far" ;
OQ.MSG_PREMADENAME    = "please enter a name for the premade" ;
OQ.MSG_MISSINGNAME    = "please name your premade" ;
OQ.MSG_REJECT         = "waitlist request not accepted.\nreason: %s" ;
OQ.MSG_CANNOTCREATE_TOOLOW   = "Cannot create premade.  \nYou must be level 10 or higher" ;
OQ.MSG_NOTLFG         = "Please do not use oQueue as LookingForGroup advertisement. \nSome players may ban you from their premade if you do." ;
OQ.TAB_PREMADE        = "Premade" ;
OQ.TAB_FINDPREMADE    = "Find Premade" ;
OQ.TAB_CREATEPREMADE  = "Create Premade" ;
OQ.TAB_THESCORE       = "The Score" ;
OQ.TAB_SETUP          = "Setup" ;
OQ.TAB_BANLIST        = "Ban List" ;
OQ.TAB_WAITLIST       = "Wait List" ;
OQ.TAB_WAITLISTN      = "Wait List (%d)" ;
OQ.CONNECTIONS        = "connection  %d - %d" ;
OQ.ANNOUNCE_PREMADES  = "%d premades available" ;
OQ.NEW_PREMADE        = "(|cFF808080%d|r) |cFFC0C0C0%s|r : %s  |cFFC0C0C0%s|r" ;
OQ.PREMADE_NAMEUPD    = "(|cFF808080%d|r) |cFFC0C0C0%s|r : %s  |cFFC0C0C0%s|r" ;
OQ.DLG_OK             = "ok" ;
OQ.DLG_YES            = "yes" ;
OQ.DLG_NO             = "no" ;
OQ.DLG_CANCEL         = "cancel" ;
OQ.DLG_ENTER          = "Enter Battle" ;
OQ.DLG_LEAVE          = "Leave Queue" ;
OQ.DLG_READY          = "Ready" ;
OQ.DLG_NOTREADY       = "NOT Ready" ;
OQ.DLG_01             = "Please enter toon name:" ;
OQ.DLG_02             = "Enter Battle" ;
OQ.DLG_03             = "Please name your premade:" ;
OQ.DLG_04             = "Please enter your real-id:" ;
OQ.DLG_05             = "Password:" ;
OQ.DLG_06             = "Please enter real-id or name of new group leader:" ;
OQ.DLG_07             = "\nNEW VERSION Now Available !!\n\noQueue  v%s  build  %d\n" ;
OQ.DLG_08             = "Please leave your party to join the wait list or \nAsk your group leader to queue the whole party" ;
OQ.DLG_09             = "Only the group leader may create an OQ Premade" ;
OQ.DLG_10             = "The queue has popped.\n\nWhat is your decision?" ;
OQ.DLG_11             = "Your queue has popped.  Waiting for Raid Leader to make a decision.\nPlease stand by." ;
OQ.DLG_12             = "Are you sure you want to leave the raid group?" ;
OQ.DLG_13             = "The premade leader has initiated a ready check" ;
OQ.DLG_14             = "The raider leader has requested a reload" ;
OQ.DLG_15             = "Banning: %s \nPlease enter your reason:" ;
OQ.DLG_16             = "Unable to select premade type.\nToo many members (max. %d)" ;
OQ.DLG_17             = "Please enter the battle-tag to ban:" ;
OQ.DLG_18a            = "Version %d.%d.%d is now available" ;
OQ.DLG_18b            = "--  Required Update  --" ;
OQ.DLG_19             = "You must qualify for your own premade" ;
OQ.DLG_20             = "No groups allowed for this premade type" ;
OQ.DLG_21             = "Leave your premade before wait listing" ;
OQ.DLG_22             = "Disband your premade before wait listing" ;
OQ.MENU_KICKGROUP     = "kick group" ;
OQ.MENU_SETLEAD       = "set group leader" ;
OQ.HONOR_PTS          = "Honor Points" ;
OQ.NOBTAG_01          = " battle-tag information not received in time." ;
OQ.NOBTAG_02          = " please try again." ;
OQ.MINIMAP_HIDDEN     = "(OQ) minimap button hidden" ;
OQ.MINIMAP_SHOWN      = "(OQ) minimap button shown" ;
OQ.FINDMESH_OK        = "your connection is fine.  premades refresh on 30 second cycles" ;
OQ.TIMEERROR_1        = "OQ: your system time is significantly out of sync (%s)." ;
OQ.TIMEERROR_2        = "OQ: please update your system time and timezone." ;
OQ.SYS_YOUARE_AFK     = "You are now Away" ;
OQ.SYS_YOUARENOT_AFK  = "You are no longer Away" ;
OQ.ERROR_REGIONDATA   = "Region data has not loaded properly." ;
OQ.TT_LEAVEPREMADE    = "left-click:  de-waitlist\nright-click:  ban premade leader" ;
OQ.TT_FINDMESH        = "request battle-tags from the scorekeeper\nto get connected to the mesh" ;
OQ.TT_SUBMIT2MESH     = "submit your battle-tag to the scorekeeper\nto help grow the mesh" ;
OQ.LABEL_TYPE         = "|cFF808080type:|r  %s" ;
OQ.LABEL_ALL          = "all premades" ;
OQ.LABEL_BGS          = "battlegrounds" ;
OQ.LABEL_RBGS         = "rated bgs" ;
OQ.LABEL_DUNGEONS     = "dungeons" ;
OQ.LABEL_LADDERS      = "ladders" ;
OQ.LABEL_RAIDS        = "raids" ;
OQ.LABEL_SCENARIOS    = "scenarios" ;
OQ.LABEL_CHALLENGES   = "challenges" ;
OQ.LABEL_BG           = "battleground" ;
OQ.LABEL_RBG          = "rated bg" ;
OQ.LABEL_ARENAS       = "arenas" ;
OQ.LABEL_ARENA        = "arena" ;
OQ.LABEL_DUNGEON      = "dungeon" ;
OQ.LABEL_LADDER       = "ladder" ;
OQ.LABEL_RAID         = "raid" ;
OQ.LABEL_SCENARIO     = "scenario" ;
OQ.LABEL_CHALLENGE    = "challenge" ;
OQ.PATTERN_CAPS       = "[ABCDEFGHIJKLMNOPQRSTUVWXYZ]" ;
OQ.CONTRIBUTE         = "send beer!" ;
OQ.MATCHUP            = "match up" ;
OQ.NODIPFORYOU        = "You have more then %d bnet friends.  no dip for you." ;
OQ.GAINED             = "gained" ;
OQ.LOST               = "lost" ;
OQ.PERHOUR            = "per hour" ;
OQ.NOW                = "now" ;
OQ.WITH               = "with" ;
OQ.RAID_TOES          = "terrace of endless spring" ;
OQ.RAID_HOF           = "heart of fear" ;
OQ.RAID_MV            = "mogushan vaults" ;
OQ.RAID_TOT           = "throne of thunder" ;
OQ.RAID_RA_DEN        = "Ra-den" ;
OQ.RBG_HRANK_1        = "Scout" ;
OQ.RBG_HRANK_2        = "Grunt" ;
OQ.RBG_HRANK_3        = "Sergeant" ;
OQ.RBG_HRANK_4        = "Senior Sergeant" ;
OQ.RBG_HRANK_5        = "First Sergeant" ;
OQ.RBG_HRANK_6        = "Stone Guard" ;
OQ.RBG_HRANK_7        = "Blood Guard" ;
OQ.RBG_HRANK_8        = "Legionnaire" ;
OQ.RBG_HRANK_9        = "Centurion" ;
OQ.RBG_HRANK_10       = "Champion" ;
OQ.RBG_HRANK_11       = "Lieutenant General" ;
OQ.RBG_HRANK_12       = "General" ;
OQ.RBG_HRANK_13       = "Warlord" ;
OQ.RBG_HRANK_14       = "High Warlord" ;
OQ.RBG_ARANK_1        = "Private" ;
OQ.RBG_ARANK_2        = "Corporal" ;
OQ.RBG_ARANK_3        = "Sergeant" ;
OQ.RBG_ARANK_4        = "Master Sergeant" ;
OQ.RBG_ARANK_5        = "Sergeant Major" ;
OQ.RBG_ARANK_6        = "Knight" ;
OQ.RBG_ARANK_7        = "Knight-Lieutenant" ;
OQ.RBG_ARANK_8        = "Knight-Captain" ;
OQ.RBG_ARANK_9        = "Knight-Champion" ;
OQ.RBG_ARANK_10       = "Lieutenant Commander" ;
OQ.RBG_ARANK_11       = "Commander" ;
OQ.RBG_ARANK_12       = "Marshal" ;
OQ.RBG_ARANK_13       = "Field Marshal" ;
OQ.RBG_ARANK_14       = "Grand Marshal" ;
OQ.TITLES             = "titles" ;
OQ.CONQUEROR          = "conqueror" ;
OQ.BLOODTHIRSTY       = "bloodthirsty" ;
OQ.BATTLEMASTER       = "battlemaster" ;
OQ.HERO               = "hero" ;
OQ.WARBRINGER         = "warbringer" ;
OQ.KHAN               = "khan" ;
OQ.RANAWAY            = "deserter.  loss registered"
OQ.TT_KARMA           = "karma"  ;
OQ.UP                 = "up" ;
OQ.DOWN               = "down" ;
OQ.BAD_KARMA_BTAG     = "OQ: selected group member's battle-tag is invalid" ;
OQ.MAX_KARMA_TODAY    = "OQ: %s has already received karma from you today" ;
OQ.YOUVE_GOT_KARMA    = "you've gained %d karma point." ;
OQ.YOUVE_LOST_KARMA   = "you've lost %d karma point." ;
OQ.YOUVE_LOST_KARMAS  = "you've lost %d karma points." ;
OQ.INSTANCE_LASTED    = "instance lasted" ;
OQ.SHOW_ILEVEL        = "show ilevel" ;
OQ.SOCKET             = " Socket" ;
OQ.SHA_TOUCHED        = "Sha--Touched" 
OQ.TT_BATTLE_TAG      = "battle-tag" ;
OQ.TT_REGULAR_BG      = "regular bgs" ;
OQ.TT_PERSONAL        = "as member" ;
OQ.TT_ASLEAD          = "as lead" ;
OQ.AVG_ILEVEL         = "avg ilevel: %d" ;
OQ.ENCHANTED          = "Enchanted:" ;
OQ.ENABLE_FOG         = "fog of war" ;
OQ.AUTO_INSPECT       = "Auto inspect (ctrl left-click)" ;
OQ.TIMELEFT           = "Time left:" ;
OQ.HORDE              = "Horde" ;
OQ.ALLIANCE           = "Alliance" ;
OQ.SETUP_TIMERWIDTH   = "Timer width" ;
OQ.BG_BEGINS          = " begin!" -- partial text of start msg
OQ.BG_BEGUN           = " begun!" -- partial text of start msg
OQ.SETUP_SHOW_CONTROLLED   = "Show controlled nodes" ;
OQ.MM_OPTION1         = "toggle main UI" ;
OQ.MM_OPTION2         = "toggle marquee" ;
OQ.MM_OPTION3         = "toggle timers" ;
OQ.MM_OPTION4         = "toggle threat UI" ;
OQ.MM_OPTION5         = "clear timers" ;
OQ.MM_OPTION6         = "show mesh time" ;
OQ.MM_OPTION7         = "fix UI" ;
OQ.MM_OPTION8         = "where am i?" ;
OQ.MM_OPTION9         = "go dark" ;
OQ.LABEL_QUESTING     = "questing" ;
OQ.LABEL_QUESTERS     = "quest groups" ;
OQ.ACTIVE_LASTPERIOD  = "# active last 7days" ;
OQ.SCORE_NLEADERS     = "# leaders" ;
OQ.SCORE_NGAMES       = "# games" ;
OQ.SCORE_NBOSSES      = "# bosses" ;
OQ.TT_PVERECORD       = "record (bosses - wipes)" ;
OQ.TT_5MANS           = "leader: 5 mans" ;
OQ.TT_RAIDS           = "leader: raids" ;
OQ.TT_CHALLENGES      = "leader: challenge runs" ;
OQ.TT_LEADER_DKP      = "leader: dragon kill pts" ;
OQ.TT_DKP             = "dragon kill pts" ;
OQ.SCORE_DKP          = "# dragon kill pts" ;
OQ.ERR_NODURATION     = "Unknown instance duration.  Unable to calculate currency changes" ;
OQ.DRUNK              = "..hic!" ;
OQ.MM_OPTION2a        = "toggle bounty board" ;
OQ.ANNOUNCE_CONTRACTS = "Announce contracts" ;
OQ.SETUP_SHOUTCONTRACTS = "Announce contracts" ;
OQ.CONTRACT_ARRIVED   = " Contract #%s just arrived!  Target: %s  Reward: |h%s" ;
OQ.CONTRACT_CLAIMED01 = "%s %s claimed contract #%s and won %s" ;
OQ.CONTRACT_CLAIMED02 = "%s claimed contract #%s and won %s" ;
OQ.TARGET_MARK        = "You've targeted a bounty target! ( contract#%s )" ;
OQ.BOUNTY_TARGET      = "You've killed a bounty target! ( contract#%s )" ;
OQ.DEATHMATCH_SCORE   = "Score!" ;
OQ.FRIEND_REQUEST     = "%s-%s wants to be your friend" ;
OQ.ALREADY_FRIENDED   = "you're already battle-net friends with %s" ;
OQ.TT_FRIEND_REQUEST  = "friend request" ;
OQ.DEATHMATCH_BEGINS  = "WPvP Death Match has begun!  Get to the spine in Pandaria and defend your pvp vendors!" ;
OQ.WONTHEMATCH        = "won the match!" ;
OQ.MSG_MISSINGTYPE    = "Please select premade type" ;

OQ.CONTRIBUTION_DLG = { "",
                        "Having fun with oQueue and public vent?",
                        "Then send us a beer!",
                        "",
                        "for tiny and oQueue:",
                        "beg.oq",
                        "",
                        "for Rathamus and public vent:",
                        "beg.vent",
                        "",
                        "Thanks!",
                        "",
                        "- tiny",
                      } ;
OQ.TIMEVARIANCE_DLG = { "",
                        "Warning:",
                        "",
                        "  Your system time is significantly ",
                        "  different from the mesh.  You must",
                        "  correct it before being allowed to",
                        "  create a premade.",
                        "",
                        "  time variance:  %s",
                        "",
                        "- tiny",
                      } ;
OQ.LFGNOTICE_DLG = { "",
                        "Warning:",
                        "",
                        "  Do not use oQueue premade names for",
                        "  LFG or other types of personal",
                        "  advertisement.  Many people will ban ",
                        "  anyone using it as such.  If you get",
                        "  banned, you won't be able to join",
                        "  their groups.",
                        "",
                        "- tiny",
                      } ;


OQ.BG_NAMES     = { [ "Random Battleground"    ] = { type_id = OQ.RND  },
                    [ "Warsong Gulch"          ] = { type_id = OQ.WSG  },
                    [ "Twin Peaks"             ] = { type_id = OQ.TP   },
                    [ "The Battle for Gilneas" ] = { type_id = OQ.BFG  },
                    [ "Arathi Basin"           ] = { type_id = OQ.AB   },
                    [ "Eye of the Storm"       ] = { type_id = OQ.EOTS },
                    [ "Strand of the Ancients" ] = { type_id = OQ.SOTA },
                    [ "Isle of Conquest"       ] = { type_id = OQ.IOC  },
                    [ "Alterac Valley"         ] = { type_id = OQ.AV   },
                    [ "Silvershard Mines"      ] = { type_id = OQ.SSM  },
                    [ "Temple of Kotmogu"      ] = { type_id = OQ.TOK  },
                    [ "Deepwind Gorge"         ] = { type_id = OQ.DWG  },
                    [ "Dragon Kill Points"     ] = { type_id = OQ.DKP  },
                    [ ""                       ] = { type_id = OQ.NONE },
                  } ;
                  
OQ.BG_SHORT_NAME = { [ "Arathi Basin"           ] = "AB",
                     [ "Alterac Valley"         ] = "AV",
                     [ "The Battle for Gilneas" ] = "BFG",
                     [ "Eye of the Storm"       ] = "EotS",
                     [ "Isle of Conquest"       ] = "IoC",
                     [ "Strand of the Ancients" ] = "SotA",
                     [ "Wildhammer Stronghold"  ] = "TP",
                     [ "Dragonmaw Stronghold"   ] = "TP",
                     [ "Twin Peaks"             ] = "TP",
                     [ "Silverwing Hold"        ] = "WSG",
                     [ "Warsong Gulch"          ] = "WSG",
                     [ "Warsong Lumber Mill"    ] = "WSG",
                     [ "Silvershard Mines"      ] = "SSM",
                     [ "Temple of Kotmogu"      ] = "ToK",
                     [ "Deepwind Gorge"         ] = "DWG",
                     
                     [ OQ.AB                    ] = "AB",
                     [ OQ.AV                    ] = "AV",
                     [ OQ.BFG                   ] = "BFG",
                     [ OQ.EOTS                  ] = "EotS",
                     [ OQ.IOC                   ] = "IoC",
                     [ OQ.SOTA                  ] = "SotA",
                     [ OQ.TP                    ] = "TP",
                     [ OQ.WSG                   ] = "WSG",
                     [ OQ.SSM                   ] = "SSM",
                     [ OQ.TOK                   ] = "ToK",
                     [ OQ.DWG                   ] = "DWG",
                     
                     [ "AB"                     ] = OQ.AB,
                     [ "AV"                     ] = OQ.AV,
                     [ "BFG"                    ] = OQ.BFG,
                     [ "EotS"                   ] = OQ.EOTS,
                     [ "IoC"                    ] = OQ.IOC,
                     [ "SotA"                   ] = OQ.SOTA,
                     [ "TP"                     ] = OQ.TP,
                     [ "WSG"                    ] = OQ.WSG,
                     [ "SSM"                    ] = OQ.SSM,
                     [ "ToK"                    ] = OQ.TOK,
                     [ "DWG"                    ] = OQ.DWG,
                   } ;
                   
OQ.BG_STAT_COLUMN = { [ "Bases Assaulted"       ] = "Base Assaulted",
                      [ "Bases Defended"        ] = "Base Defended",
                      [ "Demolishers Destroyed" ] = "Demolisher Destroyed",
                      [ "Flag Captures"         ] = "Flag Captured",
                      [ "Flag Returns"          ] = "Flag Returned",
                      [ "Gates Destroyed"       ] = "Gate Destroyed",
                      [ "Graveyards Assaulted"  ] = "Graveyard Assaulted",
                      [ "Graveyards Defended"   ] = "Graveyard Defended",
                      [ "Towers Assaulted"      ] = "Tower Assaulted",
                      [ "Towers Defended"       ] = "Tower Defended",
                    } ;

OQ.COLORBLINDSHADER = { [ 0 ] = "disabled",
                        [ 1 ] = "Protanopia",
                        [ 2 ] = "Protanomaly",
                        [ 3 ] = "Deuteranopia",
                        [ 4 ] = "Deuteranomaly",
                        [ 5 ] = "Tritanopia",
                        [ 6 ] = "Tritanomaly",
                        [ 7 ] = "Achromatopsia",
                        [ 8 ] = "Achromatomaly",
                      } ;

OQ.TRANSLATED_BY = {} ;

-- Class talent specs
local DK    = { ["Blood"]          = "Tank",
                ["Frost"]          = "Melee",
                ["Unholy"]         = "Melee",
              } ;
local DRUID = { ["Balance"]        = "Knockback",
                ["Feral Combat"]   = "Melee",
                ["Restoration"]    = "Healer",
                ["Guardian"]       = "Tank",
              } ;
local HUNTER = { ["Beast Mastery"] = "Knockback",
                 ["Marksmanship"]  = "Ranged",
                 ["Survival"]      = "Ranged",
               } ;
local MAGE = {  ["Arcane"]         = "Knockback",
                ["Fire"]           = "Ranged",
                ["Frost"]          = "Ranged",
             } ; 
local MONK = {  ["Brewmaster"]     = "Tank",
                ["Mistweaver"]     = "Healer",
                ["Windwalker"]     = "Melee",
             } ; 
local PALADIN = { ["Holy"]         = "Healer",
                  ["Protection"]   = "Tank",
                  ["Retribution"]  = "Melee",
                } ; 
local PRIEST = { ["Discipline"]    = "Healer",
                 ["Holy"]          = "Healer",
                 ["Shadow"]        = "Ranged",
               } ; 
local ROGUE = { ["Assassination"]  = "Melee",
                ["Combat"]         = "Melee",
                ["Subtlety"]       = "Melee",
              } ; 
local SHAMAN = { ["Elemental"]     = "Knockback",
                 ["Enhancement"]   = "Melee",
                 ["Restoration"]   = "Healer",
               } ; 
local WARLOCK = { ["Affliction"]   = "Knockback",
                  ["Demonology"]   = "Knockback",
                  ["Destruction"]  = "Knockback",
                } ; 
local WARRIOR = { ["Arms"]         = "Melee",
                  ["Fury"]         = "Melee",
                  ["Protection"]   = "Tank",
                } ; 

OQ.BG_ROLES = {} ;
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

-- some bosses do not 'die'... their defeat must be detected by watching their yell emotes
-- this table maps a defeat emote to the boss-id (it'd be better if it was mapped to the name, but names aren't necessarily localized)
--
OQ.DEFEAT_EMOTES = {} ;
OQ.DEFEAT_EMOTES["The Sha of Hatred has fled my body... and the monastery, as well. I must thank you, strangers. The Shado-Pan are in your debt. Now, there is much work to be done..."] = 56884 ; -- Taran Zhu
OQ.DEFEAT_EMOTES["I am bested. Give me a moment and we will venture together to face the Sha."] = 60007 ; -- Master Snowdrift
OQ.DEFEAT_EMOTES["Even together... we failed..."] = 56747 ; -- Gu Cloudstrike
OQ.DEFEAT_EMOTES["Impossible! Our might is the greatest in all the empire!"] = 61445 ; -- Haiyan the Unstoppable, Trial of the King
OQ.DEFEAT_EMOTES["The haze has been lifted from my eyes... forgive me for doubting you..."] = 56732 ; -- Liu Flameheart


-- contract toon names; to translate, replace 'nil' with the translation
--
L["Doom Lord Kazzak"        ] = nil ;
L["Hogger"                  ] = nil ; 
L["Lord Overheat"           ] = nil ;
L["Randolph Moloch"         ] = nil ;
L["Adarogg"                 ] = nil ;
L["Slagmaw"                 ] = nil ;
L["Lava Guard Gordoth"      ] = nil ;
L["Newton Burnside"         ] = nil ;
L["Auctioneer Chilton"      ] = nil ;
L["Alchemist Mallory"       ] = nil ; 
L["Toddrick"                ] = nil ;  
L["Remen Marcot"            ] = nil ;
L["Goldtooth"               ] = nil ; 
L["Auctioneer Fazdran"      ] = nil ; 
L["Kixa"                    ] = nil ; 
L["Gor the Enforcer"        ] = nil ; 
L["Tarshaw Jaggedscar"      ] = nil ;
L["Rokar Bladeshadow"       ] = nil ; 
L["Kor'kron Spotter"        ] = nil ; 
L["Falstad Wildhammer"      ] = nil ;
L["Baine Bloodhoof"         ] = nil ; 
L["Fel Reaver"              ] = nil ; 
L["Brewmaster Roland"       ] = nil ; 
L["Reeler Uko"              ] = nil ; 
L["Sulik'shor"              ] = nil ; 
L["Qu'nas"                  ] = nil ; 
L["Nal'lak the Ripper"      ] = nil ;
L["Muerta"                  ] = nil ; 
L["Disha Fearwarden"        ] = nil ; 
L["Bonestripper Buzzard"    ] = nil ; 
L["Fulgorge"                ] = nil ; 
L["Sahn Tidehunter"         ] = nil ; 
L["Moldo One-Eye"           ] = nil ; 
L["Omnis Grinlok"           ] = nil ; 
L["Armsmaster Holinka"      ] = nil ; 
L["Roo Desvin"              ] = nil ; 
L["Hiren Loresong"          ] = nil ;
L["Vasarin Redmorn"         ] = nil ;
L["Grumbol Grimhammer"      ] = nil ;
L["Usha Eyegouge"           ] = nil ;
L["Bartlett the Brave"      ] = nil ; 
L["Anette Williams"         ] = nil ; 
L["Auctioneer Vizput"       ] = nil ; 
L["Lady Sylvanas Windrunner"] = nil ;
L["Devrak"                  ] = nil ; 
L["Felicia Maline"          ] = nil ; 
L["Radulf Leder"            ] = nil ; 
L["The Black Bride"         ] = nil ; 
L["Shan'ze Battlemaster"    ] = nil ; 
L["Holgar Stormaxe"         ] = nil ; 
L["Ruskan Goreblade"        ] = nil ; 
L["Maginor Dumas"           ] = nil ; 
L["High Sorcerer Andromath" ] = nil ;
L["Captain Dirgehammer"     ] = nil ; 
L["Keryn Sylvius"           ] = nil ; 
L["Bizmo's Brawlpub Bouncer"] = nil ; 
L["Myolor Sunderfury"       ] = nil ; 
L["Golnir Bouldertoe"       ] = nil ; 
L["Auctioneer Lympkin"      ] = nil ; 
L["Jarven Thunderbrew"      ] = nil ; 
L["Mistblade Scale-Lord"    ] = nil ; 
L["Major Nanners"           ] = nil ; 
L["Doris Chiltonius"        ] = nil ; 
L["Lucan Malory"            ] = nil ; 
L["Acon Deathwielder"       ] = nil ; 
L["Ethan Natice"            ] = nil ; 
L["Kri'chon"                ] = nil ; 
L["Warlord Bloodhilt"       ] = nil ; 
L["High Marshal Twinbraid"  ] = nil ;

-- 
L[" Battle.net is currently down."] = nil ;
L[" oQueue will not function properly until Battle.net is restored."] = nil ;
L[" Please set your battle-tag before using oQueue."] = nil ;
L[" Your battle-tag can only be set via your WoW account page."] = nil ;
L["NOTICE:  You've exceeded the cap before the cap(%s).  removed: %s"] = nil ;
L["WARNING:  Your battle.net friends list has %s friends."] = nil ;
L["WARNING:  You've exceeded the cap before the cap(%s)"] = nil ;
L["WARNING:  No mesh nodes available for removal.  Please trim your b.net friends list"] = nil ;
L["Found oQ banned b.tag on your friends list.  removing: %s"] = nil ;

