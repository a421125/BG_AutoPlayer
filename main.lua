require "TSLib"
local ts = require("ts")

GlobalConfig = {
    useRandomGreat = false,
    correctionDelay = 0.03,
}

DeviceMgr = require("DeviceMgr")
ViewStatusMgr = require("ViewStatusMgr")
DeviceMgr.InitByDeviceType(3)

BangDreamUtils = require("BangDreamUtils")
local BangDreamDriver = require("BangDreamDriver")

--模拟器为2 手机为1 起点为左上角  x水平 y向下
init(DeviceMgr.GetInitDir())

-- local color1 = getColor(1829,881)
-- local color1_r,color1_g,color1_b = getColorRGB(1829,881)
-- local color2 = getColor(1874,875)
-- local color2_r,color2_g,color2_b = getColorRGB(1874,875)
-- nLog('颜色1:'..color1..' r:'..color1_r..' g:'..color1_g..' b:'..color1_b)
-- nLog('颜色2:'..color2..' r:'..color2_r..' g:'..color2_g..' b:'..color2_b)

-- if(true) then
--     return
-- end

while(true) do
    mSleep(2)
    ViewStatusMgr.Update()
end