local BangDreamConfig = {}

BangDreamConfig.TouchXList = {
    [1] = 197,
    [2] = 197 + 148 * 1,
    [3] = 197 + 148 * 2,
    [4] = 197 + 148 * 3,
    [5] = 197 + 148 * 4,
    [6] = 197 + 148 * 5,
    [7] = 197 + 148 * 6,
}
--七个按键中最左侧的按键x位置
BangDreamConfig.PosStartX = 197;
--每个按键的x方向间隔
BangDreamConfig.PosX_Interval = 148;
--按键的y坐标
BangDreamConfig.PosY = 130;
--按键计算的随机范围
BangDreamConfig.TouchRandRamge = 0

--检测第一个音符的位置
BangDreamConfig.CheckIsStartPosY = 149

BangDreamConfig.ColorList = {
    [1] = {color = 0,pos = {x=84,y=1098},rgb = {0,0,0}}, --横幅黑色
    [2] = {color = 16777215,pos = {x=247,y=96},rgb = {255,255,255}},  --横幅白色
    [3] = {color = 0,pos = {x=247,y=96},rgb = {0,0,0}},  --横幅处为黑色
    [4] = {color = 16777215,pos = {x=129,y=344},rgb = {255,255,255}},  --游戏内点击区域颜色
    [5] = {color = 10,rgb = {0,0,10}} --检测第一个音符颜色
}

--获取滑动时的目标位置
function BangDreamConfig.GetFlickMoveTarget(lane,x,y)
    return x,y + 40
end

--滑动时的滑动多少检测帧
BangDreamConfig.FlickMoveCount = 1
--滑动时的间隔时间
BangDreamConfig.MoveFrameDtTime = 20

function BangDreamConfig.GetTouchPos(index)
    local x = BangDreamConfig.PosY
    local y = BangDreamConfig.PosStartX + index * BangDreamConfig.PosX_Interval

    --计算随机位置
    local randDis = math.random(0,BangDreamConfig.TouchRandRamge)
    local halfDis = math.floor(randDis / 2)
    local randOffsetY = math.random(-halfDis,halfDis)
    local offsetX = math.floor(math.sqrt(randDis * randDis - randOffsetY * randOffsetY))
    if(math.random(0,1) == 1) then
        offsetX = -offsetX
    end

    x = x + randOffsetY
    y = y + offsetX
    nLog('随机偏移:'..offsetX..' '..randOffsetY)
    return x,y
end

--获取检测第一个音符颜色的位置
function BangDreamConfig.GetChickStartPos(index)
    local x = BangDreamConfig.CheckIsStartPosY
    local y = BangDreamConfig.TouchXList[index + 1]
    return x,y
end

--通过BPM和beat来获取当前beat的准确时间
function BangDreamConfig.GetExactTime(BPM,beatIndex)
    if(beatIndex == nil) then
        nLog('传入beatInde为nil:'..debug.traceback())
    end
    
    local time = 60 / BPM * beatIndex
    return time
end

function BangDreamConfig.GetBeatExactTime(BPMInfo,beatIndex)
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


function BangDreamConfig.GetAllSoundInfoType()
    BangDreamConfig.allType = {}
    for i=1,100 do
        for j=0,4 do
            BangDreamConfig.GetMusicAllType(i,j)
        end
    end

    for k,v in pairs(BangDreamConfig.allType) do
        nLog('类型:'..k)
    end
    
    BangDreamConfig.allType = nil
end

--加载歌曲信息
function BangDreamConfig.LoadMusicInfo(songId,difficulty)
    local soundInfoPath = "SoundInfo_Lua."..songId.."_"..difficulty
    local fullPath = userPath().."/lua/SoundInfo_Lua/"..songId.."_"..difficulty..".lua"
    local isExist = isFileExist(fullPath)
    if(not isExist) then
        nLog('文件不存在:'..fullPath)
        return nil
    end
    local soundInfo = require(soundInfoPath)
    return soundInfo
end

--获取第一个按键的位置
function BangDreamConfig.GetMusicFirstLane(songId,difficulty)
    local songInfo = BangDreamConfig.LoadMusicInfo(songId,difficulty)

    local curBeatData = songInfo[3]
    if(curBeatData.type == "Single" or curBeatData.type == "Directional") then
        return curBeatData.lane
    elseif(curBeatData.type == "Long" or curBeatData.type == "Slide") then
        return curBeatData.connections[1].lane
    end

    return 0
end


function BangDreamConfig.GetMusicAllType(songId,difficulty)
    local musicInfo = BangDreamConfig.LoadMusicInfo(songId,difficulty)
    if(musicInfo == nil) then
        return    
    end
    
    for i=1,#musicInfo do
        BangDreamConfig.allType[musicInfo[i].type] = true
    end
end

return BangDreamConfig