require "TSLib"
local ts = require("ts")

GlobalFrame = 0

BangDreamConfig = require("BangDreamConfig")
local BangDreamDriver = require("BangDreamDriver")


init(2)

--BangDreamConfig.GetAllSoundInfoType()

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
                local x,y = BangDreamConfig.GetTouchPos(touchIndex)
                touchDown(touchIndex + 1,x,y)
            end
            lastTouchTime = curTime
            curStatus = TouchStatus.e_TouchDown
            nLog('按下')
        end
    elseif(curStatus == TouchStatus.e_TouchDown) then
        if(canInput) then
            for touchIndex = 0,forCount do
                local x,y = BangDreamConfig.GetTouchPos(touchIndex)
                touchMove(touchIndex + 1,x + 10,y)
            end
            lastTouchTime = curTime
            curStatus = TouchStatus.e_TouchMove
            nLog('移动')
        end
    elseif(curStatus == TouchStatus.e_TouchMove) then
        if(canInput) then
            for touchIndex=0,forCount do
                local x,y = BangDreamConfig.GetTouchPos(touchIndex)
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
                local x,y = BangDreamConfig.GetTouchPos(touchIndex)
                TouchInstDown(touchIndex + 1,x,y)
            end
            lastTouchTime = curTime
            curStatus = TouchStatus.e_TouchDown
            nLog('按下')
        end
    elseif(curStatus == TouchStatus.e_TouchDown) then
        if(canInput) then
            for touchIndex = 0,forCount do
                local x,y = BangDreamConfig.GetTouchPos(touchIndex)
                TouchInstMove(touchIndex + 1,x + 10,y)
            end
            lastTouchTime = curTime
            curStatus = TouchStatus.e_TouchMove
            nLog('移动')
        end
    elseif(curStatus == TouchStatus.e_TouchMove) then
        if(canInput) then
            for touchIndex=0,forCount do
                local x,y = BangDreamConfig.GetTouchPos(touchIndex)
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



BangDreamDriver.Init(1,2)


local startTime = ts.ms()
local lastTime = startTime

while(true) do
    mSleep(2)
    local x,y = catchTouchPoint()
    startTime = ts.ms()
    lastTime = startTime
    break
end

while(true) do
    mSleep(2)
    GlobalFrame = GlobalFrame + 1
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