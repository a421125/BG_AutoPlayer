local BangDreamUtils = {}

--加载歌曲信息
function BangDreamUtils.LoadMusicInfo(songId,difficulty)
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

function BangDreamUtils.GetMusicAllType(songId,difficulty)
    local musicInfo = BangDreamUtils.LoadMusicInfo(songId,difficulty)
    if(musicInfo == nil) then
        return    
    end
    
    for i=1,#musicInfo do
        BangDreamUtils.allType[musicInfo[i].type] = true
    end
end

function BangDreamUtils.GetAllSoundInfoType()
    BangDreamUtils.allType = {}
    for i=1,100 do
        for j=0,4 do
            BangDreamUtils.GetMusicAllType(i,j)
        end
    end

    for k,v in pairs(BangDreamUtils.allType) do
        nLog('类型:'..k)
    end
    
    BangDreamUtils.allType = nil
end

return BangDreamUtils