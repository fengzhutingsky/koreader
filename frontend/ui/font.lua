local lfs = require("libs/libkoreader-lfs")
local Freetype = require("ffi/freetype")
local Screen = require("device").screen
local DEBUG = require("dbg")

local Font = {
    fontmap = {
        -- default font for menu contents
        cfont = "noto/NotoSans-Regular.ttf",
        -- default font for title
        --tfont = "NimbusSanL-BoldItal.cff",
        tfont = "noto/NotoSans-Bold.ttf",
        -- default font for footer
        ffont = "noto/NotoSans-Regular.ttf",

        -- default font for reading position info
        rifont = "noto/NotoSans-Regular.ttf",

        -- default font for pagination display
        pgfont = "noto/NotoSans-Regular.ttf",

        -- selectmenu: font for item shortcut
        scfont = "droid/DroidSansMono.ttf",

        -- help page: font for displaying keys
        hpkfont = "droid/DroidSansMono.ttf",
        -- font for displaying help messages
        hfont = "noto/NotoSans-Regular.ttf",

        -- font for displaying input content
        -- we have to use mono here for better distance controlling
        infont = "droid/DroidSansMono.ttf",

        -- font for info messages
        infofont = "noto/NotoSans-Regular.ttf",
    },
    fallbacks = {
        [1] = "droid/DroidSansFallback.ttf",
        [2] = "noto/NotoSans-Regular.ttf",
        [3] = "droid/DroidSans.ttf",
        [4] = "freefont/FreeSans.ttf",
    },

    fontdir = "./fonts",

    -- face table
    faces = {},
}


function Font:getFace(font, size)
    if not font then
        -- default to content font
        font = self.cfont
    end

    -- original size before scaling by screen DPI
    local orig_size = size
    local size = Screen:scaleBySize(size)

    local face = self.faces[font..size]
    -- build face if not found
    if not face then
        local realname = self.fontmap[font]
        if not realname then
            realname = font
        end
        realname = self.fontdir.."/"..realname
        ok, face = pcall(Freetype.newFace, realname, size)
        if not ok then
            DEBUG("#! Font "..font.." ("..realname..") not supported: "..face)
            return nil
        end
        self.faces[font..size] = face
    --DEBUG("getFace, found: "..realname.." size:"..size)
    end
    return { size = size, orig_size = orig_size, ftface = face, hash = font..size }
end

function Font:_readList(target, dir)
    -- lfs.dir non-exsitent directory will give error, weird!
    local ok, iter, dir_obj = pcall(lfs.dir, dir)
    if not ok then return end
    for f in iter, dir_obj do
        if lfs.attributes(dir.."/"..f, "mode") == "directory" and f ~= "." and f ~= ".." then
            self:_readList(target, dir.."/"..f)
        else
            local file_type = string.lower(string.match(f, ".+%.([^.]+)") or "")
            if file_type == "ttf" or file_type == "ttc"
                or file_type == "cff" or file_type == "otf" then
                table.insert(target, dir.."/"..f)
            end
        end
    end
end

function Font:getFontList()
    local fontlist = {}
    self:_readList(fontlist, self.fontdir)
    -- multiple path should be joined with semicolon in FONTDIR env variable
    for dir in string.gmatch(os.getenv("EXT_FONT_DIR") or "", "([^;]+)") do
        self:_readList(fontlist, dir)
    end
    table.sort(fontlist)
    return fontlist
end

function Font:update()
    for _k, _v in ipairs(self.faces) do
        _v:done()
    end
    self.faces = {}
    clearGlyphCache()
end

return Font
