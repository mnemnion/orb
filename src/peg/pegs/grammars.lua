local pl = require "pl.file"
local read = pl.read

local g = {}

 g.wtf = [[S: ``T`` (U V)]]
 g.grammar_s = [[ A  : B      C ( E / F ) / G H
			  I : "J" 
			  K : L* M+ N?
			  O : !P &Q !R*
			  `S` : ``T`` (U V)
			  W : {XY} [a-z] 
			  A : (B$2)* C$-3 D$4..5* E$+4
        ]]

 g.deco_s  = [[ A: `-(B C/ D)$2..5*` ]]
 g.rule_s  = [[A:B C(D E)/(F G H)
			  C : "D" 
			  D : E F G
]]

 g.peg_s =  read "peg/pegs/peg.peg"
 g.lisp_s = read "peg/pegs/lisp.peg"
 g.clu_s =  read "peg/pegs/clu.peg"
return g