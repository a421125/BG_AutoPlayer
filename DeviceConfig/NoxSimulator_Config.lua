local DeviceConfig = {}

--初始化init的方向
DeviceConfig.InitDir = 2

--七个按键中最左侧的按键x位置
DeviceConfig.PosStartX = 197;
--每个按键的x方向间隔
DeviceConfig.PosX_Interval = 148;
--按键的y坐标
DeviceConfig.PosY = 130;
--按键计算的随机范围
DeviceConfig.TouchRandRamge = 30

--检测第一个音符的位置
DeviceConfig.CheckIsStartPosY = 149

DeviceConfig.ColorList = {
    [1] = {color = 0,pos = {x=84,y=1098},rgb = {0,0,0}}, --横幅黑色
    [2] = {color = 16777215,pos = {x=247,y=96},rgb = {255,255,255}},  --横幅白色
    [3] = {color = 0,pos = {x=247,y=96},rgb = {0,0,0}},  --横幅处为黑色
    [4] = {color = 16777215,pos = {x=129,y=344},rgb = {255,255,255}},  --游戏内点击区域颜色
    [5] = {color = 10,rgb = {0,0,10}} --检测第一个音符颜色
}

function DeviceConfig.GetTouchPos(index)
    local x = DeviceConfig.PosY
    local y = DeviceConfig.PosStartX + index * DeviceConfig.PosX_Interval

    --计算随机位置
    local randDis = math.random(0,DeviceConfig.TouchRandRamge)
    local halfDis = math.floor(randDis / 2)
    local randOffsetY = math.random(-halfDis,halfDis)
    local offsetX = math.floor(math.sqrt(randDis * randDis - randOffsetY * randOffsetY))
    if(math.random(0,1) == 1) then
        offsetX = -offsetX
    end

    x = x + randOffsetY
    y = y + offsetX
    --nLog('随机偏移:'..offsetX..' '..randOffsetY)
    return x,y
end

--获取检测第一个音符颜色的位置
function DeviceConfig.GetChickStartPos(index)
    local x = DeviceConfig.CheckIsStartPosY
    local y = DeviceConfig.PosStartX + index * DeviceConfig.PosX_Interval
    return x,y
end

return DeviceConfig