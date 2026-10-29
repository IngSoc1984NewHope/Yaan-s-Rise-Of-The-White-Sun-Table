-- Rise Of The White Sun: standalone metadata-only Mono diagnostic v0.1.2
-- For CE Lua Engine. Attach game process, then execute; no .CT needed.
-- Does not change game variables, invoke game cheat functions or edit saves.
-- LaunchMonoDataCollector may inject CE's Mono collector helper into the process.
local REPORT_NAME = 'ROWS_Mono_Discovery.txt'
local folder = os.getenv('TEMP') or os.getenv('TMP') or '.'
local path = folder .. '\\' .. REPORT_NAME
local fh, e = io.open(path,'w')
if not fh then
  showMessage('Cannot create report: '..tostring(e))
  return
end
local function log(v) fh:write(tostring(v),'\n'); fh:flush() end
local function ashex(x)
  if type(x)=='number' and x==math.floor(x) then return string.format('0x%X',x) end
  return tostring(x)
end
local function relevant(x)
  local s=tostring(x or ''):lower()
  for _,term in ipairs({'charact','faction','inventory','equip','weapon','army','player','unit',
    'vehicle','stock','item','resource','machinegun','artillery','tank','train','gun','supply','qi',
    'troop','inventory','store','politic','person','party','member','officer'}) do
    if s:find(term,1,true) then return true end
  end
  return false
end
local pid=(type(getOpenedProcessID)=='function' and getOpenedProcessID()) or 0
log('Rise Of The White Sun - Standalone MONO diagnostic v0.1.2')
log('Game PID: '..tostring(pid))
log('CE Mono helper can inject into game process; no gameplay stat changes or saves.')
local matched=0
local ok,err=xpcall(function()
  assert(pid~=0,'CE is not attached to a process')
  assert(type(LaunchMonoDataCollector)=='function','Cheat Engine Mono module missing')
  log('Stage 1: collector initialisation')
  local init=LaunchMonoDataCollector()
  assert(init~=false and init~=0 and init~=nil,'Mono initialisation failed: '..tostring(init))
  log('Mono collector return: '..ashex(init)..' ('..type(init)..')')
  local asms=mono_enumAssemblies()
  assert(type(asms)=='table','mono_enumAssemblies returned '..type(asms))
  log('Stage 2: assemblies = '..#asms)
  local found=false
  for _,a in ipairs(asms) do
    local yes,img=pcall(mono_getImageFromAssembly,a)
    if yes and type(img)=='number' and img~=0 then
      local got,name=pcall(mono_image_get_name,img)
      if got and type(name)=='string' and name:lower():find('assembly%-csharp') then
        found=true
        log('Stage 3: '..name..', image '..ashex(img))
        local classes=mono_image_enumClasses(img)
        assert(type(classes)=='table','mono_image_enumClasses returned '..type(classes))
        log('Classes found: '..#classes)
        log('=== ALL CLASS NAMES ===')
        for _,cl in ipairs(classes) do
          log(tostring(cl.namespace or '')..'.'..tostring(cl.classname or ''))
        end
        log('=== MATCHING CLASS FIELDS + METHODS ===')
        for _,cl in ipairs(classes) do
          local cname=tostring(cl.classname or '')
          local ns=tostring(cl.namespace or '')
          if relevant(cname) or relevant(ns) then
            matched=matched+1
            log(string.format('[%d] %s.%s classHandle=%s',matched,ns,cname,ashex(cl.class)))
            if type(mono_class_enumFields)=='function' then
              local fy,fields=pcall(mono_class_enumFields,cl.class)
              if fy and type(fields)=='table' then
                for _,f in ipairs(fields) do
                  log(string.format('  %s +0x%X type=%s monotype=%s static=%s',
                    tostring(f.name),tonumber(f.offset) or 0,tostring(f.typename),
                    tostring(f.monotype),tostring(f.isStatic)))
                end
              else
                log('  FIELD_ENUM_ERROR: '..tostring(fields))
              end
            end
            if type(mono_class_enumMethods)=='function' then
              local my,methods=pcall(mono_class_enumMethods,cl.class)
              if my and type(methods)=='table' then
                for j,m in ipairs(methods) do
                  if j>120 then log('  METHOD_LIST_TRUNCATED'); break end
                  log('  METHOD '..tostring(m.name))
                end
              elseif not my then
                log('  METHOD_ENUM_ERROR: '..tostring(methods))
              end
            end
            if matched>=300 then log('Capped at 300 matched class groups'); break end
          end
        end
        break
      end
    end
  end
  assert(found,'Assembly-CSharp not found')
end, function(e)
  if debug and type(debug.traceback)=='function' then return debug.traceback(tostring(e),2) end
  return tostring(e)
end)
log(ok and 'RESULT: SUCCESS' or 'RESULT: ERROR')
if not ok then log(err) end
log('Matched class groups: '..matched)
fh:close()
local summary='Mono report saved to:\n'..path..'\nStatus: '..(ok and 'SUCCESS' or 'ERROR')
if not ok then summary=summary..'\n'..tostring(err):sub(1,650) end
showMessage(summary)
