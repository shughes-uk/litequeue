--[[ 
  @file       oqueue_tooltips.lua
  @brief      tooltips 

  @author     rmcinnis
  @date       april 06, 2012
  @copyright  Solid ICE Technologies
              this file may be distributed so long as it remains unaltered
              if this file is posted to a web site, credit must be given to me along with a link to my web page
              no code in this file may be used in other works without expressed permission  
]]--
local addonName, OQ = ... ;
local oq = OQ:mod() ; -- thank goodness i stumbled across this trick
local _ ; -- throw away (was getting taint warning; what happened blizz?)

OQ.EMPTY_SQUARE = "Interface\\Addons\\oqueue\\art\\square_middle.tga" ;

local function comma_value(n) -- credit http://richard.warburton.it
  if (n == nil) then
    n = 0 ;
  end
  local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
  return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

--------------------------------------------------------------------------
-- main premade hover over tooltip functions
--------------------------------------------------------------------------
function oq.tooltip_label( tt, x, y, align )
  local t = tt:CreateFontString() ;
  t:SetFontObject(GameFontNormal)
  t:SetWidth( tt:GetWidth()- (x + 2*15) ) ;
  t:SetHeight( 15 ) ;
  t:SetJustifyV( "MIDDLE" ) ;
  t:SetJustifyH( align ) ;
  t:SetText( "" ) ;
  t:Show() ;
  t:SetPoint("TOPLEFT", tt,"TOPLEFT", x, -1 * y ) ;
  return t ;
end

function oq.tooltip_create() 
  if (oq.tooltip ~= nil) then
    return oq.tooltip ;
  end
  local tooltip = oq.CreateFrame("FRAME", "OQTooltip", UIParent, nil ) ;
  tooltip:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background", 
                       edgeFile="Interface/Tooltips/UI-Tooltip-Border", 
                       tile=true, tileSize = 16, edgeSize = 16,
                       insets = { left = 4, right = 3, top = 4, bottom = 3 }
                      })

  tooltip:SetBackdropColor(0.0,0.0,0.0,1.0);
  tooltip.emphasis_texture = tooltip:CreateTexture( nil, "ARTWORK" ) ;
  tooltip.emphasis_texture:SetTexture( "" ) ;
  tooltip.emphasis_texture:SetPoint( "TOPLEFT"    , tooltip, "TOPLEFT"    ,  10, -10 ) ;
  tooltip.emphasis_texture:SetPoint( "BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -10,  10 ) ;

  tooltip.splat = tooltip:CreateTexture( nil, "BORDER" ) ;
  tooltip.splat:SetTexture( "" ) ;
  tooltip.splat:SetPoint( "TOPLEFT"    , tooltip, "TOPLEFT"    ,  2, -2 ) ;
  tooltip.splat:SetPoint( "BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -2,  2 ) ;

  -- class portrait
  local f = oq.CreateFrame("FRAME", "OQTooltipPortraitFrame", tooltip ) ;
  f:SetWidth(35) ;
  f:SetHeight(35) ;
  f:SetBackdropColor(0.0,0.8,0.8,1.0) ;

  local t = tooltip:CreateTexture( nil, "OVERLAY" ) ;
  t:SetTexture( "Interface\\TargetingFrame\\UI-Classes-Circles" ) ;
  t:SetAllPoints( f ) ;
  t:SetAlpha( 1.0 ) ;
  f.texture = t ;

  f:SetPoint( "TOPRIGHT", -6, -1 * 6 ) ;
  f:Show() ;
  tooltip.portrait = f ;

  local x = 5 ;
  local y = 8 ;
  local cy = 17 ;
  tooltip.nRows = 16 ;
--  tooltip:SetWidth ( 210 ) ;
  tooltip:SetHeight( (tooltip.nRows+1)*(cy)+8 ) ;
--  pm_tooltip:SetHeight( 12 + pm_tooltip.nRows*16 ) ;
--  tooltip:SetHeight( (tooltip.nRows+1)*(15+3)+8 ) ;
  tooltip:SetWidth ( 210 ) ; -- 240

  tooltip.left  = {} ;
  tooltip.right = {} ;

  for i = 1, tooltip.nRows do
    if (i == (tooltip.nRows-1)) or (i == (tooltip.nRows)) then
      tooltip.left [i] = oq.tooltip_label( tooltip, x, y, "LEFT"  ) ;
      tooltip.left [i]:SetWidth( tooltip:GetWidth()- 3 ) ;
    else
      tooltip.left [i] = oq.tooltip_label( tooltip, x, y, "LEFT"  ) ;
    end
    if (i == 2) then
      tooltip.right[i] = oq.tooltip_label( tooltip, x, y, "RIGHT" ) ;
      tooltip.right[i]:SetWidth( tooltip:GetWidth()- (x + 3*15) ) ;
    else
      tooltip.right[i] = oq.tooltip_label( tooltip, x, y, "RIGHT" ) ;
    end
    if (i == 1) then
      x = x + 10 ;
      y = y + 2 ;
      tooltip.left [i]:SetFont(OQ.FONT, 12, "") ;
      tooltip.right[i]:SetFont(OQ.FONT, 12, "") ;
    else
      tooltip.left [i]:SetTextColor( 0.6, 0.6, 0.6 ) ;
      tooltip.left [i]:SetFont(OQ.FONT, 10, "") ;

      tooltip.right[i]:SetTextColor( 0.9, 0.9, 0.25 ) ;
      tooltip.right[i]:SetFont(OQ.FONT, 10, "") ;
    end
    y = y + cy ;
    if (i == (tooltip.nRows - 1)) or (i == (tooltip.nRows - 2)) then
      y = y + 5 ; -- spacer before last row
    end
  end
  oq.tooltip = tooltip ;
  return tooltip ;
end

function oq.tooltip_clear()
  local tooltip = oq.tooltip ;
  if (tooltip ~= nil) then
    for i = 1,tooltip.nRows do
      tooltip.left [i]:SetText( "" ) ;
      tooltip.right[i]:SetText( "" ) ;
    end
  end
end

function oq.make_achieve_icon( id )
  if (id == 0) then
    return "|T".. OQ.EMPTY_SQUARE ..":24:24:0:0|t" ;
--    return "|T".. OQ.EMPTY_GEMSLOTS["Blue"] ..":24:24:0:0|t" ;
  end
  return "|T".. select( 10, GetAchievementInfo( id )) ..".blp:24:24:0:0|t";
end

function oq.make_achieve_icon_if( id, b, mask )
  if (id == 0) or (oq.is_set( b, mask ) == nil) then
    return "|T".. OQ.EMPTY_SQUARE ..":24:24:0:0|t" ;
--    return "|T".. OQ.EMPTY_GEMSLOTS["Blue"] ..":24:24:0:0|t" ;
  end
  return "|T".. select( 10, GetAchievementInfo( id )) ..".blp:24:24:0:0|t";
end

function oq.get_rank_achieves( s )
  if (s == nil) then
    return "" ;
  end
  local rank_id = oq.decode_mime64_digits( s:sub(1,1) ) ;
  local t1 = oq.decode_mime64_digits( s:sub(2,2) ) ;
  local t2 = oq.decode_mime64_digits( s:sub(3,3) ) ;
  local t3 = oq.decode_mime64_digits( s:sub(4,4) ) ;
  local str = "" ;
  if (oq.player_faction == "H") then
    str = str .."".. oq.make_achieve_icon_if( 1175, t2, 0x01 ) ; -- battlemaster
    str = str .."".. oq.make_achieve_icon_if( 8055, t2, 0x20 ) ; -- khan
    str = str .."".. oq.make_achieve_icon_if(  714, t2, 0x02 ) ; -- conqueror
    str = str .."".. oq.make_achieve_icon_if( 5363, t2, 0x04 ) ; -- bloodthirsty
    str = str .."".. oq.make_achieve_icon_if( 5326, t1, 0x02 ) ; -- warbringer
    str = str .."".. oq.make_achieve_icon_if( 6941, t1, 0x01 ) ; -- hero of the horde
  else
    str = str .."".. oq.make_achieve_icon_if(  230, t2, 0x01 ) ; -- battlemaster
    str = str .."".. oq.make_achieve_icon_if( 8052, t2, 0x20 ) ; -- khan
    str = str .."".. oq.make_achieve_icon_if(  907, t2, 0x02 ) ; -- conq
    str = str .."".. oq.make_achieve_icon_if( 5363, t2, 0x04 ) ; -- bloodthirsty
    str = str .."".. oq.make_achieve_icon_if( 5329, t1, 0x02 ) ; -- warbound
    str = str .."".. oq.make_achieve_icon_if( 6942, t1, 0x01 ) ; -- hero of the alliance
  end
  -- arena (seems to be the same for both)
  if (oq.is_set( t3, 0x02 ) ~= nil) then      -- gladiator
    str = str .."".. oq.make_achieve_icon( 2091 ) ;
  elseif (oq.is_set( t3, 0x04 ) ~= nil) then  -- duelist
    str = str .."".. oq.make_achieve_icon( 2092 ) ;
  elseif (oq.is_set( t3, 0x08 ) ~= nil) then      -- rival
    str = str .."".. oq.make_achieve_icon( 2093 ) ;
  else
    str = str .."".. "|T".. OQ.EMPTY_SQUARE ..":24:24:0:0|t" ;
--    str = str .."".. "|T".. OQ.EMPTY_GEMSLOTS["Blue"] ..":24:24:0:0|t" ;
  end
  str = str .."".. oq.make_achieve_icon_if( 1174, t3, 0x01 ) ;  -- arena master
  
  return str ;
end

function oq.get_rank_icons( s )
  if (s == nil) then
    return "" ;
  end
  local rank_id = oq.decode_mime64_digits( s:sub(1,1) ) ;
  if (OQ.rbg_rank[ rank_id ] == nil) or (OQ.rbg_rank[ rank_id ].id == 0) then
    return "" ;
  end
  return oq.make_achieve_icon( OQ.rbg_rank[ rank_id ].id ) ;
end

OQ.GOLD_MEDAL   = "|TInterface\\Challenges\\ChallengeMode_Medal_Gold.blp:24:24:0:0|t" ;
OQ.SILVER_MEDAL = "|TInterface\\Challenges\\ChallengeMode_Medal_Silver.blp:24:24:0:0|t" ;
OQ.SILVER_MEDAL = "|TInterface\\Challenges\\ChallengeMode_Medal_Silver.blp:24:24:0:0|t" ;
OQ.BRONZE_MEDAL = "|TInterface\\Challenges\\ChallengeMode_Medal_Bronze.blp:24:24:0:0|t" ;

function oq.get_medal( medal, s )
  if (s == nil) then
    return "" ;
  end
  local str = "" ;
  s = "FF" ;
  if (medal == "gold") then
    return oq.decode_mime64_digits( s ) .." ".. OQ.GOLD_MEDAL ; 
  elseif (medal == "silver") then
    return oq.decode_mime64_digits( s ) .." ".. OQ.SILVER_MEDAL ;
  elseif (medal == "bronze") then
    return oq.decode_mime64_digits( s ) .." ".. OQ.BRONZE_MEDAL ;
  end
  return "" ;
end

function oq.get_medals( s )
  if (s == nil) then
    return "" ;
  end
  local str = "" ;
  
  str = str .."".. oq.get_medal( "gold"  , s:sub(5,6) ) .." " ; 
  str = str .."".. oq.get_medal( "silver", s:sub(3,4) ) .." " ; 
  str = str .."".. oq.get_medal( "bronze", s:sub(1,2) ) .." " ; 
  return str ;
end

function oq.karma_color( karma ) 
  local clr = "|cFF000000" ;
  if (karma > 15) then
    clr = "|cFF14D847" ;  -- 16..25; good, green
  elseif (karma >   5) then
    clr = "|cFF49CF69" ;  -- 6..15; good-ish, green
  elseif (karma >  -5) then
    clr = "|cFFC0C0C0" ;  -- -4..-5; nuetral, grey
  elseif (karma > -15) then
    clr = "|cFF9D2D2D" ;  -- -5..-15; bad, red
  else
    clr = "|cFFD81914" ;  -- -16..-25; bad, red
  end
  return clr ;
end

function oq.tooltip_set2( f, m, totheside, is_lead )
  if (m == nil) then
    return ;
  end
  local tooltip = oq.tooltip_create() ;
  tooltip:ClearAllPoints() ;
  local nRows = 14 ;
  totheside = true ;
  if (totheside) then
--    local p = f:GetParent():GetParent():GetParent() ;
    tooltip:SetParent( OQMainFrame, "ANCHOR_RIGHT" ) ;
    tooltip:SetPoint("TOPLEFT", OQMainFrame, "TOPRIGHT", 10, 0 ) ;
    tooltip:SetFrameLevel( OQMainFrame:GetFrameLevel() + 10 ) ;
  else
    tooltip:SetParent( f, "ANCHOR_RIGHT" ) ;
    tooltip:SetPoint("TOPLEFT", tooltip:GetParent(), "TOPRIGHT", 10, 0 ) ;
    tooltip:SetFrameLevel( f:GetFrameLevel() + 10 ) ;
  end
  oq.tooltip_clear() ;

  if (OQ.CLASS_COLORS[m.class] == nil) then
    return ;
  end


  tooltip.left [ 1]:SetText( m.name .." (".. tostring(m.level or 0) ..")" ) ;
  tooltip.left [ 1]:SetTextColor( OQ.CLASS_COLORS[m.class].r, OQ.CLASS_COLORS[m.class].g, OQ.CLASS_COLORS[m.class].b, 1 ) ;
  tooltip.left [ 2]:SetText( m.realm ) ;
  tooltip.left [ 2]:SetTextColor( 0.0, 0.9, 0.9, 1 ) ;
  
  tooltip.right[ 2]:SetText( oq.get_rank_icons( m.ranks ) ) ;

  tooltip.left [ 3]:SetText( m.bgroup ) ;
  tooltip.left [ 3]:SetTextColor( 0.8, 0.8, 0.8, 1 ) ;

  tooltip.left [ 4]:SetText( OQ.TT_KARMA ) ;

  if (m.karma ~= nil) and (m.karma ~= 0) then
    tooltip.right[ 4]:SetText( oq.karma_color( m.karma ) .."".. tostring(m.karma) .."|r" ) ;
  else
    tooltip.right[ 4]:SetText( "--" ) ;
  end

  tooltip.left [ 5]:SetText( OQ.TT_ILEVEL ) ;
  tooltip.right[ 5]:SetText( m.ilevel ) ;
  if oq.is_dungeon_premade( m ) or (m.premade_type == OQ.TYPE_RAID) then
    tooltip.left [ 6]:SetText( OQ.TT_DKP ) ;
    if (m.premade_type == OQ.TYPE_CHALLENGE) then
      tooltip.right[ 6]:SetText( comma_value(oq.decode_mime64_digits( m.raids:sub(-3,-1)) )) ; -- member dkp is the last 3 digits
    elseif (m.premade_type == OQ.TYPE_SCENARIO) then
      tooltip.right[ 6]:SetText( comma_value(oq.decode_mime64_digits( m.raids:sub(-3,-1)) )) ; -- member dkp is the last 3 digits
    else
      tooltip.right[ 6]:SetText( comma_value(oq.decode_mime64_digits( m.raids:sub(20,22)) )) ;
    end

    if     (m.spec_type == OQ.TANK  ) then
      tooltip.left [ 8]:SetText( "dodge" ) ;
      tooltip.right[ 8]:SetText( string.format( "%.2f%%", m.dodge )) ;
      tooltip.left [ 9]:SetText( "parry" ) ;
      tooltip.right[ 9]:SetText( string.format( "%.2f%%", m.parry )) ;
      tooltip.left [10]:SetText( "block" ) ;
      tooltip.right[10]:SetText( string.format( "%.2f%%", m.block )) ;
      tooltip.left [11]:SetText( "mastery" ) ;
      tooltip.right[11]:SetText( string.format( "%.2f%%", m.mastery or 0 )) ;
    else
      tooltip.left [ 8]:SetText( "power" ) ;
      tooltip.right[ 8]:SetText( comma_value(tostring( m.power or 0 ))) ;
      tooltip.left [ 9]:SetText( "hit" ) ;
      tooltip.right[ 9]:SetText( string.format( "%.2f%%", m.hit or 0 )) ;
      tooltip.left [10]:SetText( "crit" ) ;
      tooltip.right[10]:SetText( string.format( "%.2f%%", m.crit or 0 )) ;
      tooltip.left [11]:SetText( "mastery" ) ;
      tooltip.right[11]:SetText( string.format( "%.2f%%", m.mastery or 0 )) ;
      tooltip.left [12]:SetText( "haste" ) ;
      tooltip.right[12]:SetText( string.format( "%.2f%%", m.haste or 0 )) ;
    end
    if (m.premade_type == OQ.TYPE_CHALLENGE) then
      tooltip.left [14]:SetText( "medals" ) ;
      local str = "" ;
      local n = oq.decode_mime64_digits( m.raids:sub(1,2) ) ;
      if (n > 0) then
        str = str .."  ".. tostring(n) .."x ".. OQ.BRONZE_MEDAL ;
      end
      n = oq.decode_mime64_digits( m.raids:sub(3,4) ) ;
      if (n > 0) then
        str = str .."  ".. tostring(n) .."x ".. OQ.SILVER_MEDAL ;
      end
      n = oq.decode_mime64_digits( m.raids:sub(5,6) ) ;
      if (n > 0) then
        str = str .."".. tostring(n) .."x ".. OQ.GOLD_MEDAL ;
      end
      if (str == "") then
        str = "--" ;
      end
      tooltip.right[14]:SetText( str ) ;

    end
    tooltip.left [16]:SetText( OQ.TT_OQVERSION ) ;
    tooltip.right[16]:SetText( oq.get_version_str( m.oq_ver ) ) ;
  else
    tooltip.left [ 6]:SetText( OQ.TT_RESIL ) ;
    tooltip.right[ 6]:SetText( m.resil ) ;
    tooltip.left [ 7]:SetText( OQ.TT_PVPPOWER ) ;
    tooltip.right[ 7]:SetText( comma_value(m.pvppower) ) ;
    tooltip.left [ 8]:SetText( OQ.TT_MMR ) ;
    
--    local ratings = "|cFFF08040".. tostring(m.arena2s or 0) .."|r "..
--                    "|cFFF0F0A0".. tostring(m.arena3s or 0) .."|r "..
--                    "|cFFF08040".. tostring(m.arena5s or 0) .."|r "..
--                    "|cFFF0F0A0".. tostring(m.mmr) .."|r" ;
    local ratings = "|cFFF0F0A0".. tostring(m.mmr) .."|r" ;
    tooltip.right[ 8]:SetText( ratings ) ;
    
    tooltip.left [ 9]:SetText( OQ.TT_MAXHP ) ;
    tooltip.right[ 9]:SetText( tostring(m.hp or 0) .." k" ) ;
    tooltip.left [10]:SetText( OQ.TT_WINLOSS ) ;
    tooltip.right[10]:SetText( tostring(m.wins or 0) .." - ".. tostring(m.losses or 0) ) ;
    tooltip.left [11]:SetText( OQ.TT_HKS ) ;
    tooltip.right[11]:SetText( tostring(m.hks or 0) .." k" ) ;
    tooltip.left [12]:SetText( OQ.TT_TEARS ) ;
    tooltip.right[12]:SetText( tostring( m.tears or 0 ) ) ;
    -- show icons for ranks & titles 
    tooltip.left [13]:SetText( OQ.TT_OQVERSION ) ;
    tooltip.right[13]:SetText( oq.get_version_str( m.oq_ver ) ) ;
    tooltip.left [tooltip.nRows - 0]:SetText( oq.get_rank_achieves( m.ranks ) ) ;
    tooltip.right[tooltip.nRows - 0]:SetText( "" ) ;
  end
      
  -- adjust dimensions of the box
  local w = tooltip.left[1]:GetStringWidth() ;
  for i=4,tooltip.nRows do
    tooltip.right[i]:SetWidth( tooltip:GetWidth() - 30 ) ;
  end

  local t = CLASS_ICON_TCOORDS[ OQ.LONG_CLASS[m.class] ] ;
  if t then
    tooltip.portrait.texture:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles") ;
    tooltip.portrait.texture:SetTexCoord(unpack(t)) ;
    tooltip.portrait.texture:SetAlpha( 1.0 ) ;
  end

  tooltip:Show() ;
end

function oq.tooltip_show()
  local tooltip = oq.tooltip ;
  if (tooltip ~= nil) then
    tooltip:Show() ;
  end
end

function oq.tooltip_hide() 
  local tooltip = oq.tooltip ;
  if (tooltip ~= nil) then
    tooltip:Hide() ;
  end
end

--------------------------------------------------------------------------
-- long tooltip
--------------------------------------------------------------------------

function oq.long_tooltip_create() 
  if (oq.long_tooltip ~= nil) then
    return oq.long_tooltip ;
  end
  local tooltip = oq.CreateFrame("FRAME", "OQTooltip", UIParent, nil ) ;
  tooltip:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background", 
                       edgeFile="Interface/Tooltips/UI-Tooltip-Border", 
                       tile=true, tileSize = 16, edgeSize = 16,
                       insets = { left = 4, right = 3, top = 4, bottom = 3 }
                      })

  tooltip:SetBackdropColor(0.0,0.0,0.0,1.0);
  tooltip.emphasis_texture = tooltip:CreateTexture( nil, "BORDER" ) ;
  tooltip.emphasis_texture:SetTexture( "" ) ;
  tooltip.emphasis_texture:SetPoint( "TOPLEFT"    , tooltip, "TOPLEFT"    ,  10, -10 ) ;
  tooltip.emphasis_texture:SetPoint( "BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -10,  10 ) ;

  tooltip.splat = tooltip:CreateTexture( nil, "BACKGROUND" ) ;
  tooltip.splat:SetTexture( "" ) ;
  tooltip.splat:SetPoint( "TOPLEFT"    , tooltip, "TOPLEFT"    ,  2, -2 ) ;
  tooltip.splat:SetPoint( "BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -2,  2 ) ;

  -- class portrait
  local f = oq.CreateFrame("FRAME", "OQTooltipPortraitFrame", tooltip ) ;
  f:SetWidth(35) ;
  f:SetHeight(35) ;
  f:SetBackdropColor(0.0,0.8,0.8,1.0) ;

  local t = tooltip:CreateTexture( nil, "OVERLAY" ) ;
  t:SetTexture( "Interface\\TargetingFrame\\UI-Classes-Circles" ) ;
  t:SetAllPoints( f ) ;
  t:SetAlpha( 1.0 ) ;
  f.texture = t ;

  f:SetPoint( "TOPRIGHT", -6, -1 * 6 ) ;
  f:Show() ;
  tooltip.portrait = f ;

  local x = 5 ;
  local y = 8 ;
  local cy = 17 ;
  tooltip.nRows = 20 ;
  tooltip:SetHeight( (tooltip.nRows+1)*(cy)+14 ) ;
  tooltip:SetWidth ( 220 ) ; -- 240

  tooltip.left  = {} ;
  tooltip.right = {} ;

  for i = 1, tooltip.nRows do
    if (i == (tooltip.nRows-1)) or (i == (tooltip.nRows)) then
      tooltip.left [i] = oq.tooltip_label( tooltip, x, y, "LEFT"  ) ;
      tooltip.left [i]:SetWidth( tooltip:GetWidth()- 3 ) ;
    else
      tooltip.left [i] = oq.tooltip_label( tooltip, x, y, "LEFT"  ) ;
    end
    if (i == 2) then
      tooltip.right[i] = oq.tooltip_label( tooltip, x, y, "RIGHT" ) ;
      tooltip.right[i]:SetWidth( tooltip:GetWidth()- (x + 3*15) ) ;
    else
      tooltip.right[i] = oq.tooltip_label( tooltip, x, y, "RIGHT" ) ;
    end
    if (i == 1) then
      x = x + 10 ;
      y = y + 2 ;
      tooltip.left [i]:SetFont(OQ.FONT, 12, "") ;
      tooltip.right[i]:SetFont(OQ.FONT, 12, "") ;
    else
      tooltip.left [i]:SetTextColor( 0.6, 0.6, 0.6 ) ;
      tooltip.left [i]:SetFont(OQ.FONT, 10, "") ;

      tooltip.right[i]:SetTextColor( 0.9, 0.9, 0.25 ) ;
      tooltip.right[i]:SetFont(OQ.FONT, 10, "") ;
    end
    y = y + cy ;
    if (i == (tooltip.nRows - 1)) then
      y = y + 15 ; -- spacer before last row
    end
  end
  oq.long_tooltip = tooltip ;
  return tooltip ;
end

function oq.long_tooltip_clear()
  local tooltip = oq.long_tooltip ;
  if (tooltip ~= nil) then
    for i = 1,tooltip.nRows do
      tooltip.left [i]:SetText( "" ) ;
      tooltip.right[i]:SetText( "" ) ;
    end
  end
end

function oq.long_tooltip_show()
  local tooltip = oq.long_tooltip ;
  if (tooltip ~= nil) then
    tooltip:Show() ;
  end
end

function oq.long_tooltip_hide() 
  local tooltip = oq.long_tooltip ;
  if (tooltip ~= nil) then
    tooltip:Hide() ;
  end
end

--------------------------------------------------------------------------
-- text helper tooltip
--------------------------------------------------------------------------
function oq.gen_tooltip_label( tt, x, y, align )
  local t = tt:CreateFontString() ;
  t:SetFontObject(GameFontNormal)
  t:SetWidth( tt:GetWidth()- (x + 2*15) ) ;
  t:SetHeight( 3*25 ) ;
  t:SetJustifyV( "TOP" ) ;
  t:SetJustifyH( align or "LEFT" ) ;
  t:SetText( "" ) ;
  t:Show() ;
  t:SetPoint("TOPLEFT", tt,"TOPLEFT", x, -1 * y ) ;
  return t ;
end

function oq.gen_tooltip_create() 
  if (oq.gen_tooltip ~= nil) then
    return oq.gen_tooltip ;
  end
  local tooltip ;
  tooltip = oq.CreateFrame("FRAME", "OQGenTooltip", UIParent, nil ) ;
  tooltip:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background", 
                       edgeFile="Interface/Tooltips/UI-Tooltip-Border", 
                       tile=true, tileSize = 16, edgeSize = 16,
                       insets = { left = 4, right = 3, top = 4, bottom = 3 }
                      })
--  local p = OQMainFrame ;
--  tooltip:SetPoint("TOPLEFT", p, "BOTTOMLEFT", 10, 0 ) ;

  tooltip:SetFrameStrata( "TOOLTIP" ) ;
  tooltip:SetBackdropColor(0.2,0.2,0.2,1.0);
  oq.setpos( tooltip, 100, 100, 100, 100 ) ;
  tooltip:Hide() ;

  tooltip.left  = {} ;
  tooltip.right = {} ;
  tooltip.left[1] = oq.gen_tooltip_label( tooltip, 8, 8 ) ;
  oq.gen_tooltip = tooltip ;
  return tooltip ;
end

function oq.gen_tooltip_clear()
  oq.gen_tooltip.left [1]:SetText( "" ) ;
  oq.gen_tooltip.right[1]:SetText( "" ) ;
end

function oq.gen_tooltip_set( f, txt )
  local tooltip = oq.gen_tooltip_create() ;
  tooltip:SetFrameLevel( 99 ) ;
  oq.tooltip_clear() ;
  tooltip.left [ 1]:SetText( txt ) ;

  -- adjust dimensions of the box
  local w = floor(tooltip.left[1]:GetStringWidth())  + 2*10 ;
  local h = 3*12 + 2*10 ;
  tooltip.left[1]:SetWidth ( w ) ;
  local x = f:GetLeft() + f:GetWidth() + 20 ;
  local y = (GetScreenHeight() - f:GetTop()) + f:GetHeight() + 20 ;
  tooltip:SetPoint("TOPLEFT", f, "BOTTOMRIGHT", 0, 0 ) ;
  oq.setpos( tooltip, x, y, w, h ) ;
  
  tooltip:Show() ;
end

function oq.gen_tooltip_show()
  if (oq.gen_tooltip ~= nil) then
    oq.gen_tooltip:Show() ;
  end
end

function oq.gen_tooltip_hide() 
  if (oq.gen_tooltip ~= nil) then
    oq.gen_tooltip:Hide() ;
  end
end

--------------------------------------------------------------------------
-- premade tooltip functions
--------------------------------------------------------------------------
local pm_tooltip = nil ;

function oq.pm_tooltip_create() 
  if (pm_tooltip ~= nil) then
    return pm_tooltip ;
  end
  pm_tooltip = oq.CreateFrame("FRAME", "OQPMTooltip", UIParent, nil ) ;
  pm_tooltip:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background", 
                          edgeFile="Interface/Tooltips/UI-Tooltip-Border", 
                          tile=true, tileSize = 16, edgeSize = 16,
                          insets = { left = 4, right = 3, top = 4, bottom = 3 }
                         })

  pm_tooltip.emphasis_texture = pm_tooltip:CreateTexture( nil, "BORDER" ) ;
  pm_tooltip.emphasis_texture:SetTexture( "" ) ;
  pm_tooltip.emphasis_texture:SetPoint( "TOPLEFT"    , pm_tooltip, "TOPLEFT"    ,  5, -5 ) ;
  pm_tooltip.emphasis_texture:SetPoint( "BOTTOMRIGHT", pm_tooltip, "BOTTOMRIGHT", -5,  5 ) ;
  
  pm_tooltip.splat = pm_tooltip:CreateTexture( nil, "BACKGROUND" ) ;
  pm_tooltip.splat:SetTexture( "" ) ;
  pm_tooltip.splat:SetPoint( "TOPLEFT"    , pm_tooltip, "TOPLEFT"    ,  9, -9 ) ;
  pm_tooltip.splat:SetPoint( "BOTTOMRIGHT", pm_tooltip, "BOTTOMRIGHT", -9,  9 ) ;
  
  pm_tooltip.nRows = 15 ;
  pm_tooltip:SetBackdropColor(0.0,0.0,0.0,1.0);
  pm_tooltip:SetWidth ( 210 ) ; --220
  pm_tooltip:SetHeight( 12 + pm_tooltip.nRows*16 ) ;
  pm_tooltip:SetMovable(true) ;
  pm_tooltip:SetAlpha( 1.0 ) ;
  pm_tooltip:SetFrameStrata( "TOOLTIP" ) ;
  pm_tooltip.left  = {} ;
  pm_tooltip.right = {} ;

  local x = 8 ;
  local y = 12 ;
  for i = 1, pm_tooltip.nRows do
    pm_tooltip.left [i] = oq.tooltip_label( pm_tooltip, x, y, "LEFT"  ) ;
    pm_tooltip.right[i] = oq.tooltip_label( pm_tooltip, x, y, "RIGHT" ) ;
    if (i == 1) then
      x = x + 10 ;
      y = y + 2 ;
      pm_tooltip.left [i]:SetFont(OQ.FONT, 12, "") ;
      pm_tooltip.right[i]:SetFont(OQ.FONT, 12, "") ;
      pm_tooltip.right[i]:SetWidth( pm_tooltip:GetWidth()- 15 ) ;
    else
      pm_tooltip.left [i]:SetTextColor( 0.6, 0.6, 0.6 ) ;
      pm_tooltip.left [i]:SetFont(OQ.FONT, 10, "") ;

      pm_tooltip.right[i]:SetPoint("TOPRIGHT", pm_tooltip,"TOPRIGHT", -10, -1 * y ) ;
      pm_tooltip.right[i]:SetTextColor( 0.9, 0.9, 0.25 ) ;
      pm_tooltip.right[i]:SetFont(OQ.FONT, 10, "") ;
    end
    y = y + 15 ;
  end
  return pm_tooltip ;
end

function oq.pm_tooltip_clear()
  for i = 1,pm_tooltip.nRows do
    pm_tooltip.left [i]:SetText( "" ) ;
    pm_tooltip.right[i]:SetText( "" ) ;
  end
end

function oq.pm_tooltip_get_xpbar( easy, hard, nbosses )
  local hero = "|TInterface\\Addons\\oqueue\\art\\red_block_64.tga:9:9:0:0|t";
  local norm = "|TInterface\\Addons\\oqueue\\art\\green_block_64.tga:9:9:0:0|t";
  local none = "|TInterface\\Addons\\oqueue\\art\\grey_block_64.tga:9:9:0:0|t";
  local str = "" ;
  easy = oq.decode_mime64_digits( easy ) ;
  hard = oq.decode_mime64_digits( hard ) ;
  for i=1,nbosses do
    if (oq.is_set( hard, bit.lshift( 1, i-1 ) )) then
      str = str .."".. hero ;
    elseif (oq.is_set( easy, bit.lshift( 1, i-1 ) )) then
      str = str .."".. norm ;
    else
      str = str .."".. none ;
    end
  end
  return str ;
end

function oq.pm_tooltip_get_rank( rank )
  rank = oq.decode_mime64_digits( rank ) ;
  return "|cFFD23C3C".. OQ.rbg_rank[ rank ].rank .."|r" ;
end

function oq.pm_tooltip_if_set( x, bitmask, str )
  x = oq.decode_mime64_digits( x ) ;
  if (x ~= nil) and (x ~= 0) and (oq.is_set( x, bitmask )) then
    return "|cFFD23C3C".. str .."|r" ;
  else
    return "|cFF606060".. str .."|r" ;
  end
end

function oq.pm_tooltip_set( f, raid_token )
  oq.pm_tooltip_create() ;
  local p = f:GetParent():GetParent():GetParent() ;
  pm_tooltip:SetPoint("TOPLEFT", p, "TOPRIGHT", 10, 0 ) ;
  pm_tooltip:Raise() ;
  oq.pm_tooltip_clear() ;

  local raid = oq.premades[raid_token] ;
  if (raid == nil) then
    return ;
  end
  local s = raid.stats ;
  local nMembers = s.nMembers ;
  local nWaiting = s.nWaiting ;
  if ((raid_token == oq.raid.raid_token) and oq.iam_raid_leader()) then
    s = OQ_data.stats ;
    nMembers, _avgresil, _avgilevel, nWaiting = oq.calc_raid_stats() ;
  end
  if (s == nil) then
    return ;
  end
  
  local nWins = 0 ;
  local nLosses = 0 ;

  pm_tooltip.left [ 1]:SetText( raid.name ) ;
  pm_tooltip.right[ 1]:SetText( oq.get_rank_icons( raid.leader_xp:sub(10,-1) ) ) ;
  
  pm_tooltip.left [ 2]:SetText( OQ.TT_LEADER ) ;
  
  if (raid.karma) and (raid.karma ~= 0) then
    pm_tooltip.right[ 2]:SetText( oq.karma_color( raid.karma ) .."(".. tostring(raid.karma) ..")|r  ".. raid.leader ) ;
  else
    pm_tooltip.right[ 2]:SetText( raid.leader ) ;
  end
  
  pm_tooltip.left [ 3]:SetText( OQ.TT_REALM ) ;
  pm_tooltip.right[ 3]:SetText( raid.leader_realm ) ;
  
  pm_tooltip.left [ 4]:SetText( OQ.TT_BATTLEGROUP ) ;
  pm_tooltip.right[ 4]:SetText( oq.find_bgroup( raid.leader_realm ) ) ;
  
  pm_tooltip.left [ 5]:SetText( OQ.TT_MEMBERS ) ;
  pm_tooltip.right[ 5]:SetText( nMembers ) ;
  pm_tooltip.left [ 6]:SetText( OQ.TT_WAITLIST ) ;
  pm_tooltip.right[ 6]:SetText( nWaiting ) ;
  
  --
  -- leader experience
  --
  if (raid.type == OQ.TYPE_BG) or (raid.type == OQ.TYPE_RBG) then
    pm_tooltip.left [ 7]:SetText( OQ.TT_RECORD ) ;
    nWins, nLosses = oq.get_winloss_record( raid.leader_xp ) ;
    local tag, y, cx, cy = oq.get_dragon_rank( raid.type, nWins or 0 ) ;  
    if (tag) then
      if (y == 0) then
        pm_tooltip.right[ 7]:SetText( "|T".. tag ..":32:32|t ".. nWins .." - ".. nLosses ) ;
      else
        pm_tooltip.right[ 7]:SetText( "|T".. tag ..":20:20|t ".. nWins .." - ".. nLosses ) ;
      end
    else
      pm_tooltip.right[ 7]:SetText( nWins .." - ".. nLosses ) ;
    end
    pm_tooltip.left [pm_tooltip.nRows - 0]:SetWidth( pm_tooltip:GetWidth() + 20 ) ;
    pm_tooltip.left [pm_tooltip.nRows - 0]:SetText( oq.get_rank_achieves( raid.leader_xp:sub(10,-1) ) ) ;
  elseif (raid.type == OQ.TYPE_SCENARIO) then
    local nWins   = oq.decode_mime64_digits(raid.leader_xp:sub(1,3)) ;
    local nLosses = oq.decode_mime64_digits(raid.leader_xp:sub(4,5)) ;
    local dkp     = oq.decode_mime64_digits(raid.leader_xp:sub(6,8)) ;
    local tag, y, cx, cy, title = oq.get_dragon_rank( raid.type, dkp ) ;  
    
    pm_tooltip.left [ 7]:SetText( OQ.TT_PVERECORD ) ;
    pm_tooltip.right[ 7]:SetText( nWins .." - ".. nLosses ) ;
    pm_tooltip.left [ 8]:SetText( OQ.TT_DKP ) ;
    if (tag) then
      if (y == 0) then
        pm_tooltip.right[ 8]:SetText( "|T".. tag ..":32:32|t ".. tostring( dkp ) ) ;
      else
        pm_tooltip.right[ 8]:SetText( "|T".. tag ..":20:20|t ".. tostring( dkp ) ) ;
      end
    else
      pm_tooltip.right[ 8]:SetText( tostring( dkp ) ) ;
    end
    
  elseif (raid.type == OQ.TYPE_CHALLENGE) then
    nWins, nLosses = oq.get_challenge_winloss_record( raid.leader_xp ) ;
    local dkp            = oq.decode_mime64_digits(raid.leader_xp:sub(12,14)) ;
    local tag, y, cx, cy = oq.get_dragon_rank( raid.type, dkp or 0 ) ;  
    
    pm_tooltip.left [ 7]:SetText( OQ.TT_PVERECORD ) ;
    pm_tooltip.right[ 7]:SetText( nWins .." - ".. nLosses ) ;
    pm_tooltip.left [ 8]:SetText( OQ.TT_DKP ) ;
    if (tag) then
      if (y == 0) then
        pm_tooltip.right[ 8]:SetText( "|T".. tag ..":32:32|t ".. tostring( dkp ) ) ;
      else
        pm_tooltip.right[ 8]:SetText( "|T".. tag ..":20:20|t ".. tostring( dkp ) ) ;
      end
    else
      pm_tooltip.right[ 8]:SetText( tostring( dkp ) ) ;
    end
    
    local medals = raid.leader_xp ;
    pm_tooltip.left [11]:SetText( "medals" ) ;
    local str = "" ;
    local n = oq.decode_mime64_digits( medals:sub(1,2) ) ;
    if (n > 0) then
      str = str .."  ".. tostring(n) .."x ".. OQ.BRONZE_MEDAL ;
    end
    n = oq.decode_mime64_digits( medals:sub(3,4) ) ;
    if (n > 0) then
      str = str .."  ".. tostring(n) .."x ".. OQ.SILVER_MEDAL ;
    end
    n = oq.decode_mime64_digits( medals:sub(5,6) ) ;
    if (n > 0) then
      str = str .."".. tostring(n) .."x ".. OQ.GOLD_MEDAL ;
    end
    if (str == "") then
      str = "--" ;
    end
    pm_tooltip.right[11]:SetText( str ) ;   
    
  elseif (raid.type == OQ.TYPE_RAID) or (raid.type == OQ.TYPE_DUNGEON) then
    nWins, nLosses = oq.get_pve_winloss_record( raid.leader_xp ) ;
    local dkp            = oq.decode_mime64_digits(raid.leader_xp:sub(17,19)) ;
    local tag, y, cx, cy = oq.get_dragon_rank( raid.type, dkp or 0 ) ;  

    pm_tooltip.left [ 7]:SetText( OQ.TT_PVERECORD ) ;
    pm_tooltip.right[ 7]:SetText( nWins .." - ".. nLosses ) ;
    
    pm_tooltip.left [ 8]:SetText( OQ.TT_DKP ) ;
    if (tag) then
      if (y == 0) then
        pm_tooltip.right[ 8]:SetText( "|T".. tag ..":26:26|t ".. tostring( dkp ) ) ;
      else
        pm_tooltip.right[ 8]:SetText( "|T".. tag ..":20:20|t ".. tostring( dkp ) ) ;
      end
    else
      pm_tooltip.right[ 8]:SetText( tostring( dkp ) ) ;
    end
    
    local dots = "" ;
    local raids = raid.leader_xp ;
    pm_tooltip.left [pm_tooltip.nRows - 5]:SetText( "|cFFFFD331".. OQ.LABEL_RAIDS .."|r" ) ;
    pm_tooltip.right[pm_tooltip.nRows - 5]:SetText( "" ) ;
    pm_tooltip.left [pm_tooltip.nRows - 4]:SetText( OQ.RAID_TOES ) ;
    pm_tooltip.right[pm_tooltip.nRows - 4]:SetText( oq.pm_tooltip_get_xpbar( raids:sub(1,1), raids:sub(2,2), 4 ) ) ;
    pm_tooltip.left [pm_tooltip.nRows - 3]:SetText( OQ.RAID_HOF ) ;
    pm_tooltip.right[pm_tooltip.nRows - 3]:SetText( oq.pm_tooltip_get_xpbar( raids:sub(3,3), raids:sub(4,4), 6 ) ) ;
    pm_tooltip.left [pm_tooltip.nRows - 2]:SetText( OQ.RAID_MV ) ;
    pm_tooltip.right[pm_tooltip.nRows - 2]:SetText( oq.pm_tooltip_get_xpbar( raids:sub(5,5), raids:sub(6,6), 6 ) ) ;

    pm_tooltip.left [pm_tooltip.nRows - 1]:SetText( OQ.RAID_TOT ) ;
    dots =             oq.pm_tooltip_get_xpbar( raids:sub(7,7), raids:sub( 8, 8), 6 ) ;
    dots = dots .."".. oq.pm_tooltip_get_xpbar( raids:sub(9,9), raids:sub(10,10), 6 ) ;
    pm_tooltip.right[pm_tooltip.nRows - 1]:SetText( dots ) ;    
    pm_tooltip.left [pm_tooltip.nRows - 0]:SetText( OQ.RAID_RA_DEN ) ;
    pm_tooltip.right[pm_tooltip.nRows - 0]:SetText( oq.pm_tooltip_get_xpbar( nil, raids:sub(11,11), 1 ) ) ;
  end
  
  pm_tooltip:Show() ;
end

function oq.pm_tooltip_show()
  if (pm_tooltip ~= nil) then
    pm_tooltip:Show() ;
  end
end

function oq.pm_tooltip_hide() 
  if (pm_tooltip ~= nil) then
    pm_tooltip:Hide() ;
  end
end

