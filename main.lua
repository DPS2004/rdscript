chatty = true


function trim(s)
   return s:match "^%s*(.-)%s*$"
end

function p(s)
  if chatty then
    print(s)
  end
end

function checkcommand(line,k)
  if string.sub(line,0,#k) == k then
    p(k)
    local params = {}
    for i in string.gmatch(string.sub(line,#k+2), '([^,]+)') do
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
    outfile = "arg[3]"
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






  