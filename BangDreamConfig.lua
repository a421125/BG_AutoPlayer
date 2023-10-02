local BangDreamConfig = {}

BangDreamConfig.TouchXList = {
    [1] = 210,
    [2] = 210 + 156 * 1,
    [3] = 210 + 156 * 2,
    [4] = 210 + 156 * 3,
    [5] = 210 + 156 * 4,
    [6] = 210 + 156 * 5,
    [7] = 210 + 156 * 6,
}

BangDreamConfig.PosY = 220;

--获取滑动时的目标位置
function BangDreamConfig.GetFlickMoveTarget(lane,x,y)
    return x,y + 20
end

--滑动时的滑动多少检测帧
BangDreamConfig.FlickMoveCount = 1
--滑动时的间隔时间
BangDreamConfig.MoveFrameDtTime = 20

function BangDreamConfig.GetTouchPos(index,nextIndex,percent)
    local x = 220
    local y = BangDreamConfig.TouchXList[index + 1]
    if(nextIndex and percent) then
        local nextY = BangDreamConfig.TouchXList[nextIndex + 1]
        y = math.floor((nextY + y) / 2)
    end

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