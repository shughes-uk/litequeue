--[[ 
  @file       oqueue_pkt.lua
  @brief      oqueue packet object

  @author     rmcinnis
  @date       april 25, 2013
  @copyright  Solid ICE Technologies
              this file may be distributed so long as it remains unaltered
              if this file is posted to a web site, credit must be given to me along with a link to my web page
              no code in this file may be used in other works without expressed permission  
]]--
local addonName, OQ = ... ;
local oq = OQ:mod() ; -- thank goodness i stumbled across this trick
local _ ; -- throw away (was getting taint warning; what happened blizz?)

OQPacket = {} ;

function OQPacket:new() 
  local o = {} ;
  o._vars = {} ;
  o._source = nil ;
  o._sender = nil ;
  o._pkt    = nil ;
  setmetatable(o, { __index = OQPacket }) ;
  return o ;
end

function OQPacket:cleanup()
  self._source = nil ;
  self._sender = nil ;
  self._pkt    = nil ;
  for k in pairs(self._vars) do 
    self._vars[k] = nil ;
  end
end

function OQPacket:parse( source, sender, str )
  self._source = source ;
  self._sender = sender ;
  self._pkt    = str ;
  local v ;
  for v in string.gmatch( str, "([^,]+)") do
    table.insert( self._vars, v ) ;
  end
end

function OQPacket:msg_id()
  return self._vars[5] ;
end

function OQPacket:msg_type()
  if (self._vars[3]) then
    return self._vars[3]:sub(1,1) ;
  end
  return 'X' ;
end

function OQPacket:token()
  return self._vars[3] ;
end

