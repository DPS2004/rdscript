chatty = true


function trim(s)
   return s:match "^%s*(.-)%s*$"
end

function p(s)
  if chatty then
    print(s)
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
print(levelfile)
level = dpf.loadjson(levelfile)
script = {}
for line in io.lines(scriptfile) do
  line = trim(line)
  if line ~= "" then
    table.insert(script,line)
    p("loading line "..line)
  end
end
  