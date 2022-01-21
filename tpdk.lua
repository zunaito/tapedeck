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

cs = require 'controlspec'

buf_time = 16777216 / 48000 --exact time from the sofctcut source
play_fade = 0.1
rec_fade = 0.05

audio.level_cut(1.0)
audio.level_adc_cut(1)
audio.level_eng_cut(1)

local function stereo(command, pair, ...)
    local off = (pair - 1) * 2
    for i = 1, 2 do
        softcut[command](off + i, ...)
    end
end

local function time()
    local loop_points = {}
    for i = 1,3 do loop_points[i] = { 0, 0 } end

    local heads = { 1, 2, 3 }
    local time = 1

    local function update(i)
        local st = loop_points[heads[i]][1]
        local en = loop_points[heads[i]][2]
        local mar = rec_fade

        stereo('loop_start', i, i==3 and (st-mar) or (st))
        stereo('loop_end', i, i==3 and (en+mar) or (en))
    end

    params:add{
        type='control', id='time',
        controlspec = cs.def{ min = 0.06, max = 5*3, default = 1.85 },
        action = function(v)
            time = v/3

            local mar = play_fade*4 + (5*3)
            for i = 1,3 do
                loop_points[i][1] = (i - 1) * (mar)
                loop_points[i][2] = (i- 1) * (mar) + time

                update(i)
            end
        end
    }


    for i = 1,3 do
        -- update(i)
        local st = loop_points[heads[i]][1]
        stereo('position', i, st)
    end
    clock.run(function()
        while true do
            for i = 1,3 do
                update(i)
                local st = loop_points[heads[i]][1]
                -- stereo('position', i, st)
            end
            
            clock.sleep(time)
            table.insert(heads, 1, table.remove(heads, #heads))
        end
    end)
end

local function head(idx)
    stereo('enable', idx, 1)
    stereo('level_slew_time', idx, 0.1)
    stereo('recpre_slew_time', idx, 0.1)

    local off = (idx - 1) * 2
    softcut.pan(off + 1, -1)
    softcut.pan(off + 2, 1)
    softcut.buffer(off + 1, 1)
    softcut.buffer(off + 2, 2)
end

local function rechead()
    idx = 3
    local off = (idx - 1) * 2

    head(idx)

    stereo('loop', idx, 1)
    stereo('rec', idx, 1)
    stereo('play', idx, 0)
    stereo('pre_level', idx, 0)
    stereo('rec_level', idx, 1)
    stereo('fade_time', idx, rec_fade)

    do
        local route = 'stereo'
        local pan = 0
        local function update()
            local v, p = 1, pan

            if route == 'stereo' then
                softcut.level_input_cut(1, off + 1, v * ((p > 0) and 1 - p or 1))
                softcut.level_input_cut(2, off + 1, 0)
                softcut.level_input_cut(2, off + 2, v * ((p < 0) and 1 + p or 1))
                softcut.level_input_cut(1, off + 2, 0)
            elseif route == 'mono' then
                softcut.level_input_cut(1, off + 1, v * ((p > 0) and 1 - p or 1))
                softcut.level_input_cut(1, off + 2, v * ((p < 0) and 1 + p or 1))
                softcut.level_input_cut(2, off + 1, v * ((p > 0) and 1 - p or 1))
                softcut.level_input_cut(2, off + 2, v * ((p < 0) and 1 + p or 1))
            end
        end
        local ir_op = { 'stereo', 'mono' } 
        params:add{
            type = 'option', id = 'input routing', options = ir_op,
            action = function(v) route = ir_op[v]; update() end
        }
        params:add{
            type = 'control', id = 'input pan', 
            controlspec = cs.def{ min = -1, max = 1, default = 0.5 },
            action = function(v) pan = v; update() end
        }
    end
    params:add{
        type = 'control', id = 'feedback', controlspec = cs.def{ default = 0.54 },
        action = function(v)
            softcut.level_cut_cut(1 + off, 2 + off, v)
            softcut.level_cut_cut(2 + off, 1 + off, v)
        end
    }
end

local rates = { 1, 1, 1 }
local function update_all_rates()

end
local function update_rate(i)
end

local rates = {
    1, 1, 1,
    all = 1,
    update = function(s, i)
        stereo('rate', i, s[i] * s.all)
    end,
    update_all = function(s)
        for i = 1,3 do
            s:update(i)
        end
    end
}

local function all()
    params:add{
        type='control', id='all fine',
        controlspec = cs.def{ min = -1, max = 1, default = 0 },
        action = function(v)
            rates.all = 2^v; rates:update_all()
        end
    }
    params:add{
        type='control', id ='slew',
        controlspec = cs.def{ min = 0, max = 0.5, default = 0.1 },
        action = function(v)
            for i = 1,6 do
                softcut.rate_slew_time(i, v)
            end
        end
    }
end

local function playhead(idx)
    local off = (idx - 1) * 2

    head(idx)
    
    stereo('rec', idx, 0)
    stereo('play', idx, 1)
    stereo('loop', idx, 1)
    stereo('level_input_cut', 1, idx, 0)
    stereo('level_input_cut', 2, idx, 0)
    stereo('pre_level', idx, 1)
    stereo('fade_time', idx, play_fade)

    -- stereo('post_filter_dry', idx, 0)
    -- stereo('rec', idx, 1)
    -- stereo('pre_level', idx, 0.75)

    do
        local pan = 0
        local lvl = 1
        local update = function()
            local p, v = pan, lvl
            softcut.level(off + 1, v * ((p > 0) and 1 - p or 1))
            softcut.level(off + 2, v * ((p < 0) and 1 + p or 1))
        end

        params:add{
            type='control', id = 'level '..idx,
            controlspec = cs.def { default = .8 },
            action = function(v) lvl = v; update() end
        }
        params:add{
            type='control', id = 'pan '..idx,
            controlspec = cs.def { min = -1, max = 1, default = 0 },
            action = function(v) pan = v; update() end
        }
    end
    do
        local names = { '-2x', '-1x', '-1/2x', '1/2x', '1x', '2x' }
        local vals = { -2, -1, -0.5, 0.5, 1, 2 }
        local course = 1
        local fine = 0
        local update = function()
            rates[idx] = (course * 2^fine); rates:update(idx)
        end
        params:add{
            type='option', id = 'rate '..idx,
            options = names, default = 5,
            action = function(v) 
                course = vals[v]; update()
            end
        }
        params:add{
            type='control', id='fine '..idx,
            controlspec = cs.def{ min = -1, max = 1, default = 0 },
            action = function(v)
                fine = v; update()
            end
        }
    end
end

local function filter()
    local pre = 'hp'
    local post = 'lp'
    local both = { pre, post }
    local defaults = { hp = 0, lp = 1 }

    for i = 1,2 do
        stereo('post_filter_dry', i, 0)
        stereo('post_filter_'..post, i, 1)
    end
    stereo('pre_filter_fc_mod', 3, 0)
    stereo('pre_filter_dry', 3, 0)
    stereo('pre_filter_'..pre, 3, 1)

    for i,filter in ipairs(both) do
        local pre = i==1

        params:add {
            type = 'control', id = filter,
            controlspec = cs.def{ default = defaults[filter], quantum = 1/100/2, step = 0 },
            action = (
                pre and (
                    function(v) 
                        stereo('pre_filter_fc', 3, util.linexp(0, 1, 2, 20000, v)) 
                    end
                ) or (
                    function(v) 
                        for i = 1,2 do
                            stereo('post_filter_fc', i, util.linexp(0, 1, 2, 20000, v)) 
                        end
                    end
                )
            )
        }
    end
    params:add {
        type = 'control', id = 'res',
        controlspec = cs.def{ default = 0.4 },
        action = function(v)
            for i = 1,2 do
                stereo('post_filter_rq', i, util.linexp(0, 1, 0.01, 20, 1 - v))
            end
            stereo('pre_filter_rq', 3, util.linexp(0, 1, 0.01, 20, 1 - v))
        end
    }
end


time()
all()
rechead()
filter()
playhead(1)
playhead(2)

function init()
    params:set('rate 1', 4)
    params:set('rate 2', 6)
    params:set('level 2', 0.91)
    
    softcut.pan(2, -1)
    softcut.pan(1, 1)

    params:bang()
end

function redraw()
    screen.clear()
    screen.move(20, 20)
    screen.text'nemes prism'
    screen.update()
end
