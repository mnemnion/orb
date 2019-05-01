










local sql = require "sqlite"
local pcall = assert (pcall)
local gsub = assert(string.gsub)
local format = assert(string.format)
local ffi = require "ffi"
assert(ffi)
ffi.reflect = require "reflect"
assert(ffi.reflect)










-- get a conn object via in-memory DB
local conn = sql.open ":memory:"
local conn_mt = ffi.reflect.getmetatable(conn)
local stmt = conn:prepare "CREATE TABLE IF NOT EXISTS test(a,b);"
local stmt_mt = ffi.reflect.getmetatable(stmt)

stmt:close()
conn:close() -- polite
conn, stmt = nil, nil







local function san(str)
   return gsub(str, "'", "''")
end

sql.san = san

























function sql.format(str, ...)
   local argv = {...}
   str = gsub(str, "%%s", "'%%s'"):gsub("''%%s''", "'%%s'")
   for i, v in ipairs(argv) do
      if type(v) == "string" then
         argv[i] = san(v)
      elseif type(v) == "cdata" then
         -- assume this is a number of some kind
         argv[i] = tonumber(v)
      else
         argv[i] = v
      end
   end
   local success, ret = pcall(format, str, unpack(argv))
   if success then
      return ret
   else
      return success, ret
   end
end









function sql.pexec(conn, stmt, col_str)
   -- conn:exec(stmt)
   col_str = col_str or "hik"
   local success, result, nrow = pcall(conn.exec, conn, stmt, col_str)
   if success then
      return result, nrow
   else
      return false, result
   end
end










function sql.lastRowId(conn)
   local result = conn:rowexec "SELECT CAST(last_insert_rowid() AS REAL)"
   return result
end


















local pragma_pre = "PRAGMA "

-- Builds and returns a pragma string
local function __pragma(prag, value)
   local val
   if value == nil then
      return pragma_pre .. prag .. ";"
   end
   if type(value) == "boolean" then
      val = value and " = 1" or " = 0"
   elseif type(value) == "string" then
      val = "('" .. san(value) .. "')"
   elseif type(value) == "number" then
      val = " = " .. tostring(value)
   else
      error(false, "value of type " .. type(value) .. ", " .. tostring(value))
   end
   return pragma_pre .. prag .. val .. ";"
end

-- Sets a pragma and checks its new value
local function _prag_set(conn, prag)
   return function(value)
      local prag_str = __pragma(prag, value)
      conn:exec(prag_str)
      -- check for a boolean
      -- #todo make sure this gives sane results for a method-call pragma
      local answer = conn:exec(pragma_pre .. prag .. ";")
      if answer[1] and answer[1][1] then
         if answer[1][1] == 1 then
            return true
         elseif answer[1][1] == 0 then
            return false
         else
            return nil
         end
      end
   end
end






local function new_conn_index(conn, key)
   local function _prag_index(_, prag)
      return _prag_set(conn, prag)
   end
   if key == "pragma" then
      return setmetatable({}, {__index = _prag_index})
   else
      return conn_mt[key]
   end
end

conn_mt.__index = new_conn_index




return sql
