









local L = require "lpeg"

local s = require "singletons/status" ()
s.verbose = true

local pl_mini = require "util/plmini"
local getfiles = pl_mini.dir.getfiles
local makepath = pl_mini.dir.makepath
local getdirectories = pl_mini.dir.getdirectories
local extension = pl_mini.path.extension
local dirname = pl_mini.path.dirname
local basename = pl_mini.path.basename
local read = pl_mini.file.read
local write = pl_mini.file.write
local isdir = pl_mini.path.isdir

local u = {}
function u.inherit(meta)
  local MT = meta or {}
  local M = setmetatable({}, MT)
  M.__index = M
  local m = setmetatable({}, M)
  m.__index = m
  return M, m
end
function u.export(mod, constructor)
  mod.__call = constructor
  return setmetatable({}, mod)
end

local a = require "singletons/anterm"

local m = require "orb:Orbit/morphemes"
local walk = require "orb:walk/walk"
local strHas = walk.strHas
local endsWith = walk.endsWith
local subLastFor = walk.subLastFor
local writeOnChange = walk.writeOnChange
local Path = require "orb:walk/path"
local Dir = require "orb:walk/directory"
local File = require "orb:walk/file"
local epeg = require "orb:util/epeg"

local Doc = require "orb:Orbit/doc"

local W, w = u.inherit()



function W.weaveMd(weaver, doc)
  return doc:toMarkdown()
end










local popen = io.popen
local function dotToSvg(dotted, out_file)
    local success, svg_file = pcall (popen,
                          "dot -Tsvg " .. tostring(out_file), "r")
    if success then
        return svg_file:read("*a")
    else
        -- #todo start using %d and format!
        s:complain("dotError", "dot failed with " .. success)
    end
end





local function weave_dir(weaver, pwd, depth)
    local depth = depth + 1
    for dir_str in pl_mini.dir.walk(pwd, false, false) do
        local dir = Dir(dir_str)
        if not strHas(".git", dir.path.str)
            and not strHas("src/lib", dir.path.str) then
            dir = dir.path.str -- migrate this down
            local files = getfiles(dir)
            s:verb(("  "):rep(depth) .. "* " .. dir)
            local subdirs = getdirectories(dir)
            for _, f in ipairs(files) do
                if extension(f) == ".orb" then
                    -- Weave and prepare out directory
                    s:verb(("  "):rep(depth) .. "  - " .. f)
                    local orb_f = read(f)
                    local doc = Doc(orb_f)
                    local doc_md_dir = subLastFor("/orb", "/doc/md", dirname(f))
                    local doc_dot_dir = subLastFor("/orb", "/doc/dot", dirname(f))
                    local doc_svg_dir = subLastFor("/orb", "/doc/svg", dirname(f))
                    makepath(doc_md_dir)
                    makepath(doc_dot_dir)
                    makepath(doc_svg_dir)
                    local bare_name = basename(f):sub(1, -5) --  == #".orb"
                    local out_md_name = doc_md_dir .. "/" .. bare_name .. ".md"
                    local out_dot_name = doc_dot_dir .. "/" .. bare_name .. ".dot"
                    local out_svg_name = doc_svg_dir .. "/" .. bare_name .. ".svg"
                    local woven_md = weaver:weaveMd(doc) or ""

                    -- Compare, report, and write out if necessary
                    local last_md = read(out_md_name) or ""
                    local changed_md = writeOnChange(woven_md, last_md, out_md_name, depth)
                    local woven_dot = doc:dot() or ""
                    local last_dot = read(out_dot_name) or ""
                    local changed_dot = writeOnChange(woven_dot, last_dot, out_dot_name, depth)

                    -- SVG call is fairly slow and only useful of the dot has changed
                    if changed_dot then
                        local woven_svg = dotToSvg(woven_dot, out_dot_name)
                        local last_svg = read(out_svg_name) or ""
                        writeOnChange(woven_svg, last_svg, out_svg_name, depth)
                    end
                end
            end
        end
    end

    return true
end

local function weave_all(weaver, pwd)
    for dir in pl_mini.dir.walk(pwd, false, false) do
        if not strHas(".git", dir) and isdir(dir)
            and endsWith("orb", dir) then
            s:chat(a.cyan("Weave: " .. dir))
            return weave_dir(weaver, dir, 0)
        end
    end

    return false
end

W.weave_all = weave_all













local function weaveDeck(weaver, deck)
    local dir = deck.dir
    local codex = deck.codex
    local orbDir = codex.orb
    local docMdDir = codex.docMd
    s:verb ("weaving " .. tostring(deck.dir))
    s:verb ("into " .. tostring(docMdDir))
    for i, sub in ipairs(deck) do
        weaveDeck(weaver, sub)
    end
    for name, doc in pairs(deck.docs) do
        local woven = weaver:weaveMd(doc)
        if woven then
            -- add to docMds
            local docMdPath = Path(name):subFor(orbDir, docMdDir, ".md")
            s:verb("wove: " .. name)
            s:verb("into:    " .. tostring(docMdPath))
            deck.docMds[docMdPath] = woven
            codex.docMds[docMdPath] = woven
        end

    end
    return deck.docMds
end

W.weaveDeck = weaveDeck



function W.weaveCodex(weaver, codex)
   print "weaving CODEX"
   local orb = codex.orb
   weaveDeck(weaver, orb)
   for name, docMd in pairs(codex.docMds) do
      walk.writeOnChange(name, docMd)
   end
end



local function new(Weaver, doc)
    local weaver = setmetatable({}, W)


    return weaver
end



return W
