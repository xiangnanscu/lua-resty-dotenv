local os = os
local gmatch = ngx.re.gmatch
local match = ngx.re.match
local gsub = ngx.re.gsub

-- https://github.com/motdotla/dotenv/blob/master/lib/main.js
local LINE =
[[(?:^|^)\s*(?:export\s+)?([\w.-]+)(?:\s*=\s*?|:\s+?)(\s*'(?:\\'|[^'])*'|\s*"(?:\\"|[^"])*"|\s*`(?:\\`|[^`])*`|[^#\r\n]+)?\s*(?:#.*)?(?:$|$)]]

local function dict(a, b)
  local t = {}
  for key, value in pairs(a) do
    t[key] = value
  end
  for key, value in pairs(b) do
    t[key] = value
  end
  return t
end

local function split(s, sep)
  local res = {}
  sep = sep or " "
  local i = 1
  local a, b
  while true do
    a, b = s:find(sep, i, true)
    if a then
      local e = s:sub(i, a - 1)
      i = b + 1
      res[#res + 1] = e
    else
      res[#res + 1] = s:sub(i)
      return res
    end
  end
end

local function parse(src)
  local obj = {}
  local it = assert(gmatch(src, LINE, "msui"))
  while true do
    local m, err = it()
    if err then
      return nil, err
    end
    if not m then
      break
    end
    local key = m[1]
    local value = m[2] or ""
    value = (value:gsub("^%s*(.-)%s*$", "%1"))
    local maybeQuote = value:sub(1, 1);
    -- remove surrounding quotes
    value = (value:gsub([[^(['"`])([%s%S]*)%1$]], "%2"))
    if maybeQuote == '"' then
      value = value:gsub([[\n]], "\n")
      value = value:gsub([[\r]], "\r")
    end
    obj[key] = value;
  end
  return obj;
end

---@param env_value string
---@param env table
---@return string
local function expand_key(env_value, env)
  local index = 0
  for m in gmatch(env_value, [[(.?\${*[\w]*(?::-[\w/]*)?}*)]], 'msui') do
    index = index + 1
    local parts = assert(match(m[1], [[(.?)\${*([\w]*(?::-[\w/]*)?)?}*]]))
    local prefix = parts[1]
    local value, replacePart;
    if prefix == '\\' then
      ---@type string
      replacePart = parts[1];
      value = replacePart:sub(2)
    else
      local keyParts = split(parts[2], ':-')
      local key = keyParts[1]
      replacePart = parts[0]:sub(#prefix + 1);
      local ek = os.getenv(key)
      if ek ~= nil then
        value = ek
      else
        value = env[key] or keyParts[2] or ""
      end
      -- if #keyParts>1 and value then
      --   local replaceNested = ""
      -- end
      value = expand_key(value, env)
    end
    env_value = assert(gsub(env_value, '\\' .. replacePart, value))
  end
  return env_value
end

local function expand(env)
  for key, value in pairs(env) do
    env[key] = expand_key(value, env)
  end
  return env
end

local function make(opts)
  opts = opts or {}
  local path
  local env = {}
  if opts.path == nil then
    path = '.env'
  elseif type(opts.path) == 'string' then
    path = opts.path
  elseif type(opts.path) == 'table' then
    for _, p in ipairs(opts.path) do
      for key, value in pairs(make(dict(opts, { path = p }))) do
        env[key] = value
      end
    end
  else
    error("invald path type:" .. type(opts.path))
  end
  if path then
    local file = io.open(path, "r")
    if file then
      env = dict(env, assert(parse(file:read("*a"))))
    end
  end
  return env
end

local function parsing_file(opts)
  return expand(make(opts))
end

local JSON_ENV
local function getenv(key)
  if not JSON_ENV then
    local json = parsing_file { path = { '.env', '.env.local' } }
    JSON_ENV = json
  end
  if key then
    return JSON_ENV[key]
  else
    return JSON_ENV
  end
end

local dotenv = setmetatable({ parse = parse, make = make, expand = expand, getenv = getenv },
  {
    __call = function(t, opts)
      return parsing_file(opts)
    end
  })

dotenv.__index = dotenv

return dotenv
