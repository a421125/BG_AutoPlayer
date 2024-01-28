local BangDreamDriver = {}
local self = BangDreamDriver

local DeviceMgr = DeviceMgr

--BPM
BangDreamDriver.curBPM = 100
--全局延迟时间
BangDreamDriver.totalDelay = 0
--所有类型按键的处理
BangDreamDriver.OptionType = {}
--可用的touchId 元素= {id = {isUsing = false, lastUseTime = 0}}
BangDreamDriver.touchPointList = {}

--BPM信息列表
BangDreamDriver.BPMInfo = {
    BPMList= {},    --bpmData = {bpm,beat,startTime}
    curBeat = 0,
    curBPMTime = 0,
    curBPM = 1,
}

--单次点击的列表
BangDreamDriver.ToExecuteSingleList = {}
--正在运行的单次点击列表
BangDreamDriver.ExecutingSingleList = {}
--单次点击的状态
local SingleTouchStatus = {
    e_Init = 0,
    e_TouchDown = 1,
    e_TouchFlick = 2,
    e_TouchUp = 3,
}
--长按的列表
BangDreamDriver.ToExecuteLongList = {}
--正在执行的长按的列表
BangDreamDriver.ExecutingLongList = {}
local LongTouchStatus = {
    e_Init = 0,
    e_TouchDown = 1,
    e_TouchFlick = 2,
    e_TouchUp = 3,
    e_Done = 4,
}

--滑动的列表
BangDreamDriver.ToExecuteSlideList = {}
BangDreamDriver.ExecutingSlideList = {}
local SlideTouchStatus = {
    e_Init = 0,
    e_TouchDown = 1,
    e_TouchFlick = 2,
    e_TouchUp = 3,
    e_Done = 4,
}

--水平滑动列表
BangDreamDriver.ToExecuteDirList = {}
BangDreamDriver.ExecutingDirList = {}
--单次点击的状态
local DirTouchStatus = {
    e_Init = 0,
    e_TouchDown = 1,
    e_TouchFlick = 2,
    e_TouchUp = 3,
}


--region 对外接口

function BangDreamDriver.Init(songId,difficulty)
    BangDreamDriver.InitOnce()
    BangDreamDriver.Reset()
    BangDreamDriver.InitMusic(songId,difficulty)
end

--endregion

--仅需要初始化一次的逻辑
function BangDreamDriver.InitOnce()
    if(self.isInitOnceFinish) then
        return
    end

    BangDreamDriver.OptionType = {
        --Slide Long System BPM Single Directional
        --长按 滑动
        Slide = {createFunc = BangDreamDriver.SlideCreate},
        --长按 不动
        Long = {createFunc = BangDreamDriver.LongCreate},
        Single = {createFunc = BangDreamDriver.SingleCreate},
        Directional = {createFunc = BangDreamDriver.DirectionCreate},
        BPM = {createFunc = BangDreamDriver.BPMCreate},
    }

    self.isInitOnceFinish = true
end

--重置模块
function BangDreamDriver.Reset()
    for i=1,10 do
        self.touchPointList[i] = {isUsing = false, lastUseTime = 0}
    end

    BangDreamDriver.TouchList = {}
    BangDreamDriver.BPMInfo = {
        BPMList= {},
        curBeat = 0,
        curBPMTime = 0,
        curBPM = 1,
    }

    BangDreamDriver.ToExecuteSingleList = {}
    BangDreamDriver.ExecutingSingleList = {}
    BangDreamDriver.ToExecuteLongList = {}
    BangDreamDriver.ExecutingLongList = {}
    BangDreamDriver.ToExecuteSlideList = {}
    BangDreamDriver.ExecutingSlideList = {}
end

function BangDreamDriver.InitMusic(songId,difficulty)
    --Slide Long System BPM Single Directional
    local songInfo = BangDreamUtils.LoadMusicInfo(songId,difficulty)
    for i=1,#songInfo do
        local curTb = songInfo[i]
        local optionTable = BangDreamDriver.OptionType[curTb.type]
        if(optionTable ~= nil) then
            optionTable.createFunc(curTb)
        end
    end

    --获取开始的延迟时间
    local curBeatData = songInfo[3]
    if(curBeatData.type == "Single" or curBeatData.type == "Directional") then
        BangDreamDriver.totalDelay = DeviceMgr.GetBeatExactTime(BangDreamDriver.BPMInfo,curBeatData.beat)
    elseif(curBeatData.type == "Long" or curBeatData.type == "Slide") then
        BangDreamDriver.totalDelay = DeviceMgr.GetBeatExactTime(BangDreamDriver.BPMInfo,curBeatData.connections[1].beat)
    end

    nLog('totalDelay为:'..BangDreamDriver.totalDelay)
end

function BangDreamDriver.Update(frameTime,sinceStartTime)
    sinceStartTime = sinceStartTime + BangDreamDriver.totalDelay
    
    BangDreamDriver.ExecutingSingleUpdate(frameTime,sinceStartTime)
    BangDreamDriver.ToExecuteSingleUpdate(frameTime,sinceStartTime)

    BangDreamDriver.ExecutingLongUpdate(frameTime,sinceStartTime)
    BangDreamDriver.ToExecuteLongUpdate(frameTime,sinceStartTime)

    BangDreamDriver.ExecutingSlideUpdate(frameTime,sinceStartTime)
    BangDreamDriver.ToExecuteSlideUpdate(frameTime,sinceStartTime)

    BangDreamDriver.ExecutingDirUpdate(frameTime,sinceStartTime)
    BangDreamDriver.ToExecuteDirUpdate(frameTime,sinceStartTime)

    if(
        #BangDreamDriver.ToExecuteSingleList == 0 and
        #BangDreamDriver.ExecutingSingleList == 0 and
        #BangDreamDriver.ToExecuteLongList == 0 and
        #BangDreamDriver.ExecutingLongList == 0 and
        #BangDreamDriver.ToExecuteSlideList == 0 and
        #BangDreamDriver.ExecutingSlideList == 0 and
        #BangDreamDriver.ToExecuteDirList == 0 and
        #BangDreamDriver.ExecutingDirList == 0
    ) then
        return true
    end

    return false
end

--region 点击模块

function BangDreamDriver.SingleCreate(beatData)
    local singleData = {}
    singleData.beat = beatData.beat
    singleData.lane = beatData.lane
    singleData.flick = beatData.flick
    singleData.time = DeviceMgr.GetBeatExactTime(BangDreamDriver.BPMInfo,beatData.beat)
    singleData.status = SingleTouchStatus.e_Init
    table.insert(self.ToExecuteSingleList,singleData)
end

--singleData 音符数据
--sinceStartTime 游戏开始至现在时间
function BangDreamDriver.ExecuteSingleData(singleData,sinceStartTime)
    if(singleData.status == SingleTouchStatus.e_Init) then
        local curFingerIndex = BangDreamDriver.GetCanUseTouchId(sinceStartTime)
        local touchX,touchY = DeviceMgr.GetTouchPos(singleData.lane)
        BangDreamDriver.touchDown(curFingerIndex,touchX,touchY,singleData.beat,sinceStartTime)
        singleData.curFingerIndex = curFingerIndex
        singleData.touchX = touchX
        singleData.touchY = touchY
        singleData.status = SingleTouchStatus.e_TouchDown
        table.insert(BangDreamDriver.ExecutingSingleList,singleData)

        singleData.flickTime = sinceStartTime 
        singleData.moveCount = 0
        return false
    elseif(singleData.status == SingleTouchStatus.e_TouchDown) then
        if(not singleData.flick) then
            singleData.status = SingleTouchStatus.e_TouchFlick
            return false
        else
            local deltaTime = (sinceStartTime - singleData.flickTime) * 1000
            if(deltaTime >= DeviceMgr.MoveFrameDtTime) then
                singleData.flickTime = sinceStartTime
                singleData.moveCount = singleData.moveCount + 1
                local targetX,targetY = DeviceMgr.GetFlickMoveTarget(singleData.lane,singleData.touchX,singleData.touchY)
                singleData.touchX = targetX
                singleData.touchY = targetY
                BangDreamDriver.touchMove(singleData.curFingerIndex,singleData.touchX,singleData.touchY,singleData.beat,sinceStartTime)
                if(singleData.moveCount >= DeviceMgr.FlickMoveCount) then
                    singleData.status = SingleTouchStatus.e_TouchFlick
                end
            end
            return false
        end
    elseif(singleData.status == SingleTouchStatus.e_TouchFlick) then
        local deltaTime = (sinceStartTime - singleData.flickTime) * 1000
        if(deltaTime >= DeviceMgr.MoveFrameDtTime) then
            BangDreamDriver.touchUp(singleData.curFingerIndex,singleData.touchX,singleData.touchY,singleData.beat,sinceStartTime)
            singleData.status = SingleTouchStatus.e_TouchUp
            BangDreamDriver.ReStoreTouchId(singleData.curFingerIndex,sinceStartTime)
            return true
        end
        return false
    end

    return true
end

function BangDreamDriver.ExecutingSingleUpdate(frameTime,sinceStartTime)
    local index = 1
    while(#self.ExecutingSingleList >= index) do
        local curData = self.ExecutingSingleList[index]
        if(curData == nil) then
            nLog('[ExecutingSingleList]Length:'..#self.ExecutingSingleList..' index:'..index)
        end
        local isFinish = self.ExecuteSingleData(curData,sinceStartTime)
        if(isFinish) then
            table.remove(self.ExecutingSingleList,index)
        else
            index = index + 1
        end
    end
end

function BangDreamDriver.ToExecuteSingleUpdate(frameTime,sinceStartTime)
    local index = 1
    while(#self.ToExecuteSingleList >= index) do
        local curData = self.ToExecuteSingleList[index]
        if(curData == nil) then
            nLog('[ToExecuteSingleList]Length:'..#self.ToExecuteSingleList..' index:'..index)
        end
        local dTime = (curData.time - sinceStartTime) * 1000
        local threhold = 14

        if(GlobalConfig.useRandomGreat) then
            local randNum = math.random(0,100)
            if(randNum > 96) then
                threhold = 40
            end
        end

        if(curData.flick) then
            threhold = 26
        end
        if(dTime >= threhold) then
            break
        end

        self.ExecuteSingleData(curData,sinceStartTime)
        table.remove(self.ToExecuteSingleList,index)
    end
end

--endregion

--region 水平滑动模块
function BangDreamDriver.DirectionCreate(beatData)
    local dirData = {}
    dirData.beat = beatData.beat
    dirData.lane = beatData.lane
    dirData.direction = beatData.direction
    dirData.time = DeviceMgr.GetBeatExactTime(BangDreamDriver.BPMInfo,beatData.beat)
    dirData.status = DirTouchStatus.e_Init
    table.insert(self.ToExecuteDirList,dirData)
end

--dirData 音符数据
--sinceStartTime 游戏开始至现在时间
function BangDreamDriver.ExecuteDirData(dirData,sinceStartTime)
    if(dirData.status == DirTouchStatus.e_Init) then
        local curFingerIndex = BangDreamDriver.GetCanUseTouchId(sinceStartTime)
        local touchX,touchY = DeviceMgr.GetTouchPos(dirData.lane)
        BangDreamDriver.touchDown(curFingerIndex,touchX,touchY,dirData.beat,sinceStartTime)
        dirData.curFingerIndex = curFingerIndex
        dirData.touchX = touchX
        dirData.touchY = touchY
        dirData.status = DirTouchStatus.e_TouchDown
        table.insert(BangDreamDriver.ExecutingDirList,dirData)

        dirData.lastOperaTime = sinceStartTime
        dirData.moveCount = 0
        return false
    elseif(dirData.status == DirTouchStatus.e_TouchDown) then
        local deltaTime = (sinceStartTime - dirData.lastOperaTime) * 1000
        if(deltaTime >= DeviceMgr.MoveFrameDtTime) then
            dirData.lastOperaTime = sinceStartTime
            dirData.moveCount = dirData.moveCount + 1
            local targetX,targetY = DeviceMgr.GetDirMoveTarget(dirData.touchX,dirData.touchY,dirData.direction == "Left")
            dirData.touchX = targetX
            dirData.touchY = targetY
            BangDreamDriver.touchMove(dirData.curFingerIndex,dirData.touchX,dirData.touchY,dirData.beat,sinceStartTime)
            if(dirData.moveCount >= DeviceMgr.FlickMoveCount) then
                dirData.status = DirTouchStatus.e_TouchFlick
            end
        end
        return false
    elseif(dirData.status == DirTouchStatus.e_TouchFlick) then
        local deltaTime = (sinceStartTime - dirData.lastOperaTime) * 1000
        if(deltaTime >= DeviceMgr.MoveFrameDtTime) then
            BangDreamDriver.touchUp(dirData.curFingerIndex,dirData.touchX,dirData.touchY,dirData.beat,sinceStartTime)
            dirData.status = DirTouchStatus.e_TouchUp
            BangDreamDriver.ReStoreTouchId(dirData.curFingerIndex,sinceStartTime)
            return true
        end
        return false
    end

    return true
end

function BangDreamDriver.ExecutingDirUpdate(frameTime,sinceStartTime)
    local index = 1
    while(#self.ExecutingDirList >= index) do
        local curData = self.ExecutingDirList[index]
        if(curData == nil) then
            nLog('[ExecutingDirList]Length:'..#self.ExecutingDirList..' index:'..index)
        end
        local isFinish = self.ExecuteDirData(curData,sinceStartTime)
        if(isFinish) then
            table.remove(self.ExecutingDirList,index)
        else
            index = index + 1
        end
    end
end

function BangDreamDriver.ToExecuteDirUpdate(frameTime,sinceStartTime)
    local index = 1
    while(#self.ToExecuteDirList >= index) do
        local curData = self.ToExecuteDirList[index]
        if(curData == nil) then
            nLog('[ToExecuteDirList]Length:'..#self.ToExecuteDirList..' index:'..index)
        end
        local dTime = (curData.time - sinceStartTime) * 1000
        local threhold = 30
        if(dTime >= threhold) then
            break
        end

        self.ExecuteDirData(curData,sinceStartTime)
        table.remove(self.ToExecuteDirList,index)
    end
end

--endregion

--region 长按模块

function BangDreamDriver.LongCreate(beatData)
    local longData = {}
    local connections = beatData.connections
    longData.beat = connections[1].beat
    longData.lane = connections[1].lane
    longData.flick = connections[2].flick
    longData.status = LongTouchStatus.e_Init
    longData.startTime = DeviceMgr.GetBeatExactTime(BangDreamDriver.BPMInfo,connections[1].beat)
    longData.endTime = DeviceMgr.GetBeatExactTime(BangDreamDriver.BPMInfo,connections[2].beat)
    table.insert(self.ToExecuteLongList,longData)
    --nLog('创建长按')
end

function BangDreamDriver.ToExecuteLongUpdate(frameTime,sinceStartTime)
    local index = 1
    while(#self.ToExecuteLongList >= index) do
        local curData = self.ToExecuteLongList[index]
        if(curData == nil) then
            nLog('[ToExecuteLongList]Length:'..#self.ToExecuteLongList..' index:'..index)
        end
        local dTime = (curData.startTime - sinceStartTime) * 1000
        --nLog('长按键  dtTime:'..dTime)
        if(dTime >= 16) then
            break
        end

        self.ExecuteLongData(curData,sinceStartTime)
        table.remove(self.ToExecuteLongList,index)
    end
end

function BangDreamDriver.ExecutingLongUpdate(frameTime,sinceStartTime)
    local index = 1
    while(#self.ExecutingLongList >= index) do
        local curData = self.ExecutingLongList[index]
        if(curData == nil) then
            nLog('[ExecutingLongList]Length:'..#self.ExecutingLongList..' index:'..index)
        end
        local isFinish = self.ExecuteLongData(curData,sinceStartTime)
        if(isFinish) then
            table.remove(self.ExecutingLongList,index)
        else
            index = index + 1
        end
    end
end

function BangDreamDriver.ExecuteLongData(longData,sinceStartTime)
    if(longData.status == LongTouchStatus.e_Init) then
        local curFingerIndex = BangDreamDriver.GetCanUseTouchId(sinceStartTime)
        local touchX,touchY = DeviceMgr.GetTouchPos(longData.lane)
        BangDreamDriver.touchDown(curFingerIndex,touchX,touchY,longData.beat,sinceStartTime)
        -- nLog('长按:  按下')

        --按下的时间
        longData.lastOperaTime = sinceStartTime
        longData.curFingerIndex = curFingerIndex
        longData.touchX = touchX
        longData.touchY = touchY
        longData.status = LongTouchStatus.e_TouchDown
        table.insert(BangDreamDriver.ExecutingLongList,longData)
        return false
    elseif(longData.status == LongTouchStatus.e_TouchDown) then
        local finishDeltaTime = (longData.endTime - sinceStartTime) * 1000
        if(not longData.flick and finishDeltaTime <= 10) then
            longData.status = LongTouchStatus.e_TouchUp
        end
        if(longData.flick and finishDeltaTime <= 18) then
            longData.status = LongTouchStatus.e_TouchFlick
            longData.moveCount = 1
        end
        return false
    elseif(longData.status == LongTouchStatus.e_TouchFlick) then
        local lastOperaDuration = (sinceStartTime - longData.lastOperaTime) * 1000
        if(lastOperaDuration < DeviceMgr.MoveFrameDtTime) then
            return false
        end

        local targetX,targetY = DeviceMgr.GetFlickMoveTarget(longData.lane,longData.touchX,longData.touchY)
        longData.touchX = targetX
        longData.touchY = targetY
        BangDreamDriver.touchMove(longData.curFingerIndex,longData.touchX,longData.touchY,longData.beat,sinceStartTime)
        longData.moveCount = longData.moveCount - 1
        longData.lastOperaTime = sinceStartTime
        if(longData.moveCount <= 0) then
            longData.lastOperaTime = sinceStartTime
            longData.status = LongTouchStatus.e_TouchUp
        end
        return false
    elseif(longData.status == LongTouchStatus.e_TouchUp) then
        local lastOperaDuration = (sinceStartTime - longData.lastOperaTime) * 1000
        if(lastOperaDuration < DeviceMgr.MoveFrameDtTime) then
            return false
        end

        BangDreamDriver.touchUp(longData.curFingerIndex,longData.touchX,longData.touchY,longData.beat,sinceStartTime)
        -- nLog('长按:  抬起')
        longData.status = LongTouchStatus.e_Done
        BangDreamDriver.ReStoreTouchId(longData.curFingerIndex,sinceStartTime)
        return true
    end

    return false
end

--endregion

--region 滑动模块
function BangDreamDriver.SlideCreate(beatData)
    local slideData = {}
    slideData.beat = beatData.connections[1].beat
    slideData.connections = {}
    for i=1,#beatData.connections do
        local curData = beatData.connections[i]
        local curNode = {}
        curNode.lane = curData.lane
        curNode.time = DeviceMgr.GetBeatExactTime(BangDreamDriver.BPMInfo,curData.beat)
        curNode.beat = curData.beat
        table.insert(slideData.connections,curNode)
    end
    slideData.flick = beatData.connections[#beatData.connections].flick
    slideData.status = SlideTouchStatus.e_Init
    slideData.lastOperaTime = 0
    table.insert(self.ToExecuteSlideList,slideData)
end

function BangDreamDriver.ExecutingSlideUpdate(frameTime,sinceStartTime)
    local index = 1
    while(#self.ExecutingSlideList >= index) do
        local curData = self.ExecutingSlideList[index]
        if(curData == nil) then
            nLog('[ExecutingSlideList]Length:'..#self.ExecutingSlideList..' index:'..index)
        end
        local isFinish = self.ExecuteSlideData(curData,sinceStartTime)
        if(isFinish) then
            table.remove(self.ExecutingSlideList,index)
        else
            index = index + 1
        end
    end
end

function BangDreamDriver.ToExecuteSlideUpdate(frameTime,sinceStartTime)
    local index = 1
    while(#self.ToExecuteSlideList >= index) do
        local curData = self.ToExecuteSlideList[index]
        if(curData == nil) then
            nLog('[ToExecuteSlideList]Length:'..#self.ToExecuteSlideList..' index:'..index)
        end
        local dTime = (curData.connections[1].time - sinceStartTime) * 1000
        if(dTime >= 16) then
            break
        end

        self.ExecuteSlideData(curData,sinceStartTime)
        table.remove(self.ToExecuteSlideList,index)
    end
end

function BangDreamDriver.ExecuteSlideData(slideData,sinceStartTime)
    if(slideData.status == SlideTouchStatus.e_Init) then
        local curFingerIndex = BangDreamDriver.GetCanUseTouchId(sinceStartTime)
        local touchX,touchY = DeviceMgr.GetTouchPos(slideData.connections[1].lane)
        BangDreamDriver.touchDown(curFingerIndex,touchX,touchY,slideData.connections[1].beat,sinceStartTime)
        slideData.lastOperaTime = sinceStartTime
        slideData.curFingerIndex = curFingerIndex
        slideData.touchX = touchX
        slideData.touchY = touchY
        slideData.status = SlideTouchStatus.e_TouchDown
        slideData.connectIndex = 1
        table.insert(BangDreamDriver.ExecutingSlideList,slideData)
        return false
    elseif(slideData.status == SlideTouchStatus.e_TouchDown) then
        local operaDtTime = (sinceStartTime - slideData.lastOperaTime) * 1000
        if(operaDtTime < DeviceMgr.MoveFrameDtTime) then
            return false
        end

        --首先找到第一个未到时间的节点
        local result = -1
        local maxIndex = #slideData.connections
        for i=maxIndex,slideData.connectIndex,-1 do
            local curData = slideData.connections[i]
            if(curData.time < sinceStartTime) then
                result = i
                break
            end
        end

        if(result == slideData.connectIndex) then
            return false
        end

        slideData.connectIndex = result

        --然后进行下次滑动点的位置计算
        local curBeatData = slideData.connections[slideData.connectIndex]
        local touchX,touchY = DeviceMgr.GetTouchPos(curBeatData.lane)
        BangDreamDriver.touchMove(slideData.curFingerIndex,touchX,touchY,curBeatData.beat,sinceStartTime)
        slideData.lastOperaTime = sinceStartTime
        slideData.touchX = touchX
        slideData.touchY = touchY
        if(slideData.connectIndex == #slideData.connections) then
            if(curBeatData.flick) then
                slideData.status = SlideTouchStatus.e_TouchFlick
            else
                slideData.status = SlideTouchStatus.e_TouchUp
            end
        end
        return false
    elseif(slideData.status == SlideTouchStatus.e_TouchFlick) then
        local operaDtTime = (sinceStartTime - slideData.lastOperaTime) * 1000
        if(operaDtTime < DeviceMgr.MoveFrameDtTime) then
            return false
        end

        local curBeatData = slideData.connections[#slideData.connections]
        local targetX,targetY = DeviceMgr.GetFlickMoveTarget(curBeatData.lane,slideData.touchX,slideData.touchY)
        slideData.touchX = targetX
        slideData.touchY = targetY
        BangDreamDriver.touchMove(slideData.curFingerIndex,slideData.touchX,slideData.touchY,curBeatData.beat,sinceStartTime)
        slideData.lastOperaTime = sinceStartTime
        slideData.status = SlideTouchStatus.e_TouchUp

        return false
    elseif(slideData.status == SlideTouchStatus.e_TouchUp) then
        local operaDtTime = (sinceStartTime - slideData.lastOperaTime) * 1000
        if(operaDtTime < DeviceMgr.MoveFrameDtTime) then
            return false
        end

        local curBeatData = slideData.connections[#slideData.connections]
        BangDreamDriver.touchUp(slideData.curFingerIndex,slideData.touchX,slideData.touchY,curBeatData.beat,sinceStartTime)
        slideData.status = SlideTouchStatus.e_Done
        BangDreamDriver.ReStoreTouchId(slideData.curFingerIndex,sinceStartTime)

        return true
    end

    return false
end

--endregion

function BangDreamDriver.BPMCreate(beatData)
    local BPMInfo = BangDreamDriver.BPMInfo

    local bpmData = {
        bpm = beatData.bpm,
        beat = beatData.beat,
        startTime = BPMInfo.curBPMTime
    }

    BPMInfo.curBPMTime = 60 / BPMInfo.curBPM * (bpmData.beat - BPMInfo.curBeat) + BPMInfo.curBPMTime
    BPMInfo.curBeat = bpmData.beat
    BPMInfo.curBPM = bpmData.bpm
    bpmData.startTime = BPMInfo.curBPMTime

    table.insert(BPMInfo.BPMList,bpmData)

    nLog('BPM信息 BPMTime:'..bpmData.startTime..' Beat:'..bpmData.beat)
end

--region 手指id管理
function BangDreamDriver.GetCanUseTouchId(sinceStartTime)
    for i=1,10 do
        local curFingerData = self.touchPointList[i]
        if(not curFingerData.isUsing) then
            local deltaTime = math.floor((sinceStartTime - curFingerData.lastUseTime) * 1000)
            if(deltaTime > 30) then
                curFingerData.isUsing = true
                return i
            end
        end
    end

    nLog('获取可用手指id失败')
    return -1
end

function BangDreamDriver.ReStoreTouchId(id,sinceStartTime)
    local curFingerData = self.touchPointList[id]
    if(curFingerData.isUsing == false) then
        nLog('[BangDreamDriver]:ReStoreTouchId有问题 id已被释放:'..id)
    end

    curFingerData.lastUseTime = sinceStartTime
    curFingerData.isUsing = false
end
--endregion

local globalDebug = true

--region touch输入
function BangDreamDriver.touchDown(fingerIndex,x,y,beatIndex,sinceStartTime,openDebug)
    local startTime = os.clock()
    touchDown(fingerIndex,x,y)
    local executeTime = math.floor((os.clock() - startTime) * 1000)
    if(openDebug or globalDebug) then
        -- nLog('按下 手指id:'..fingerIndex..' x:'..x..' y:'..y..' beatIndex:'..beatIndex..' startTime:'..sinceStartTime)
        local deltaTime = math.floor((sinceStartTime - BangDreamDriver.totalDelay) * 1000)
        -- nLog('按下 手指id:'..fingerIndex..' beatIndex:'..beatIndex..' playTime:'..deltaTime)
    end
end

function BangDreamDriver.touchMove(fingerIndex,x,y,beatIndex,sinceStartTime,openDebug)
    local startTime = os.clock()
    touchMove(fingerIndex,x,y)
    local executeTime = math.floor((os.clock() - startTime) * 1000)
    if(openDebug or globalDebug) then
        -- nLog('移动 手指id:'..fingerIndex..' x:'..x..' y:'..y..' beatIndex:'..beatIndex..' startTime:'..sinceStartTime)
        local deltaTime = math.floor((sinceStartTime - BangDreamDriver.totalDelay) * 1000)
        -- nLog('移动 手指id:'..fingerIndex..' beatIndex:'..beatIndex..' playTime:'..deltaTime)
    end
end

function BangDreamDriver.touchUp(fingerIndex,x,y,beatIndex,sinceStartTime,openDebug)
    local startTime = os.clock()
    touchUp(fingerIndex,x,y)
    local executeTime = math.floor((os.clock() - startTime) * 1000)
    if(openDebug or globalDebug) then
        -- nLog('抬起 手指id:'..fingerIndex..' x:'..x..' y:'..y..' beatIndex:'..beatIndex..' startTime:'..sinceStartTime)
        local deltaTime = math.floor((sinceStartTime - BangDreamDriver.totalDelay) * 1000)
        -- nLog('抬起 手指id:'..fingerIndex..' beatIndex:'..beatIndex..' playTime:'..deltaTime)
    end
end
--endregion


return BangDreamDriver