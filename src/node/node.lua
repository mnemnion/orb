













local N = {}
N.__index = N
N.isNode = true















function N.toString(Node, depth)
   local depth = depth or 0
   local phrase = ""
   phrase = ("  "):rep(depth) .. "id: " .. Node.id .. ",  "
      .. "first: " .. Node.first .. ", last: " .. Node.last .. "\n"
   if Node[1] then
    for _,v in ipairs(Node) do
      if(v.isNode) then
        phrase = phrase .. N.toString(v, depth + 1)
      end
    end
  end 
   return phrase
end





























































































return N
