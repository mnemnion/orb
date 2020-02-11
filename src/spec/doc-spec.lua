


local Dir = require "fs/directory"
local Doc = require "orb:orb/doc"



local testsDir = Dir "test"



for file in testsDir:files() do
   local doc = Doc(file:read())
   if doc then
      local nomatch = doc:select "NOMATCH" ()
      if nomatch then
         io.write"Unmatched Node:\n"
         for unmatched in doc:select "NOMATCH" do
            io.write(tostring(unmatched:strLine()) .. "\n")
         end
      end
      local incomplete = doc:select "INCOMPLETE" ()
      if incomplete then
         io.write "Incomplete Node:\n"
         for uncompleted in doc:select "INCOMPLETE" do
            io.write(tostring(uncompleted:strLine()) .. "\n")
         end
      end
   end
end
