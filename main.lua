json = require "json"
dpf = require "dpf"

chatty = true

jsonsave = true

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
  if string.sub(trim(line),0,#k) == k then
    p(k)
    local params = {}
    for i in string.gmatch(string.sub(trim(line),#k+2), '([^,]+)') do
      i = trim(i)
      table.insert(params,i)
      p(i)
    end
    if params[#params] then
      params[#params] = string.sub(params[#params],1,-2) --remove )
    end
    if pythonmode then
      local indent = string.find(line,k) - 1
      if indent ~= 0 then
        --indent found
        if indentsize == -1 then
          indentsize = indent
        end
        
        indent = indent / indentsize -- get real indent number
        if indent % 1 ~= 0 then
          error("(Python Mode) Non-integer indent at line " .. linenumber .. ": " .. line)
        end
        if indent - (lastindent + 1) > 0 then
          error("(Python Mode) Too big of an indent at line " .. linenumber .. ": " .. line .. " (" .. lastindent + 1 .. " or less expected, " .. indent .. " recieved)")
        end
      end
      
      indentoffset = (lastindent - indent)
      if indentoffset > 0 then
        --descending!
        for i=1,indentoffset do
          p("added fake 'end' for indents")
          table.insert(script,{command = "end",parameters = {},line=linenumber-0.5})
        end
      end
      lastindent = indent
      table.insert(script,{command = k,parameters = params,line=linenumber})
    else
      table.insert(script,{command = k,parameters = params,line=linenumber})
    end
    return true
  else
    return false
  end
  
end

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

pythonmode = false
lastindent = 0
indentsize = -1

level = dpf.loadjson(levelfile)
scriptlines = {}
script = {}
linenumber = 1
for line in io.lines(scriptfile) do
  --line = trim(line)
  if line == "python_mode(True)" then
    pythonmode = true
    p("Python mode activated.")
  end
  if trim(line) ~= "" then
    table.insert(scriptlines,trim(line))
    p("loading line "..trim(line))
    local found = false
    
    if checkcommand(line,"python_mode") then found = true end
    if checkcommand(line,"levelend") then found = true end
    if checkcommand(line,"define") then found = true end
    if checkcommand(line,"if") then found = true end
    if checkcommand(line,"tag") then found = true end
    if checkcommand(line,"end") then found = true end
    if checkcommand(line,"for") then found = true end
    if checkcommand(line,"run") then found = true end
    if checkcommand(line,"setcondensed") then found = true end
    if found == false and string.sub(trim(line),0,2) == "--" then
      p("comment found: " .. trim(line))
      found = true
    end
    if not found then
      error("Could not parse line " .. linenumber .. ": ".. line)
    end
  end
  
  linenumber = linenumber + 1
end

if jsonsave then
  dpf.savejson("parsed.json",script)
end




print("--------Processing Script--------")

condensed = true
levelend = 99
layer = 0
layertypes = {}
layertags = {}
ifcount = 0
forcount = 0
cfor = {duration = 0, bar = 99, beat=1}

conditionalnames = {}

if not level.conditionals then
  level.conditionals = {}
end

newconditional("rs_true","0==0")


for i,v in ipairs(script) do
  if v.command == "levelend" then
    levelend = tonumber(v.parameters[1]) + 2
    table.insert(level.events,{
      bar = levelend-1,
      beat = 1,
      y = 1,
      type = "SetPlayStyle",
      PlayStyle = "Normal",
      NextBar = 0,
      Relative = true
    })
    p("level end set to bar ".. v.parameters[1])
  end
  if v.command == "define" then
    layer = layer + 1
    layertags[layer] = v.parameters[1]
    layertypes[layer] = "define"
    p("layer set to ".. layer..", tag set to " .. layertags[layer])
  end
  if v.command == "if" then
    ifcount = ifcount + 1
    newconditional("rscon_if_"..ifcount,v.parameters[1])
    if condensed then
      runtag(levelend,1,"rstag_if_"..ifcount,layertags[layer],"rscon_if_"..ifcount)
    else
      if layertypes[layer] ~= "for" then
        runtag(levelend,1,"rstag_if_"..ifcount,layertags[layer],"rscon_if_"..ifcount)
      else
        runtag(cfor.bar,cfor.beat,"rstag_if_"..ifcount,layertags[layer],"rscon_if_"..ifcount,cfor.duration)
      end
    end
    layer = layer + 1
    layertags[layer] = "rstag_if_"..ifcount
    layertypes[layer] = "if"
  end
  if v.command == "tag" then
    runtag(levelend,1,v.parameters[1],layertags[layer])
  end
  if v.command == "end" then
    if condensed or layertypes[layer] ~= "for" then
      local oldlayer = layertags[layer]
      layertags[layer] = "nil"
      layertypes[layer] = "nil"
      layer = layer - 1
      local newlayer = layertags[layer]
      if not newlayer then
        newlayer = "NO LAYER"
      end
      if not oldlayer then
        error("Unexpected 'end' at line " .. v.line)
      end
      p("ending layer, returning from " ..oldlayer.. " to " .. newlayer)
    else
      p("ending uncondensed for layer")
      layertypes[layer] = "nonfor"
    end
  end
  if v.command == "for" then
    if condensed then
      p("starting condensed for loop")
      forcount = forcount + 1
      runtag(tonumber(v.parameters[1]),tonumber(v.parameters[2]),"rstag_for_"..forcount,layertags[layer],"rs_true",v.parameters[3])
      layer = layer + 1
      layertags[layer] = "rstag_for_"..forcount
      layertypes[layer] = "for"
      
    else
      forcount = forcount + 1
      layertypes[layer] = "for"
      cfor.duration = v.parameters[3]
      cfor.bar = tonumber(v.parameters[1])
      cfor.beat = tonumber(v.parameters[2])
      p("starting uncondensed for loop")
    end
  end
  if v.command == "run" then
    table.insert(level.events,{
      bar = levelend,
      beat = 1,
      y = 1,
      type = "CallCustomMethod",
      methodName = v.parameters[1],
      tag = layertags[layer],
      executionTime = "OnBar",
      sortOffset = 0
    })
    p("added run custom method " .. v.parameters[1] .. " with tag "..layertags[layer])
  end
  if v.command == "setcondensed" then
    if v.parameters[1] == "true" then
      condensed = true
    else
      condensed = false
    end
    p("set condensed mode to " .. tostring(condensed))
  end
      
end




dpf.savejson(outfile,level)
  