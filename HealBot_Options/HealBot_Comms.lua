local HealBotcommAddonSummary={}
local HealBotAddonSummaryNoCommsCPU={}
local HealBotAddonSummaryNoCommsMem={}
local HealBotAddonSummaryNoCommsSort={}
local _

local qAddonMsg={}
function HealBot_Comms_SendAddonMsg(msg, aType, pName)
    local aMsg=""
    if pName then
        aMsg=msg.."~"..aType.."~"..pName
    else
        aMsg=msg.."~"..aType
    end
    local unique=true;
    table.foreach(qAddonMsg, function (index,msg)
        if msg==aMsg then unique=false; end
    end)
    if unique then
        table.insert(qAddonMsg,aMsg)
    end
end

function HealBot_Comms_Set()
    local inInst,inType = HealBot_ZoneType()
    HealBot_Comms_SendTo(inInst,inType)
    HealBot_Comms_GuildUpdate()
end

local hbCommsTo=0
function HealBot_Comms_SendTo(inInst,inType)
    if inInst and (IsInGroup(LE_PARTY_CATEGORY_INSTANCE) or IsInRaid(LE_PARTY_CATEGORY_INSTANCE) or inType == "pvp" or inType == "arena" or HasLFGRestrictions()) then
        hbCommsTo=1
    elseif IsInRaid() then
        hbCommsTo=2
    elseif IsInGroup() then
        hbCommsTo=3
    else
        hbCommsTo=0
    end
end

local hbInGuild=false
function HealBot_Comms_GuildUpdate()
    hbInGuild=IsInGuild()
end

function HealBot_Comms_SendInstantAddonMsg(msg,notGroup,toPlayer)
    if notGroup then
        if notGroup==1 and hbInGuild then
            C_ChatInfo.SendAddonMessage(HEALBOT_HEALBOT, msg, "GUILD")
        elseif notGroup==2 then
            C_ChatInfo.SendAddonMessage(HEALBOT_HEALBOT, msg, "WHISPER", toPlayer)
        end
    elseif hbCommsTo==1 then
        C_ChatInfo.SendAddonMessage(HEALBOT_HEALBOT, msg, "INSTANCE_CHAT")
    elseif hbCommsTo==2 then
        C_ChatInfo.SendAddonMessage(HEALBOT_HEALBOT, msg, "RAID")
    elseif hbCommsTo==3 then
        C_ChatInfo.SendAddonMessage(HEALBOT_HEALBOT, msg, "PARTY")
    end
end

function HealBot_Comms_SendAddonMessage()
    if #qAddonMsg>0 then
        local aMsg=qAddonMsg[1]
        table.remove(qAddonMsg,1)
        HealBot_AddDebug(aMsg,"Comms",true)
        
        local msg, aType, pName=string.split("~", aMsg)
        aType=tonumber(aType)
        if aType==1 then
            HealBot_Comms_SendInstantAddonMsg(msg)
        elseif aType==2 and pName then
            local xUnit=HealBot_Panel_RaidUnitName(pName)
            if xUnit and UnitExists(xUnit) and UnitIsConnected(xUnit) and UnitIsPlayer(xUnit) and UnitName(xUnit)==pName then
                HealBot_Comms_SendInstantAddonMsg(msg,2,pName)
            end
        elseif aType==3 then
            HealBot_Comms_SendInstantAddonMsg(msg,1)
        end
        --HealBot_AddDebug("comms="..aMsg)
    end
end

function HealBot_Comms_GetChan(chan)
    if GetChannelName(chan)>0 then
        return GetChannelName(chan);
    else
        return nil;
    end
end

local function HealBot_Comms_Print_IncHealsSum(sender_id,addon_id,HealsCnt,linenum)
    HealBot_Options_SetLabel("HBIncH"..linenum.."Healer",sender_id)
    HealBot_Options_SetLabel("HBIncH"..linenum.."Ver",addon_id)
end

function HealBot_Comms_About()
    local hbcommver=HealBot_GetInfo()

    local linenum=1
    for x,v in pairs(hbcommver) do
        if linenum<21 then
            HealBot_Comms_Print_IncHealsSum(x,v,0,linenum)
            linenum=linenum+1
        end
    end

    HealBot_Options_SetLabel("HealBot_Error_Clientx",HEALBOT_WORD_CLIENT..": "..GetLocale())
    if HealBot_Globals.localLang then
        HealBot_Options_SetLabel("HealBot_Error_Versionx",HEALBOT_OPTIONS_LANG..": "..HealBot_Globals.localLang)
    else
        HealBot_Options_SetLabel("HealBot_Error_Versionx",HEALBOT_OPTIONS_LANG..": "..GetLocale())
    end
    HealBot_Options_SetLabel("HealBot_Error_Classx",HEALBOT_WORD_VERSION..": "..HEALBOT_VERSION)
    HealBot_Comms_MacroSuppressError()
    HealBot_Comms_MacroSuppressSound()
end

local sPeople={}
function HealBot_Comms_Print_Supports()
    if not HEALBOT_CREDITS_PEOPLE[1] then return end
    local b=0
    for x,_ in pairs(sPeople) do
        sPeople[x]=false
    end 
    for x=1,20 do
        local s=HealBot_Globals.LastSupporter+x
        if not HEALBOT_CREDITS_PEOPLE[s] then
            b=b+1
            s=b
            if not HEALBOT_CREDITS_PEOPLE[s] then s=1 end
        end
        if not sPeople[HEALBOT_CREDITS_PEOPLE[s]] then
            HealBot_Options_SetLabel("HBIncH"..x.."Supporter",HEALBOT_CREDITS_PEOPLE[s])
            sPeople[HEALBOT_CREDITS_PEOPLE[s]]=true
        end
    end
    if HEALBOT_CREDITS_PEOPLE[21] then
        HealBot_Globals.LastSupporter=HealBot_Globals.LastSupporter+1
        local s=HealBot_Globals.LastSupporter+1
        if not HEALBOT_CREDITS_PEOPLE[s] then
            HealBot_Globals.LastSupporter=0
        end
    end
end

local mult=0
function HealBot_Comm_round(num, idp)
    mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

local HealBot_MsgUpdateAvail=nil
local hbMajor, hbMinor, hbPatch, hbHealbot = string.split(".", HEALBOT_VERSION)
local hbVersionChecked = {}
function HealBot_Comms_CheckVer(userName, version)
    if not hbVersionChecked[userName] then
        local tNewVer=nil
        hbVersionChecked[userName]=true
        local tMajor, tMinor, tPatch, tHealbot = string.split(".", version)
        if tonumber(tMajor)==HEALBOT_GAME_VERSION then
            if tonumber(tMajor)>tonumber(hbMajor) then 
                tNewVer=true
            elseif tonumber(tMajor)==tonumber(hbMajor) and tonumber(tMinor)>tonumber(hbMinor) then 
                tNewVer=true
            elseif tonumber(tMajor)==tonumber(hbMajor) and tonumber(tMinor)==tonumber(hbMinor) and tonumber(tPatch)>tonumber(hbPatch) then 
                tNewVer=true
            elseif tonumber(tMajor)==tonumber(hbMajor) and tonumber(tMinor)==tonumber(hbMinor) and tonumber(tPatch)==tonumber(hbPatch) and tonumber(tHealbot)>tonumber(hbHealbot) then 
                tNewVer=true
            end
            if tNewVer then
                hbMajor=tMajor
                hbMinor=tMinor
                hbPatch=tPatch
                hbHealbot=tHealbot
                if not HealBot_Globals.OneTimeMsg["VERSION"] then
                    HealBot_AddChat(HEALBOT_CHAT_NEWVERSION1)
                    HealBot_Globals.OneTimeMsg["VERSION"]=true
                end
                HealBot_MsgUpdateAvail = hbMajor.."."..hbMinor.."."..hbPatch.."."..hbHealbot
            end
        end
    end
end

function HealBot_Comms_MacroSuppressError()
    if HealBot_Globals.MacroSuppressError then
        HealBot_Info_SuppressErrorsVal:SetText("ON")
        HealBot_Info_SuppressErrorsVal:SetTextColor(0.1,1,0.1)
    else
        HealBot_Info_SuppressErrorsVal:SetText("OFF")
        HealBot_Info_SuppressErrorsVal:SetTextColor(0.88,0.1,0.1)
    end
end

function HealBot_Comms_MacroSuppressSound()
    if HealBot_Globals.MacroSuppressSound then
        HealBot_Info_SuppressSoundsVal:SetText("ON")
        HealBot_Info_SuppressSoundsVal:SetTextColor(0.1,1,0.1)
    else
        HealBot_Info_SuppressSoundsVal:SetText("OFF")
        HealBot_Info_SuppressSoundsVal:SetTextColor(0.88,0.1,0.1)
    end
end    

local vCPU=1
function HealBot_Comms_PerfLevel()
    if HealBot_retLuVars("CPUProfilerOn") then
        HealBot_Info_PerfLevelVal:SetText("WARNING CPU Profiling is turned ON")
        HealBot_Info_PerfLevelVal:SetTextColor(0.88,0.1,0.1)
    else
        if HealBot_Globals.UltraPerf then
            vCPU=HealBot_Globals.CPUUsage*2
            HealBot_Info_PerfLevelVal:SetText(vCPU.." <Ultra>  ["..HealBot_Globals.FPS.."fps]")
        else
            vCPU=HealBot_Globals.CPUUsage
            HealBot_Info_PerfLevelVal:SetText(vCPU.."   ["..HealBot_Globals.FPS.."fps]")
        end
        if vCPU<3 then
            HealBot_Info_PerfLevelVal:SetTextColor(0.88,0.1,0.1)
        elseif vCPU<5 then
            HealBot_Info_PerfLevelVal:SetTextColor(0.88,0.88,0.1)
        else
            HealBot_Info_PerfLevelVal:SetTextColor(0.1,1,0.1)
        end
    end
end