







local Node    =  require "espalier/node"
local Grammar =  require "espalier/grammar"
local L       =  require "espalier/elpatt"

local P, R, E, V, S    =  L.P, L.R, L.E, L.V, L.S

local _ = (P" " + P"\n" + P"\t" + P"\r")^0

local IDstart =  R("az", "AZ") + "_" -- dot is actually latin-1 but
local IDrest  =  IDstart + R"09"

local num     =  P"-"^0 * (P"." + R"09"^1)
              +  R"09"^1 * P"."^0 * R"09"^0

local string_patt = P"\"" * (P(1) - (P"\"" * - P"\\\""))^0 * P"\""

local function dot_fn(_ENV)
  START "dot"

  dot =  _ * P"strict"^0 * _ * (P"graph" + P"digraph")
      *  _ * V"ID"^0 * _ * "{" * _ * V"statment_list" * _ * "}" * _

  statement_list =  V"statement"^0 * _ * ";"^0 * _ * V"statement"^0

  statement  =  V"node_statement"
             +  V"edge_statement"
             +  V"attr_statement"
             +  V"ID" * _ * "=" * _ * V"ID"
             +  subgraph

  attr_statement =  (P"graph" + "espalier/node" + "edge") * attr_list
  attr_list      =  P"[" * _ * V"a_list"^0 * _ * P"]" * _ * V"attr_list"^0
  a_list         =  V"ID" * _ * "=" * _ * V"ID"
                 * (P";" + P",")^0 * _ * V"a_list"^0

  edge_statement =  (V"node_id" + V"subgraph") * _ * V"edgeRHS" * V"attr_list"^0
  edgeRHS        =  V"edgeop" * _ * (V"node_id" + V"subgraph") * _ * V"edgeRHS"^0

  node_statement =  V"node_id" * _ * V"attr_list"^0
  node_id        =  V"ID" * _ * V"port"^0
  port           =  P":" * _ * V"ID" * _ * (P":" * _ * V"compass_point")^0

  subgraph       =  (P"subgraph" * _ * V"ID"^0)^0 * _
                 *  "{" * _ * V"statement_list" * _ * "}"

  compass_point  =  S("n","ne","e","se","s","sw","w","nw","_")

  ID    =  (IDstart^1 * IDrest^0) + num + string_patt

  -- Add C-style comments

end

