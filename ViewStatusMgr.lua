local ViewStatusMgr = {}
local self = ViewStatusMgr

local BangDreamDriver = require("BangDreamDriver")

local eGameStatus = {
    e_Init = 1,
    e_MusicInfoView = 2,
    e_WaitPlay = 3,
    e_StartPlay = 4,
    e_DirverRunning = 5,
    e_CheckPlay = 6,
}
local curStatus = eGameStatus.e_Init

local MusicStartFirstLine = 0
local lastUpdateTime = 0

local MusicStartTime = 0
local MusicLastTime = 0

function ViewStatusMgr.Update()
    local curTime = ts.ms()
    local deltaTime = math.floor((curTime - lastUpdateTime) * 1000)
    -- nLog('延迟为:'..deltaTime)
    --nLog('当前状态:'..curStatus)
    lastUpdateTime = curTime

    if(curStatus == eGameStatus.e_Init) then
        if(not ViewStatusMgr.IsMusicInfoStatus()) then
            return
        end

        curStatus = eGameStatus.e_MusicInfoView
        local difficultId = DeviceMgr.GetMusicDifficult()
        local musicId = DeviceMgr.GetJacketListByRectId()
        nLog('难度为:'..difficultId..' 歌曲id:'..musicId)

        BangDreamDriver.Init(musicId,difficultId)
        MusicStartFirstLine = DeviceMgr.GetMusicFirstLane(musicId,difficultId)
        nLog('MusicStartFirstLine:'..MusicStartFirstLine)
        nLog('进入歌曲信息界面')
    elseif(curStatus == eGameStatus.e_MusicInfoView) then
        if(ViewStatusMgr.IsGameStartStatus()) then
            curStatus = eGameStatus.e_WaitPlay
        end
    elseif(curStatus == eGameStatus.e_WaitPlay) then
        if(ViewStatusMgr.IsGameReadyStatus()) then
            curStatus = eGameStatus.e_StartPlay
        end
    elseif(curStatus == eGameStatus.e_StartPlay) then
        local isEnter,timeOffset,checkTime = ViewStatusMgr.IsFirstNoteEnter()
        if(isEnter) then
            curStatus = eGameStatus.e_DirverRunning
            MusicStartTime =  ts.ms()
            MusicStartTime = MusicStartTime - checkTime + GlobalConfig.correctionDelay + timeOffset
            MusicLastTime = MusicStartTime
        end
    elseif(curStatus == eGameStatus.e_DirverRunning) then
        local curTime = ts.ms()
        local sinceStartTime = curTime - MusicStartTime
        local deltaTime = curTime - MusicLastTime
        MusicLastTime = curTime

        -- nLog('sinceStartTime:'..math.floor(sinceStartTime * 1000))
        if(deltaTime * 1000 > 20) then
            -- nLog('Update耗时高:'..(deltaTime * 1000))
        end

        local isFinish = BangDreamDriver.Update(deltaTime,sinceStartTime)
        if(isFinish) then
            collectgarbage("collect")
            curStatus = eGameStatus.e_CheckPlay
        end
    elseif(curStatus == eGameStatus.e_CheckPlay) then
        -- nLog('处于检测play阶段')
        if(ViewStatusMgr.CheckCanClickPlay()) then
            curStatus = eGameStatus.e_Init
        end
    end
end

--检测是否在歌曲信息界面
function ViewStatusMgr.IsMusicInfoStatus()
    local curConfig1 = DeviceMgr.ColorList[2]
    local color1 = getColor(curConfig1.pos.x,curConfig1.pos.y)
    local curConfig2 = DeviceMgr.ColorList[1]
    local color2 = getColor(curConfig2.pos.x,curConfig2.pos.y)
    --nLog('位置1:'..curConfig1.pos.x..' '..curConfig1.pos.y..' 颜色:'..color1)
    --nLog('位置2:'..curConfig2.pos.x..' '..curConfig2.pos.y..' 颜色:'..color2)
    if(color1 == curConfig1.color and color2 == curConfig2.color) then
        return true
    end

    return false
end

--检测歌曲信息界面关闭,游戏面板未打开的状态
function ViewStatusMgr.IsGameStartStatus()
    local curConfig = DeviceMgr.ColorList[3]
    local color1 = getColor(curConfig.pos.x,curConfig.pos.y)
    if(color1 == curConfig.color) then
        return true
    end

    return false
end

--检测游戏开始后点击栏显示出来后的状态
function ViewStatusMgr.IsGameReadyStatus()
    local curConfig = DeviceMgr.ColorList[4]
    local color1 = getColor(curConfig.pos.x,curConfig.pos.y)
    if(color1 == curConfig.color) then
        return true
    end

    return false
end

--检测游戏开始后 第一个音符是否已经到了 用于校准游戏时间
function ViewStatusMgr.IsFirstNoteEnter()
    local startCheckTime = ts.ms()

    keepScreen(true)

    local x,y = DeviceMgr.GetChickStartPos(MusicStartFirstLine)

    local colorList = {}
    local stepCount = 7
    local halfStepCount = math.floor(stepCount / 2)
    for i=1,stepCount do
        local curColor = getColor(x,y - 10 * (i - halfStepCount))
        -- nLog('获取颜色为:'..curColor)
        table.insert(colorList,curColor)
    end

    local targetColor = DeviceMgr.GetChickStartColor()

    local marchList = {}
    local marchNum = 0
    local marchStr = ''
    local equalCount = 0
    for i=1,stepCount do
        local curColor = colorList[i]
        local isEqual = math.abs(curColor - targetColor) > 5
        marchStr = marchStr..(isEqual and 1 or 0)
        equalCount = equalCount + (isEqual and 1 or 0)
        marchList[i] = isEqual and 1 or 0
    end

    for i=1,stepCount do
        if(marchList[i] == 0) then
            marchNum = marchNum - 1
        else
            break
        end
    end

    for i=stepCount,1,-1 do
        if(marchList[i] == 0) then
            marchNum = marchNum + 1
        else
            break
        end
    end

    -- local offsetTime = 0.1 -marchNum / 2 * 0.01
    local offsetTime =  -marchNum / 2 * 0.01
    -- local offsetTime = 0

    if(equalCount == 0) then
        return false
    end

    keepScreen(false)

    -- local checkTime = ts.ms() - startCheckTime
    checkTime = 0
    local checkTimeInt = math.floor((checkTime) * 1000)
    nLog('第一个node检测march:'..marchStr..' marchNum为:'..marchNum..' offsetTime:'..offsetTime..' 检查时间为:'..checkTimeInt)
    return true,offsetTime,checkTime
end

--检测是否能点击开始打歌
function ViewStatusMgr.CheckCanClickPlay()
    keepScreen(true)

    local curConfig1 = DeviceMgr.ColorList[5]
    local curConfig2 = DeviceMgr.ColorList[6]
    local screenColor1 = getColor(curConfig1.pos.x,curConfig1.pos.y)
    local screenColor2 = getColor(curConfig2.pos.x,curConfig2.pos.y)

    keepScreen(false)

    -- nLog('screenColor1:'..screenColor1..' configColor1:'..curConfig1.color)
    -- nLog('screenColor2:'..screenColor2..' configColor2:'..curConfig2.color)
    if(screenColor1 == curConfig1.color and screenColor2 == curConfig2.color) then
        local touchX,touchY = DeviceMgr.GetClickPlayPos()
        tap(touchX,touchY)
        return true
    else
        return false
    end
end

return ViewStatusMgr