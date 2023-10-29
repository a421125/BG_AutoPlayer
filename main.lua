require "TSLib"
local ts = require("ts")

BangDreamUtils = require("BangDreamUtils")
DeviceMgr = require("DeviceMgr")
DeviceMgr.InitByDeviceType(3)
local BangDreamDriver = require("BangDreamDriver")

--模拟器为2 手机为1 起点为左上角  x水平 y向下
init(DeviceMgr.GetInitDir())

-- while(true) do
--     touchDown(300,100)
--     touchUp(300,100)
--     mSleep(100)
-- end


--region ---------------------------------------测试touchDown/touchUp/touchMove start------------------------------------------------------
--[[

local lastRecordTime = 0
function LogSleep(sleepTime)
    local curTime = ts.ms()
    mSleep(sleepTime)
    local deltaTime = (curTime - lastRecordTime) * 1000
    if(deltaTime > 20) then
        nLog('延迟超标:'..deltaTime)
    end
    lastRecordTime = curTime
end

local TouchStatus = {
    e_Init = 0,
    e_TouchDown = 1,
    e_TouchMove = 2,
    e_TouchUp = 3,    
}

local curStatus = TouchStatus.e_Init
local lastTouchTime = ts.ms()
local forCount = 1

while(true) do
    LogSleep(2)

    local curTime = ts.ms()
    local canInput = (curTime - lastTouchTime) * 1000 >= 40

    if(curStatus == TouchStatus.e_Init) then
        if(canInput) then
            for touchIndex=0,forCount do
                local x,y = DeviceMgr.GetTouchPos(touchIndex)
                touchDown(touchIndex + 1,x,y)
            end
            lastTouchTime = curTime
            curStatus = TouchStatus.e_TouchDown
            nLog('按下')
        end
    elseif(curStatus == TouchStatus.e_TouchDown) then
        if(canInput) then
            for touchIndex = 0,forCount do
                local x,y = DeviceMgr.GetTouchPos(touchIndex)
                touchMove(touchIndex + 1,x + 10,y)
            end
            lastTouchTime = curTime
            curStatus = TouchStatus.e_TouchMove
            nLog('移动')
        end
    elseif(curStatus == TouchStatus.e_TouchMove) then
        if(canInput) then
            for touchIndex=0,forCount do
                local x,y = DeviceMgr.GetTouchPos(touchIndex)
                touchUp(touchIndex + 1,x + 10,y)
            end
            lastTouchTime = curTime
            curStatus = TouchStatus.e_TouchUp
            nLog('抬起')
        end
    elseif(curStatus == TouchStatus.e_TouchUp) then
        if(canInput) then
            curStatus = TouchStatus.e_Init
        end
    end
end

if(true) then
    return
end

--]]

--endregion ---------------------------------------测试touchDown/touchUp/touchMove end------------------------------------------------------

--region ---------------------------------------测试touch类 start------------------------------------------------------
--[[
local lastRecordTime = 0
function LogSleep(sleepTime)
    local curTime = ts.ms()
    mSleep(sleepTime)
    local deltaTime = (curTime - lastRecordTime) * 1000
    if(deltaTime > 20) then
        nLog('延迟超标:'..deltaTime)
    end
    lastRecordTime = curTime
end

local touchDic = {}
function GetTouchInst(index)
    local touchInst = touchDic[index]
    if(touchInst == nil) then
        touchInst = touch(index)
        touchDic[index] = touchInst
    end

    return touchInst
end

function TouchInstDown(index,x,y)
    local inst = GetTouchInst(index)
    inst = inst:on(x,y)
    touchDic[index] = inst
end

function TouchInstMove(index,x,y)
    local inst = GetTouchInst(index)
    inst = inst:Step(49):move(x,y)
    touchDic[index] = inst
end

function TouchInstUp(index)
    local inst = GetTouchInst(index)
    inst:off()
    touchDic[index] = nil 
end

local TouchStatus = {
    e_Init = 0,
    e_TouchDown = 1,
    e_TouchMove = 2,
    e_TouchUp = 3,    
}

local curStatus = TouchStatus.e_Init
local lastTouchTime = ts.ms()
local forCount = 0

while(true) do
    LogSleep(2)

    local curTime = ts.ms()
    local canInput = (curTime - lastTouchTime) * 1000 >= 40

    if(curStatus == TouchStatus.e_Init) then
        if(canInput) then
            for touchIndex=0,forCount do
                local x,y = DeviceMgr.GetTouchPos(touchIndex)
                TouchInstDown(touchIndex + 1,x,y)
            end
            lastTouchTime = curTime
            curStatus = TouchStatus.e_TouchDown
            nLog('按下')
        end
    elseif(curStatus == TouchStatus.e_TouchDown) then
        if(canInput) then
            for touchIndex = 0,forCount do
                local x,y = DeviceMgr.GetTouchPos(touchIndex)
                TouchInstMove(touchIndex + 1,x + 10,y)
            end
            lastTouchTime = curTime
            curStatus = TouchStatus.e_TouchMove
            nLog('移动')
        end
    elseif(curStatus == TouchStatus.e_TouchMove) then
        if(canInput) then
            for touchIndex=0,forCount do
                local x,y = DeviceMgr.GetTouchPos(touchIndex)
                TouchInstUp(touchIndex + 1)
            end
            lastTouchTime = curTime
            curStatus = TouchStatus.e_TouchUp
            nLog('抬起')
        end
    elseif(curStatus == TouchStatus.e_TouchUp) then
        if(canInput) then
            curStatus = TouchStatus.e_Init
        end
    end
end

if(true) then
    return
end

--]]

--endregion ---------------------------------------测试touch类 end--------------------------------------------------------

--region-------------------测试滑动----------------------------

-- touchDown(1,220,210)
-- touchDown(2,220,420)
-- mSleep(20)
-- touchMove(1,240,210)
-- touchMove(2,240,420)
-- mSleep(20)
-- touchMove(1,260,210)
-- touchMove(2,260,420)
-- mSleep(20)
-- touchUp(1,260,210)
-- touchUp(2,260,420)

-- local downStr = 'sendevent /dev/input/event4 1 330 1;sendevent /dev/input/event4 3 58 1;sendevent /dev/input/event4 3 53 400;sendevent /dev/input/event4 3 54 400;sendevent /dev/input/event4 0 2 0;sendevent /dev/input/event4 0 0 0;'
-- local upStr = 'sendevent /dev/input/event4 1 330 0;sendevent /dev/input/event4 0 2 0;sendevent /dev/input/event4 0 0 0;'

-- local curTime = ts.ms()
-- os.execute(downStr)
-- local deltaTime = ts.ms() - curTime
-- nLog('延迟为:'..deltaTime)

-- mSleep(20)

-- local curTime = ts.ms()
-- os.execute(upStr)
-- local deltaTime = ts.ms() - curTime
-- nLog('延迟为:'..deltaTime)

-- local curTime = ts.ms()
-- touchDown(400,400)
-- local deltaTime = ts.ms() - curTime
-- nLog('延迟为:'..deltaTime)

-- local curTime = ts.ms()
-- touchUp(400,400)
-- local deltaTime = ts.ms() - curTime
-- nLog('延迟为:'..deltaTime)

-- if(true) then
--     return
-- end

--endregion-------------------end测试滑动-------------------------

--region-------------测试取色----------------------------

local eViewStatus = {
    e_Init = 1,
    e_MusicInfoView = 2,
    e_WaitPlay = 3,
    e_StartPlay = 4,
}

local firstLane = 0
local lastTime = 0
local startTime = 0
local curStatus = eViewStatus.e_Init

while(true) do
    local curTime = ts.ms()
    local deltaTime = math.floor((curTime - lastTime) * 1000)
    -- nLog('延迟为:'..deltaTime)
    --nLog('当前状态:'..curStatus)
    lastTime = curTime

    if(curStatus == eViewStatus.e_Init) then
        local curConfig1 = DeviceMgr.ColorList[2]
        local color1 = getColor(curConfig1.pos.x,curConfig1.pos.y)
        local curConfig2 = DeviceMgr.ColorList[1]
        local color2 = getColor(curConfig2.pos.x,curConfig2.pos.y)
        --nLog('位置1:'..curConfig1.pos.x..' '..curConfig1.pos.y..' 颜色:'..color1)
        --nLog('位置2:'..curConfig2.pos.x..' '..curConfig2.pos.y..' 颜色:'..color2)
        if(color1 == curConfig1.color and color2 == curConfig2.color) then
            curStatus = eViewStatus.e_MusicInfoView
            local difficultId = DeviceMgr.GetMusicDifficult()
            local musicId = DeviceMgr.GetJacketListByRectId()
            nLog('难度为:'..difficultId..' 歌曲id:'..musicId)
            BangDreamDriver.Init(musicId,difficultId)
            firstLane = DeviceMgr.GetMusicFirstLane(musicId,difficultId)
            nLog('firstLane:'..firstLane)
            nLog('进入歌曲信息界面')
        end
    elseif(curStatus == eViewStatus.e_MusicInfoView) then
        local curConfig = DeviceMgr.ColorList[3]
        local color1 = getColor(curConfig.pos.x,curConfig.pos.y)
        if(color1 == curConfig.color) then
            curStatus = eViewStatus.e_WaitPlay
            nLog('游戏前等待状态')
        end
    elseif(curStatus == eViewStatus.e_WaitPlay) then
        local curConfig = DeviceMgr.ColorList[4]
        local color1 = getColor(curConfig.pos.x,curConfig.pos.y)
        if(color1 == curConfig.color) then
            curStatus = eViewStatus.e_StartPlay
            nLog('进入游戏状态')
        end
    elseif(curStatus == eViewStatus.e_StartPlay) then
        --检测对应第一个音符时间
        local x,y = DeviceMgr.GetChickStartPos(firstLane)
        local color = getColor(x,y)
        --nLog('检测位置:'..x..' '..y..' 颜色:'..color)
        local curConfig = DeviceMgr.ColorList[5]
        if(color ~= curConfig.color) then
            --nLog('检测到第一个音符:'..curTime)
            break
        end
    end

    mSleep(1)
end

--endregion

-- while(true) do
--     mSleep(2)
--     local x,y = catchTouchPoint()
--     local curTime = ts.ms()
--     local deltaTime = curTime - startTime
--     nLog('时间差为:'..math.floor(deltaTime * 1000))
--     startTime = curTime
--     lastTime = startTime
--     break
-- end

mSleep(0)

startTime = ts.ms()
lastTime = startTime

while(true) do
    mSleep(2)
    local curTime = ts.ms()
    local deltaTime = curTime - lastTime
    lastTime = curTime
    local sinceStartTime = curTime - startTime

    local intDtTime = math.floor(deltaTime * 1000)
    if(intDtTime > 10) then
        nLog('deltaTime:'..intDtTime)
    end

    BangDreamDriver.Update(deltaTime,sinceStartTime)
end