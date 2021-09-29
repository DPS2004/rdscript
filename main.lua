chatty = true


function trim(s)
   return s:match "^%s*(.-)%s*$"
end

function p(s)
  if chatty then
    print(s)
  end
end

function newconditional(n, exp)
  local newid = #level.conditionals + 1
  table.insert(level.conditionals,{
    id = newid, --this might not always work!!!!!
    type = "Custom",
    name = n,
    expression = exp
  })
  conditionalnames[n] = #level.conditionals
  p("conditional added: "..n..", "..exp..", id of ".. newid)
end

function runtag(bar,beat,dotag,checktag,conditional,length)
  local ifval = nil
  length = length or 0
  if conditional then
    ifval = conditionalnames[conditional] .."d"..length
  else
    conditional = "none"
  end
  table.insert(level.events,{
    bar = bar,
    beat = beat,
    y = 0,
    type = "TagAction",
    tag = checktag,
    Action = "Run",
    Tag = dotag
  })
  level.events[#level.events]["if"] = ifval
  print("runtag added: "..dotag..", conditional of ".. conditional)
end

function checkcommand(line,k)
  if string.sub(line,0,#k) == k then
    p(k)
    local params = {}
    for i in string.gmatch(string.sub(line,#k+2), '([^,]+)') do
      i = trim(i)
      table.insert(params,i)
      p(i)
    end
    if params[#params] then
      params[#params] = string.sub(params[#params],1,-2) --remove )
    end
    table.insert(script,{command = k,parameters = params})
    return true
  else
    return false
  end
  
end

json = require "json"
dpf = require "dpf"

if arg[1] and arg[2] then
  levelfile = arg[2]
  
  scriptfile = arg[1]
  outfile = "out.rdlevel"
  if arg[3] then
    outfile = arg[3]
  end
else
  error("Not enough arguments were passed.")
  
end
level = dpf.loadjson(levelfile)
scriptlines = {}
script = {}
linenumber = 1
for line in io.lines(scriptfile) do
  line = trim(line)
  if line ~= "" then
    table.insert(scriptlines,line)
    p("loading line "..line)
    local found = false
    
    if checkcommand(line,"levelend") then found = true end
    if checkcommand(line,"define") then found = true end
    if checkcommand(line,"if") then found = true end
    if checkcommand(line,"tag") then found = true end
    if checkcommand(line,"end") then found = true end
    if checkcommand(line,"while") then found = true end
    if checkcommand(line,"run") then found = true end
    
    if found == false and string.sub(line,0,2) == "--" then
      p("comment found: " .. line)
      found = true
    end
    if not found then
      error("Could not parse line " .. linenumber .. ": ".. line)
    end
  end
  
  linenumber = linenumber + 1
end






print("--------Processing Script--------")

levelend = {99,1}
layer = 0
layertags = {}
ifcount = 0
whilecount = 0

conditionalnames = {}

if not level.conditionals then
  level.conditionals = {}
end

newconditional("rs_true","0==0")


for i,v in ipairs(script) do
  if v.command == "levelend" then
    levelend = {tonumber(v.parameters[1]),tonumber(v.parameters[2])}
    p("level end set to bar ".. v.parameters[1] .. " beat " .. v.parameters[2])
  end
  if v.command == "define" then
    layer = layer + 1
    layertags[layer] = v.parameters[1]
    p("layer set to ".. layer..", tag set to " .. layertags[layer])
  end
  if v.command == "if" then
    ifcount = ifcount + 1
    newconditional("rscon_if_"..ifcount,v.parameters[1])
    runtag(levelend[1],levelend[2],"rstag_if_"..ifcount,layertags[layer],"rscon_if_"..ifcount)
    layer = layer + 1
    layertags[layer] = "rstag_if"..ifcount
  end
  if v.command == "tag" then
    runtag(levelend[1],levelend[2],v.parameters[1],layertags[layer])
  end
  if v.command == "end" then
    local oldlayer = layertags[layer]
    layertags[layer] = "nil"
    layer = layer - 1
    local newlayer = layertags[layer]
    if not newlayer then
      newlayer = "NO LAYER"
    end
    p("ending layer, returning from " ..oldlayer.. " to " .. newlayer)
  end
  if v.command == "while" then
    whilecount = whilecount + 1
    runtag(tonumber(v.parameters[1]),tonumber(v.parameters[2]),"rstag_while_"..whilecount,layertags[layer],"rs_true",v.parameters[3])
    layer = layer + 1
    layertags[layer] = "rstag_while_"..whilecount
  end
  if v.command == "run" then
    table.insert(level.events,{
      bar = levelend[1],
      beat = levelend[2],
      y = 1,
      type = "CallCustomMethod",
      methodName = v.parameters[1],
      tag = layertags[layer],
      executionTime = "OnBar",
      sortOffset = 0
    })
    p("added run custom method " .. v.parameters[1] .. " with tag "..layertags[layer])
  end
end


dpf.savejson(outfile,level)
  