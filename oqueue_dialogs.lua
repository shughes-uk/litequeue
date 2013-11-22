--[[ 
  @file       oqueue_dialogs.lua
  @brief      oqueue dialogs

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

--------------------------------------------------------------------------
--  dialog definitions
--------------------------------------------------------------------------
StaticPopupDialogs["OQ_AddToonName"] = {
  preferredIndex=STATICPOPUPS_NUMDIALOGS,  -- http://forums.wowace.com/showthread.php?p=320956
  text = OQ.DLG_01,
  button1 = OQ.DLG_OK,
  button2 = OQ.DLG_CANCEL,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function (self, data)
    self.editBox:SetText("") ;
    self.editBox:SetFocus() ;
  end,
  OnAccept = function (self, data, data2)
    local text = self.editBox:GetText()
    oq.add_toon( text ) ;
  end,
  EditBoxOnEnterPressed = function(self)
    local text = self:GetText()
    oq.add_toon( text ) ;
    self:GetParent():Hide() ;
  end,
  EditBoxOnEscapePressed = function(self)
    self:GetParent():Hide() ;
  end,
  hasEditBox = true
}

StaticPopupDialogs["OQ_BanBTag"] = {
  preferredIndex=STATICPOPUPS_NUMDIALOGS,
  text = OQ.DLG_17,
  button1 = OQ.DLG_OK,
  button2 = OQ.DLG_CANCEL,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function (self, data)
    self.editBox:SetText("") ;
    self.editBox:SetFocus() ;
  end,
  OnAccept = function (self, data, data2)
    local text = self.editBox:GetText()
    oq.ban_user( text ) ;
  end,
  EditBoxOnEnterPressed = function(self)
    local text = self:GetText()
    oq.ban_user( text ) ;
    self:GetParent():Hide() ;
  end,
  EditBoxOnEscapePressed = function(self)
    self:GetParent():Hide() ;
  end,
  hasEditBox = true
}

StaticPopupDialogs["OQ_BanUser"] = {
  preferredIndex=STATICPOPUPS_NUMDIALOGS,
  text = OQ.DLG_15,
  button1 = OQ.DLG_OK,
  button2 = OQ.DLG_CANCEL,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function (self, data, data2)
    self.editBox:SetText("") ;
    self.editBox:SetFocus() ;
  end,
  OnAccept = function (self, data, data2)
    reason = self.editBox:GetText() ;
    local d = self.data2 ;
    if (d.flag == 1) then
      local m = oq.raid.group[d.gid].member[d.slot_] ;
      oq.ban_add( m.realid, reason ) ;
      oq.remove_member( d.gid, d.slot_ ) ;
    elseif (d.flag == 2) then
      oq.ban_add( d.btag, reason ) ;
      oq.remove_waitlist( d.req_token ) ;
    elseif (d.flag == 3) then
      oq.ban_add( d.btag, reason ) ;
    elseif (d.flag == 4) then
      oq.ban_add( d.btag, reason ) ;
      oq.remove_premade( d.raid_tok ) ;
    end
    self:Hide() ;
  end,
  EditBoxOnEnterPressed = function(self, data, data2)
    local reason = self:GetText() ;
    local d = self:GetParent().data2 ;
    if (d.flag == 1) then
      local m = oq.raid.group[d.gid].member[d.slot_] ;
      oq.ban_add( m.realid, reason ) ;
      oq.remove_member( d.gid, d.slot_ ) ;
    elseif (d.flag == 2) then
      oq.ban_add( d.btag, reason ) ;
      oq.remove_waitlist( d.req_token ) ;
    elseif (d.flag == 3) then
      oq.ban_add( d.btag, reason ) ;
    elseif (d.flag == 4) then
      oq.ban_add( d.btag, reason ) ;
      oq.remove_premade( d.raid_tok ) ;
    end
    self:GetParent():Hide() ;
  end,
  EditBoxOnEscapePressed = function(self)
    self:GetParent():Hide() ;
  end,
  hasEditBox = true
}

StaticPopupDialogs["OQ_EnterBattle"] = {
  preferredIndex=STATICPOPUPS_NUMDIALOGS,
  text = OQ.DLG_02,
  button1 = OQ.DLG_OK,
  timeout = 30,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function (self, data)
  end,
  OnAccept = function (self, data, data2)
    if (data == nil) then
      data = 1 ;
    end
    self:Hide() ;
  end,
  OnCancel = function (self, data, data2)
    if (data == nil) then
      data = 1 ;
    end
    self:Hide() ;
  end,
  hasEditBox = false
}

StaticPopupDialogs["OQ_EnterPremadeName"] = {
  preferredIndex=STATICPOPUPS_NUMDIALOGS,
  text = OQ.DLG_03,
  button1 = OQ.DLG_OK,
  button2 = OQ.DLG_CANCEL,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function (self, data)
    self.editBox:SetText("") ;
    self.editBox:SetFocus() ;
  end,
  OnAccept = function (self, data, data2)
    if (data2) then
      data2(data) ;
    end
    self:Hide() ;
  end,
  EditBoxOnEnterPressed = function(self)
    if (data2) then
      data2(data) ;
    end
    self:GetParent():Hide() ;
  end,
  EditBoxOnEscapePressed = function(self)
    self:GetParent():Hide() ;
  end,
  hasEditBox = true
}

StaticPopupDialogs["OQ_EnterRealID"] = {
  preferredIndex=STATICPOPUPS_NUMDIALOGS,
  text = OQ.DLG_04,
  button1 = OQ.DLG_OK,
  button2 = OQ.DLG_CANCEL,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function (self, data)
    self.editBox:SetText(player_realid or "") ;
    self.editBox:SetFocus() ;
  end,
  OnAccept = function (self, data, data2)
    player_realid  = self.editBox:GetText() ;
    OQ_data.realid = player_realid ;
    if (data2) then
      data2(data) ;
    end
    self:Hide() ;
  end,
  EditBoxOnEnterPressed = function(self)
    player_realid  = self:GetText() ;
    OQ_data.realid = player_realid ;
    if (data2) then
      data2(data) ;
    end
    self:GetParent():Hide() ;
  end,
  EditBoxOnEscapePressed = function(self)
    self:GetParent():Hide() ;
  end,
  hasEditBox = true
}

StaticPopupDialogs["OQ_EnterPword"] = {
  preferredIndex=STATICPOPUPS_NUMDIALOGS,
  text = OQ.DLG_05,
  button1 = OQ.DLG_OK,
  button2 = OQ.DLG_CANCEL,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function (self, data)
    self.editBox:SetText("") ;
    self.editBox:SetFocus() ;
  end,
  OnAccept = function (self, data, data2)
    oq.send_req_waitlist( data, self.editBox:GetText() ) ;
    self:Hide() ;
  end,
  EditBoxOnEnterPressed = function(self, data, data2)
    oq.send_req_waitlist( data, self:GetText() ) ;
    self:GetParent():Hide() ;
  end,
  EditBoxOnEscapePressed = function(self)
    self:GetParent():Hide() ;
  end,
  hasEditBox = true
}

StaticPopupDialogs["OQ_NewVersionAvailable"] = {
  preferredIndex=STATICPOPUPS_NUMDIALOGS,
  text = OQ.DLG_07,
  button1 = OQ.DLG_OK,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function (self, data)
    self.editBox:SetWidth( 275 ) ;
    self.editBox:SetText("http://curse.com/addons/wow/oqueue") ;
    self.editBox:SetFocus() ;
    -- fanfare for new version
    oq.excited_cheer() ;
  end,
  OnAccept = function (self, data, data2)
    self:Hide() ;
  end,
  EditBoxOnEnterPressed = function(self)
    self:GetParent():Hide() ;
  end,
  EditBoxOnEscapePressed = function(self)
    self:GetParent():Hide() ;
  end,
  hasEditBox = true
}

StaticPopupDialogs["OQ_NotPartyLead"] = {
  preferredIndex=STATICPOPUPS_NUMDIALOGS,
  text = OQ.DLG_08,
  button1 = OQ.DLG_OK,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function (self, data)
  end,
  OnAccept = function (self, data, data2)
    self:Hide() ;
  end,
  OnCancel = function (self, data, data2)
    self:Hide() ;
  end,
  hasEditBox = false
}

StaticPopupDialogs["OQ_NoPartyWaitlists"] = {
  preferredIndex=STATICPOPUPS_NUMDIALOGS,
  text = OQ.DLG_20,
  button1 = OQ.DLG_OK,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function (self, data)
  end,
  OnAccept = function (self, data, data2)
    self:Hide() ;
  end,
  OnCancel = function (self, data, data2)
    self:Hide() ;
  end,
  hasEditBox = false
}

StaticPopupDialogs["OQ_NoWaitlistWhilePremade"] = {
  preferredIndex=STATICPOPUPS_NUMDIALOGS,
  text = OQ.DLG_21,
  button1 = OQ.DLG_OK,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function (self, data)
    oq.center( self ) ;
  end,
  OnAccept = function (self, data, data2)
    self:Hide() ;
  end,
  OnCancel = function (self, data, data2)
    self:Hide() ;
  end,
  hasEditBox = false
}

StaticPopupDialogs["OQ_NoWaitlistWhilePremadeLead"] = {
  preferredIndex=STATICPOPUPS_NUMDIALOGS,
  text = OQ.DLG_22,
  button1 = OQ.DLG_OK,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function (self, data)
    oq.center( self ) ;
  end,
  OnAccept = function (self, data, data2)
    self:Hide() ;
  end,
  OnCancel = function (self, data, data2)
    self:Hide() ;
  end,
  hasEditBox = false
}

StaticPopupDialogs["OQ_CannotCreatePremade"] = {
  preferredIndex=STATICPOPUPS_NUMDIALOGS,
  text = OQ.DLG_09,
  button1 = OQ.DLG_OK,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function (self, data)
    oq.center( self ) ;
  end,
  OnAccept = function (self, data, data2)
    self:Hide() ;
  end,
  OnCancel = function (self, data, data2)
    self:Hide() ;
  end,
  hasEditBox = false
}

StaticPopupDialogs["OQ_DoNotQualifyPremade"] = {
  preferredIndex=STATICPOPUPS_NUMDIALOGS,
  text = OQ.DLG_19,
  button1 = OQ.DLG_OK,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function (self, data)
    oq.center( self ) ;
  end,
  OnAccept = function (self, data, data2)
    self:Hide() ;
  end,
  OnCancel = function (self, data, data2)
    self:Hide() ;
  end,
  hasEditBox = false
}

StaticPopupDialogs["OQ_PremadeTypeMissing"] = {
  preferredIndex=STATICPOPUPS_NUMDIALOGS,
  text = OQ.MSG_MISSINGTYPE,
  button1 = OQ.DLG_OK,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function (self, data)
    oq.center( self ) ;
  end,
  OnAccept = function (self, data, data2)
    self:Hide() ;
  end,
  OnCancel = function (self, data, data2)
    self:Hide() ;
  end,
  hasEditBox = false
}

StaticPopupDialogs["OQ_QueuePoppedLeader"] = {
  preferredIndex=STATICPOPUPS_NUMDIALOGS,
  text = OQ.DLG_10,
  button1 = OQ.DLG_ENTER,
  button2 = OQ.DLG_LEAVE,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function (self, data)
  end,
  OnAccept = function (self, data, data2)
    oq.raid_announce( "enter_bg,".. data ) ;
    self:Hide() ;
  end,
  OnCancel = function (self, data, data2)
    oq.raid_announce( "leave_queue,".. data ) ;
    oq.battleground_leave_now( data ) ;
    self:Hide() ;
    oq.ui:Show() ; -- force it, in case the user hit esc
  end,
  hasEditBox = false
}

StaticPopupDialogs["OQ_QueuePoppedMember"] = {
  preferredIndex=STATICPOPUPS_NUMDIALOGS,
  text = OQ.DLG_11,
  button1 = nil,
  button2 = nil,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function (self, data)
  end,
  OnAccept = function (self, data, data2)
    self:Hide() ;
  end,
  OnCancel = function (self, data, data2)
    self:Hide() ;
  end,
  hasEditBox = false
}

StaticPopupDialogs["OQ_QuitRaidConfirm"] = {
  preferredIndex=STATICPOPUPS_NUMDIALOGS,
  text = OQ.DLG_12,
  button1 = OQ.DLG_YES,
  button2 = OQ.DLG_NO,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function (self, data)
  end,
  OnAccept = function (self, data, data2)
    if (not oq.iam_raid_leader()) and (not oq.iam_party_leader()) then
      oq.leave_party() ;
      oq.quit_raid_now() ;
    else
      oq.quit_raid_now() ;
    end
    self:Hide() ;
  end,
  OnCancel = function (self, data, data2)
    self:Hide() ;
  end,
  hasEditBox = false
}

StaticPopupDialogs["OQ_ReadyCheck"] = {
  preferredIndex=STATICPOPUPS_NUMDIALOGS,
  text = OQ.DLG_13,
  button1 = OQ.DLG_READY,
  button2 = OQ.DLG_NOTREADY,
  timeout = 20,
  whileDead = true,
  hideOnEscape = false,
  OnShow = function (self, data)
    local my_group, my_slot = oq.my_seat() ;
    oq.ready_check( my_group, my_slot, OQ.FLAG_WAITING ) ;
    PlaySound( "ReadyCheck" ) ;
  end,
  OnAccept = function (self, data, data2)
    local my_group, my_slot = oq.my_seat() ;
    oq.ready_check( my_group, my_slot, OQ.FLAG_READY ) ;
    self:Hide() ;
  end,
  OnCancel = function (self, data, reason)
    local my_group, my_slot = oq.my_seat() ;
    if (reason == "timeout") then
      oq.ready_check( my_group, my_slot, OQ.FLAG_CLEAR ) ;
    else
      oq.ready_check( my_group, my_slot, OQ.FLAG_NOTREADY ) ;
    end
    self:Hide() ;
  end,
  hasEditBox = false
}

StaticPopupDialogs["OQ_ReloadUI"] = {
  preferredIndex=STATICPOPUPS_NUMDIALOGS,
  text = OQ.DLG_14,
  button1 = OQ.DLG_OK,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  OnShow = function (self, data)
  end,
  OnAccept = function (self, data, data2)
    oq.on_reload_now() ;
    self:Hide() ;
  end,
  OnCancel = function (self, data, data2)
    oq.on_reload_now() ;
    self:Hide() ;
  end,
  hasEditBox = false
}

local _brb_dlg = nil ;
function oq.brb_dlg()
  if (_brb_dlg == nil) then
    local cx = 300 ;
    local cy = 200 ;
    local x  = (UIParent:GetWidth()-cx)/2 ;
    local y  = 300 ;
    local f = oq.CreateFrame("FRAME", "OQBRBDialog", UIParent ) ;
    oq.setpos( f, x, y, cx, cy ) ;
    f:SetBackdropColor(0.2,0.2,0.2,1.0);
    f:SetPoint( "TOPLEFT", x, -1 * y) ;
    f:SetBackdrop({bgFile="Interface/FrameGeneral/UI-Background-Rock", 
                   edgeFile="Interface/Tooltips/UI-Tooltip-Border", 
                   tile=true, tileSize = 16, edgeSize = 16,
                   insets = { left = 4, right = 3, top = 4, bottom = 3 }
                  })
    f:SetBackdropColor(0.2,0.2,0.2,1.0);
    f:SetFrameStrata("DIALOG") ;
    f:SetFrameLevel(99) ;
    f:SetAlpha( 1.0 ) ;
    f.ok = oq.button2( f, 20, 20, cx-2*20, cy-2*20, OQ.IAM_BACK, 15, function(self) self:GetParent():Hide() ; end ) ;
    
    f:SetScript( "OnShow", function(self)
                             self.init(self) ;
                           end 
               ) ;
    f:SetScript( "OnHide", function(self)
                             oq.iam_back() ;
                             oq.tremove_value( UISpecialFrames, self:GetName() ) ;
                             tinsert( UISpecialFrames, oq.ui:GetName() ) ;
                           end
               ) ;
    f.center = function(self)
                 oq.moveto( self, 
                            (GetScreenWidth ()-self:GetWidth ())/2,
                            (GetScreenHeight()-self:GetHeight())/2 - 100
                          ) ;
               end
    f.init = function(self)
               local cx = 300 ;
               local cy = 200 ;
               local x  = (UIParent:GetWidth()-cx)/2 ;
               local y  = 200 ;
               oq.setpos( self, 10, 10, 300, 200 ) ;
               self.center( self ) ;
             end ;
    _brb_dlg = f ;
  end

  tinsert( UISpecialFrames, _brb_dlg:GetName() ) ;
  oq.tremove_value( UISpecialFrames, oq.ui:GetName() ) ;

  _brb_dlg:Show() ;
  return _brb_dlg ;
end
 
