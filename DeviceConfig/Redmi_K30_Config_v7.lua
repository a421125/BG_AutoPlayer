local DeviceConfig = {}

--初始化init的方向
DeviceConfig.InitDir = 1

--七个按键中最左侧的按键x位置
DeviceConfig.PosStartX = 554;
--每个按键的x方向间隔
DeviceConfig.PosX_Interval = 215;
--按键的y坐标
DeviceConfig.PosY = 851;
--按键计算的随机范围
DeviceConfig.TouchRandRamge = 30

--检测第一个音符的位置
-- DeviceConfig.CheckIsStartPosY = 820
DeviceConfig.CheckIsStartPosY = 756

--检查歌曲图的区域位置
DeviceConfig.RectCheckList = {
    [1] = {x=1,y=1,width=3,height=3},       --左上取9个颜色
    [2] = {x=472,y=1,width=3,height=3},     --右上取9个颜色
    [3] = {x=472,y=473,width=3,height=3},   --右下取9个颜色
    [4] = {x=1,y=473,width=3,height=3},     --左下取9个颜色
}
--歌曲界面的图片左上角位置
DeviceConfig.JacketLeftTopPos = {x=961,y=118}

--高清晰度
-- DeviceConfig.ColorList = {
--     [1] = {color = 0,pos = {x=164,y=690},rgb = {0,0,0}}, --横幅黑色
--     [2] = {color = 16711421,pos = {x=213,y=695},rgb = {254,254,253}},  --横幅白色
--     [3] = {color = 0,pos = {x=213,y=695},rgb = {0,0,0}},  --横幅处为黑色
--     [4] = {color = 16777215,pos = {x=554,y=851},rgb = {255,255,255}},  --游戏内点击区域颜色
-- }

--低清晰度
DeviceConfig.ColorList = {
    [1] = {color = 0,pos = {x=164,y=680},rgb = {0,0,0}}, --横幅黑色
    [2] = {color = 16711421,pos = {x=213,y=695},rgb = {254,254,253}},  --横幅白色
    [3] = {color = 0,pos = {x=213,y=695},rgb = {0,0,0}},  --横幅处为黑色
    [4] = {color = 16777215,pos = {x=555,y=851},rgb = {255,255,255}},  --游戏内点击区域颜色

    --检测开始游戏的位置和颜色
    [5] = {color = 16727154,pos = {x=1829,y=881},rgb = {255,60,114}},  --开始游戏的红色位置
    [6] = {color = 16776957,pos = {x=1874,y=875},rgb = {255,254,253}},  --开始游戏的白色位置
}

--检查第一个音符的x坐标
DeviceConfig.TouchStartPosListX = {
    [0] = 654,
    [1] = 830,
    [2] = 985,
    [3] = 1200,
    [4] = 1415,
    [5] = 1556,
    [6] = 1766,
}

DeviceConfig.TouchPosBlackColor = 17

--歌曲界面难度检测的配置相关
DeviceConfig.DifficultCheckConfig = {
    pos = {x=1450,y=294},
    [15476107] = 4, --special 粉色
    [15543598] = 3, --expert 红色
    [16689442] = 2, --hard 黄色
    [1619745] = 1,  --normal 绿色
    [3624696] = 0,  --easy 蓝色
}

function DeviceConfig.GetTouchPos(index)
    local y = DeviceConfig.PosY
    local x = DeviceConfig.PosStartX + index * DeviceConfig.PosX_Interval

    --计算随机位置
    local randDis = math.random(0,DeviceConfig.TouchRandRamge)
    local halfDis = math.floor(randDis / 2)
    local randOffsetY = math.random(-halfDis,halfDis)
    local offsetX = math.floor(math.sqrt(randDis * randDis - randOffsetY * randOffsetY))
    if(math.random(0,1) == 1) then
        offsetX = -offsetX
    end

    x = x + offsetX
    y = y + randOffsetY
    -- nLog('随机偏移:'..offsetX..' '..randOffsetY)
    return x,y
end



--获取检测第一个音符颜色的位置
function DeviceConfig.GetChickStartPos(index)
    local y = DeviceConfig.CheckIsStartPosY
    local x = DeviceConfig.TouchStartPosListX[index]
    return x,y
end

return DeviceConfig