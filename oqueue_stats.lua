--[[ 
  @file       oqueue_stats.lua
  @brief      oqueue statistics object

  @author     rmcinnis
  @date       april 25, 2013
  @copyright  Solid ICE Technologies
              this file may be distributed so long as it remains unaltered
              if this file is posted to a web site, credit must be given to me along with a link to my web page
              no code in this file may be used in other works without expressed permission  
              
  note:       still learning the tricks of lua.  objects can be simulated using metatables somehow 
              (would've been nice to know sooner)
]]--
local addonName, OQ = ... ;
local oq = OQ:mod() ; -- thank goodness i stumbled across this trick
local _ ; -- throw away (was getting taint warning; what happened blizz?)
if (OQ.table == nil) then
  OQ.table = {} ;
end
local tbl = OQ.table ;

--------------------------------------------------------------------------
--  packet stats
--------------------------------------------------------------------------
PacketStatistics = {} ;
function PacketStatistics:new( max_cnt ) 
   local o = tbl.new() ;
   o._cnt = 0 ;
   o._max = max_cnt ;
   o.array = tbl.new() ;
   for i=1,max_cnt do
      o.array[i] = tbl.new() ;
      o.array[i]._x = nil ;
      o.array[i]._tm = nil ;
   end
   o._n   = 0 ;
   o._aps = 0 ;
   o._dt  = 0 ;
   setmetatable(o, { __index = PacketStatistics }) ;
   return o ;
end

function PacketStatistics:avg()
   local t1 = nil ; 
   local t2 = nil ; 
   local n1 = 0 ;
   local n2 = 0 ;
   self._n  = 0 ;
   self._aps = 0 ; -- avg per second
   
   for i=1,self._max do
      if (self.array[i]._x ~= nil) then
         self._n = self._n + 1 ;
         if (t2 == nil) then
            t2 = self.array[i]._tm ;
            n2 = self.array[i]._x ;
         end
         t1 = self.array[i]._tm ;
         n1 = self.array[i]._x ;
      end
   end
   if (self._n < 2) then
      self._aps = 0 ;
      self._dt  = 0 ;
      return 0 ;
   end
   self._dt  = t2 - t1 ;
   if (self._dt > 0) then
      self._aps = (n2 - n1) / self._dt ;
   end
   return self._aps ;
end

function PacketStatistics:inc()
  self._cnt = self._cnt + 1 ;
  self:push( self._cnt ) ;
end

function PacketStatistics:push( x ) 
   for i=self._max,2,-1 do
      self.array[i]._x  = self.array[i-1]._x  ;
      self.array[i]._tm = self.array[i-1]._tm ;
   end
   self.array[1]._x  = x ;
   self.array[1]._tm = GetTime() ;
   self:avg() ;
end

oq.pkt_sent      = PacketStatistics:new(10) ; 
oq.pkt_recv      = PacketStatistics:new(10) ; 
oq.pkt_processed = PacketStatistics:new(10) ; 

