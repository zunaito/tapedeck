-- TPDK
-- tape emulator fx
--
-- llllllll.co/t/tapedeck
--
--
--
--    ▼ instructions below ▼
--
-- see param menu to map controls
--

engine.name="Tpdk"

counter=0
tape_spin=0
font_level=15
message="drive=0.5"
pcur=1

groups={
  {"tape_wet","saturation","drive"},
  {"dist_wet","lowgain","highgain"},
  {"wowflu","wobble_amp","flutter_amp"},
}

current_monitor_level=0
function init()
  current_monitor_level=params:get("monitor_level")
  params:set("monitor_level",-99)

  params:add_control("amp","amp",controlspec.new(0,1,'lin',0.01/1,1,'',0.1/1))
  params:set_action("amp",function(x)
    engine.amp(x)
    msg("amp="..(math.floor(x*10)/10))
  end)
  params:add_separator("tape")
  local ps={
    {"tape_wet","wet",0},
    {"tape_bias","bias",50},
    {"saturation","sat",80},
    {"drive","drive",80},
  }
  for _,p in ipairs(ps) do
    params:add_control(p[1],p[2],controlspec.new(0,100,'lin',1,p[3],"%",1/100))
    params:set_action(p[1],function(x)
      engine[p[1]](x/100)
      msg(p[2].."="..math.floor(x).."%")
    end)
  end
  params:add_separator("distortion")
  local ps={
    {"dist_wet","wet",0},
    {"drivegain","drive",10},
    {"dist_bias","bias",0},
    {"lowgain","low",10},
    {"highgain","high",10},
  }
  for _,p in ipairs(ps) do
    params:add_control(p[1],p[2],controlspec.new(0,100,'lin',1,p[3],"%",1/100))
    params:set_action(p[1],function(x)
      engine[p[1]](x/100)
      msg(p[2].."="..math.floor(x).."%")
    end)
  end
  params:add_control("shelvingfreq","shelving freq",controlspec.new(20,16000,'exp',10,600,'Hz',10/16000))
  params:set_action("shelvingfreq",function(x)
    engine.shelvingfreq(x)
  end)

  params:add_separator("wow / flutter")
  local ps={
    {"wowflu","wet",0},
    {"wobble_amp","wobble",8},
    {"flutter_amp","flutter",3},
  }
  for _,p in ipairs(ps) do
    params:add_control(p[1],p[2],controlspec.new(0,100,'lin',1,p[3],"%",1/100))
    params:set_action(p[1],function(x)
      engine[p[1]](x/100)
      msg(p[2].."="..math.floor(x).."%")
    end)
  end
  params:add_control("wobble_rpm","wobble rpm",controlspec.new(1,66,'lin',1,33,'rpm',1/66))
  params:set_action("wobble_rpm",function(x)
    engine.wobble_rpm(x)
  end)
  params:add_control("flutter_fixedfreq","flutter freq",controlspec.new(0.1,10,'lin',0.1,6,'Hz',0.1/10))
  params:set_action("flutter_fixedfreq",function(x)
    engine.flutter_fixedfreq(x)
  end)
  params:add_control("flutter_variationfreq","flutter var freq",controlspec.new(0.1,10,'lin',0.1,2,'Hz',0.1/10))
  params:set_action("flutter_variationfreq",function(x)
    engine.flutter_variationfreq(x)
  end)

  params:add_separator("filters")
  params:add_control("lpf","low-pass filter",controlspec.new(100,20000,'exp',100,18000,'Hz',100/18000))
  params:set_action("lpf",function(x)
    engine.lpf(x)
  end)
  params:add_control("lpfqr","low-pass qr",controlspec.new(0.02,1,'lin',0.02,0.7,'',0.02/1))
  params:set_action("lpfqr",function(x)
    engine.hpfqr(x)
  end)
  params:add_control("hpf","high-pass filter",controlspec.new(10,20000,'exp',10,60,'Hz',10/18000))
  params:set_action("hpf",function(x)
    engine.hpf(x)
  end)
  params:add_control("hpfqr","high-pass qr",controlspec.new(0.02,1,'lin',0.02,0.7,'',0.02/1))
  params:set_action("hpfqr",function(x)
    engine.hpfqr(x)
  end)

  params:bang()

  msg("MIX "..ToRomanNumerals(math.random(1,12)),30)

  clock.run(function()
    while true do
      clock.sleep(1/10)
      redraw()
    end
  end)
end

function cleanup()
  params:set("monitor_level",current_monitor_level)
end

function ToRomanNumerals(s)
  local map={
    I=1,
    V=5,
    X=10,
    L=50,
    C=100,
    D=500,
    M=1000,
  }
  local numbers={1,5,10,50,100,500,1000}
  local chars={"I","V","X","L","C","D","M"}

  --s = tostring(s)
  s=tonumber(s)
  if not s or s~=s then error"Unable to convert to number" end
  if s==math.huge then error"Unable to convert infinity" end
  s=math.floor(s)
  if s<=0 then return s end
  local ret=""
  for i=#numbers,1,-1 do
    local num=numbers[i]
    while s-num>=0 and s>0 do
      ret=ret..chars[i]
      s=s-num
    end
    --for j = i - 1, 1, -1 do
    for j=1,i-1 do
      local n2=numbers[j]
      if s-(num-n2)>=0 and s<num and s>0 and num-n2~=n2 then
        ret=ret..chars[j]..chars[i]
        s=s-(num-n2)
        break
      end
    end
  end
  return ret
end

function msg(s,l)
  message=s
  font_level=l or 15
end

  screen.update()
end
