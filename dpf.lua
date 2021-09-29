_G['dpf'] = {}


function dpf.loadjson(f,w)
  w = w or {}
  print("dpf loading " .. f)
  local cf = io.open(f, "r+")
  if cf == nil then
    cf = io.open(f, "w")
    cf:write(json.encode(w))
    cf:close()
    cf = io.open(f, "r+")
  end
  local text = cf:read("*a")
  if string.sub(f,-8) == ".rdlevel" then
    text = text:sub(4) -- BEGONE, ∩╗┐
  end
  local filejson = json.decode(text)
  cf:close()
  return filejson
end
function dpf.loadtracery(f)
  print("dpf loading tracery " .. f)
  local cf = io.open(f, "r+")
  local filejson = json.decode(cf:read("*a"))
  cf:close()
  local grammar = tracery.createGrammar(filejson)
  grammar:addModifiers(tracery.baseEngModifiers)
  return grammar
end

function dpf.savejson(f,w)
  local cf = io.open(f, "w")
  cf:write(json.encode(w))
  cf:close()
end


return dpf