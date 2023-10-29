local DeviceMgr = {}

--目前已经配置的设备类型列表
DeviceMgr.DeviceTypeList = {
    [1] = {name = 'NoxSimulator',fileName = 'NoxSimulator_Config',ColorCheckName = "Redmi_K30_Config"},
    [2] = {name = 'Redmi_K30',fileName = 'Redmi_K30_Config',ColorCheckName = "Redmi_K30_Config"},
    [3] = {name = 'Redmi_K30',fileName = 'Redmi_K30_Config_v7',ColorCheckName = "Redmi_K30_Config"},
}

--具体设备的配置信息
local DeviceConfig = nil
--设备相关的歌曲封面颜色信息
local JacketColorConfig = nil

--TODO 暂时把颜色信息记录在这里，之后删除
DeviceMgr.ColorList = nil

--滑动时的滑动多少检测帧
DeviceMgr.FlickMoveCount = 1
--滑动时的间隔时间
DeviceMgr.MoveFrameDtTime = 20

--初始化，绑定设备配置
function DeviceMgr.InitByDeviceType(deviceType)
    local deviceInfo = DeviceMgr.DeviceTypeList[deviceType]
    if(deviceInfo == nil) then
        nLog('[DeviceMgr] 初始化的设备类型配置找不到:' + deviceType)
    end

    DeviceConfig = DeviceMgr.LoadLuaFile('DeviceConfig',deviceInfo.fileName)
    if(not DeviceConfig) then
        return false
    end
    DeviceMgr.ColorList = DeviceConfig.ColorList

    JacketColorConfig = DeviceMgr.LoadLuaFile('ColorCheckConfig',deviceInfo.ColorCheckName)

    return true
end

--加载lua文件
function DeviceMgr.LoadLuaFile(dirPath,filePath)
    local fileFullPath = userPath().."/lua/"..dirPath..'/'..filePath..'.lua'
    local isExist = isFileExist(fileFullPath)
    if(not isExist) then
        nLog('[DeviceMgr]加载lua文件失败 设备配置文件不存在:'..fileFullPath)
        return false
    end

    local luaPath = dirPath..'.'..filePath
    local data = require(luaPath)
    return data
end

--获取初始化触动方向的id
function DeviceMgr.GetInitDir()
    return DeviceConfig.InitDir
end

--获取滑动时的目标位置
function DeviceMgr.GetFlickMoveTarget(lane,x,y)
    return x,y + 40
end

--通过BPM和beat来获取当前beat的准确时间
function DeviceMgr.GetExactTime(BPM,beatIndex)
    if(beatIndex == nil) then
        nLog('[DeviceMgr] 传入beatInde为nil:'..debug.traceback())
    end
    
    local time = 60 / BPM * beatIndex
    return time
end

function DeviceMgr.GetBeatExactTime(BPMInfo,beatIndex)
    local result = 0
    --说明是当前数据往后找
    if(beatIndex >= BPMInfo.curBeat) then
        result = 60 / BPMInfo.curBPM * (beatIndex - BPMInfo.curBeat) + BPMInfo.curBPMTime
    else    --这里说明要从头开始找
        local BPMList = BPMInfo.BPMList
        for i=1,#BPMList do
            local curBPMInfo = BPMList[i]
            if(beatIndex >= curBPMInfo.beat) then
                result = 60 / curBPMInfo.bpm * (beatIndex - curBPMInfo.beat) + curBPMInfo.startTime
            end
        end
    end

    --nLog('计算时间 beat:'..beatIndex..' 时间:'..result)
    return result
end

--获取第一个按键的位置
function DeviceMgr.GetMusicFirstLane(songId,difficulty)
    local songInfo = BangDreamUtils.LoadMusicInfo(songId,difficulty)

    local curBeatData = songInfo[3]
    if(curBeatData.type == "Single" or curBeatData.type == "Directional") then
        return curBeatData.lane
    elseif(curBeatData.type == "Long" or curBeatData.type == "Slide") then
        return curBeatData.connections[1].lane
    end

    return 0
end

function DeviceMgr.GetChickStartPos(index)
    return DeviceConfig.GetChickStartPos(index)
end

function DeviceMgr.GetTouchPos(index)
    return DeviceConfig.GetTouchPos(index)
end

----在歌曲页面找歌曲id
--idList:传入的已经过滤的歌曲id
function DeviceMgr.GetJacketListByRectId()
    local JacketLeftTopPos = DeviceConfig.JacketLeftTopPos
    local totalClientColorList = {}

    for i=1,#DeviceConfig.RectCheckList do
        local curRect = DeviceConfig.RectCheckList[i]
        if(curRect == nil or JacketLeftTopPos == nil) then
            nLog('[DeviceMgr] GetJacketListByRectId失败: leftTopPos为nil 或 rect为nil')
            return false
        end
    
        local startPosX = JacketLeftTopPos.x + curRect.x
        local startPosY = JacketLeftTopPos.y + curRect.y
        local clientColorList = DeviceMgr.GetClientColorList(startPosX,startPosY,curRect.width,curRect.height)
        table.insert(totalClientColorList,clientColorList)
    end

    local jacketSelectList = {}

    local clientColorList1 = totalClientColorList[1]
    for jacketName,jacketData in pairs(JacketColorConfig) do
        local colorRect = jacketData[1]
        local rectDif = 0
        for i=1,#clientColorList1 do
            local difValue = DeviceMgr.CalcColorDif(colorRect[i],clientColorList1[i])
            rectDif = rectDif + difValue
        end

        table.insert(jacketSelectList,{name = jacketName, dif = rectDif})
    end

    table.sort(jacketSelectList,function(a,b)
        return a.dif < b.dif
    end)

    nLog('[找歌] 第一轮 第一个为:'..jacketSelectList[1].name..' 差异为:'..jacketSelectList[1].dif)
    local lastIndex = #jacketSelectList
    nLog('[找歌] 第一轮 最后一个为:'..jacketSelectList[lastIndex].name..' 差异为:'..jacketSelectList[lastIndex].dif)

    local round1List = {}
    for i=1,10 do
        local jacketData = jacketSelectList[i]
        if(jacketData) then
            table.insert(round1List,jacketData)
        end
    end

    for i=2,#totalClientColorList do
        local curColorList = totalClientColorList[i]
        for jacketIndex=1,#round1List do
            local curJackeData = round1List[jacketIndex]
            local colorRect = JacketColorConfig[curJackeData.name][i]
            for colorIndex=1,#colorRect do
                local difValue = DeviceMgr.CalcColorDif(colorRect[colorIndex],curColorList[colorIndex])
                curJackeData.dif = curJackeData.dif + difValue
            end
        end
    end

    table.sort(round1List,function(a,b)
        return a.dif < b.dif
    end)

    for i=1,5 do
        nLog('[找歌] 最终结果 序号:'..i..' '..round1List[i].name..' 差异为:'..round1List[i].dif)
    end

    return JacketColorConfig[round1List[1].name].musicIndex
end

function DeviceMgr.GetMusicDifficult()
    local DifficultCheckConfig = DeviceConfig.DifficultCheckConfig
    local color = getColor(DifficultCheckConfig.pos.x,DifficultCheckConfig.pos.y)
    local difficult = DifficultCheckConfig[color]
    nLog('难度颜色为:'..color..'难度获取为:'..tostring(difficult))
    return difficult
end

--获取两个颜色的方差
function DeviceMgr.CalcColorDif(color0, color1)
    local difR = color0[1] - color1[1]
    local difG = color0[2] - color1[2]
    local difB = color0[3] - color1[3]
    local difValue = difR * difR + difB * difB + difG * difG

    return difValue
end

--获取一个区域的颜色值列表
function DeviceMgr.GetClientColorList(startX,startY,width,height)
    local clientColorList = {}
    for x=0,width-1 do
        for y=0,height-1 do
            local pointIndex = y * width + x + 1
            local r,g,b = getColorRGB(startX + x,startY + y)
            --nLog('查找像素点 x:'..(startX + x)..' y:'..(startY + y)..' 颜色为:'..r..' '..g..' '..b)
            table.insert(clientColorList,{r,g,b})
        end
    end

    return clientColorList
end

return DeviceMgr