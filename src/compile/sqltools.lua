







local sql = assert (sql)



local SQLtools = {}














function SQLtools.unwrapKey(result_set)
   if result_set and result_set[1] and result_set[1][1] then
      local id = result_set[1][1]
      if type(id) == "cdata" then
         return tonumber(id)
      else
         return id
      end
   else
      return nil
   end
end





















function SQLtools.tableResults(sql_result, num)
   local one_result = false
   local result_tab = {}
   if not num then
      num = 1
      one_result = true
   end
   assert(type(num) == "number" or num == "all")
   for key, column in pairs(sql_result) do
      if type(key) == "string" then
         if num == "all" then
            for i,v in pairs(column) do
               if type(v) == "cdata" then
                  v = tonumber(v)
               end
               result_tab[i] = result_tab[i] or {}
               result_tab[i][key] = v
            end
         else
            for i = 1, num do
               local v = type(column[i]) == "cdata"
                         and tonumber(column[i])
                         or column[i]
               result_tab[i] = result_tab[i] or {}
               result_tab[i][key] = v
            end
         end
      end
   end
   if one_result then
      return result_tab[1]
   else
      return result_tab
   end
end



return SQLtools
