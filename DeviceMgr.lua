local DeviceMgr = {}

--目前已经配置的设备类型列表
DeviceMgr.DeviceTypeList = {
    [1] = {name = 'NoxSimulator',fileName = 'NoxSimulator_Config'},
    [2] = {name = 'Redmi_K30',fileName = 'Redmi_K30_Config'},
}

--具体设备的配置信息
local DeviceConfig = nil

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

    local deviceInfoPath = "DeviceConfig."..deviceInfo.fileName
    local fileFullPath = userPath().."/lua/DeviceConfig/"..deviceInfo.fileName..".lua"
    local isExist = isFileExist(fileFullPath)
    if(not isExist) then
        nLog('[DeviceMgr] 设备配置文件不存在:'..fileFullPath)
        return false
    end
    DeviceConfig = require(deviceInfoPath)
    DeviceMgr.ColorList = DeviceConfig.ColorList
    return true
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


return DeviceMgr