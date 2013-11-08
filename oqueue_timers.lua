--[[ 
  @file       oqueue_timers.lua
  @brief      oqueue timers

  @author     rmcinnis
  @date       april 06, 2012
  @copyright  Solid ICE Technologies
              this file may be distributed so long as it remains unaltered
              if this file is posted to a web site, credit must be given to me along with a link to my web page
              no code in this file may be used in other works without expressed permission  
              
  note:       timer resolution ==0.050 seconds
]]--
local addonName, OQ = ... ;
local oq = OQ:mod() ; -- thank goodness i stumbled across this trick
local _ ; -- throw away (was getting taint warning; what happened blizz?)
if (OQ.table == nil) then
  OQ.table = {} ;
end
local tbl = OQ.table ;

local OQ_LILREDX_ICON  = "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp:8:8:0:0:64:64:32:48:16:32|t";
local OQ_LILSKULL_ICON = "|TInterface\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp:10:10:0:0:64:64:48:64:16:32|t";
OQ.TIMER_RESOLUTION = 200/1000 ; -- 5 times per second

--------------------------------------------------------------------------
-- timer functions
--------------------------------------------------------------------------
function oq.__get_timer()
  if (oq._timer_pool == nil) then
    oq._timer_pool = tbl.new() ;
  end
  local t = next(oq._timer_pool) ;
  if t then
    oq._timer_pool[t] = nil ;
  else
    oq._nTimers = (oq._nTimers or 0) + 1 ;
    t = { __id = oq._nTimers } ;
  end
  return t ;
end

function oq.__del_timer( t )
  if (oq._timer_pool == nil) then
    oq._timer_pool = tbl.new() ;
  end
  if (t) then
    oq._timer_pool[t] = true ;
  end
  return nil ;
end

function oq.create_timer()
  if (oq.timers == nil) then
    oq.next_timer_cycle = 0 ;
    oq.timer_slice      = OQ.TIMER_RESOLUTION ; -- no more than 10 cycles per second; helps throttle for high framerate machines
    oq.timers = tbl.new() ;
    oq.ui_timer = oq.CreateFrame("Frame", "OQ_TimerFrame" ) ;
    oq.ui_timer:SetScript( "OnUpdate", function(self, elapsed) oq.timer_trigger( GetTime() ) ; end ) ;
    oq.ui_timer:SetSize( 2, 2 ) ;
    oq.ui_timer:Show() ;
  end
end

function oq.timer( id, dt_, func_, repeater, arg1_, arg2_, arg3_, arg4_, arg5_, arg6_, arg7_ )
  if (oq.timers == nil) then
    oq.create_timer() ;
  end
  
  if (func_ == nil) then
    oq.timers[ id ] = oq.__del_timer( oq.timers[ id ] ) ;
  else
    oq.timers[ id ] = oq.__get_timer() ;
    oq.timers[ id ].dt       = dt_ ;
    oq.timers[ id ].tm       = GetTime() + dt_ ;
    oq.timers[ id ].one_shot = (not repeater) ;
    oq.timers[ id ].func     = func_ ;
    oq.timers[ id ].arg1     = arg1_ ;
    oq.timers[ id ].arg2     = arg2_ ;
    oq.timers[ id ].arg3     = arg3_ ;
    oq.timers[ id ].arg4     = arg4_ ;
    oq.timers[ id ].arg5     = arg5_ ;
    oq.timers[ id ].arg6     = arg6_ ;
    oq.timers[ id ].arg7     = arg7_ ;
  end
end

function oq.is_timer(id)
  return ((oq.timers ~= nil) and (oq.timers[id] ~= nil)) ;
end

function oq.timer_clear()
  if (oq.timers == nil) then
    return ;
  end
  for i,v in pairs( oq.timers ) do
    oq.__del_timer( v ) ;
  end
  tbl.clear( oq.timers ) ;
end

function oq.timer_dump() 
  print( "--[ timers ]------" ) ;
  for i,v in pairs( oq.timers ) do
    if (v.one_shot) then
      print( "  ".. string.format( "%4.02f", v.dt ) .."  ".. tostring(i) .."   one_shot" ) ;
    else
      print( "  ".. string.format( "%02d", v.dt ) .."  ".. tostring(i) ) ;
    end
  end  
  print( "--" ) ;
end

oq.one_shot = 0 ;
function oq.timer_oneshot( dt_, func_, arg1_, arg2_, arg3_, arg4_, arg5_, arg6_, arg7_ )
  oq.one_shot = oq.one_shot + 1 ;
  oq.timer( "one_shot.".. oq.one_shot, dt_, func_, nil, arg1_, arg2_, arg3_, arg4_, arg5_, arg6_, arg7_ ) ;  
end

-- resets timer to now + dt
function oq.timer_reset( id, dt )
  if (oq.timers[ id ] ~= nil) then
    local now = GetTime() ;
    if (dt == nil) then
      dt = oq.timers[ id ].dt ;
    end
    oq.timers[ id ].tm = now + dt ;
  end
end

function oq.timer_trigger( now )
  if (now < oq.next_timer_cycle) then
    return ;
  end
  oq.next_timer_cycle = now + oq.timer_slice ;
  for i,v in pairs( oq.timers ) do
    if (v.tm < now) then
      local arg1 = v.arg1 ;
      if (arg1 == nil) or (arg1 == "#now") then
        arg1 = now ;
      end
      oq._timer_id = i ;
      local retOK, rc = pcall( v.func, arg1, v.arg2, v.arg3, v.arg4, v.arg5, v.arg6, v.arg7 ) ;
      if (retOK == true) then 
        if (rc ~= nil) or (v.one_shot) then
          oq.timers[i] = oq.__del_timer( oq.timers[i] ) ;
        else
          v.error_cnt = nil ;
          v.tm = now + v.dt ;
        end
      else
        v.error_cnt = (v.error_cnt or 0) + 1 ;
        if ((v.error_cnt % 5) == 0) then
          print( OQ_LILREDX_ICON .."  OQ: error calling '".. tostring(i) .."'  error: ".. tostring(rc) ) ;
          print( OQ_LILREDX_ICON .."  OQ: removing timer" ) ;
          oq.timers[i] = oq.__del_timer( oq.timers[i] ) ;
        end
      end
    end
  end
end

function oq.timer_trip( id )
  if (oq.timers[ id ] ~= nil) then
    oq.timers[ id ].tm = 0 ;
  end
end

