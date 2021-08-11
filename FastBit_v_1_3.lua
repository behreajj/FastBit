--A fork of the original FastBit by WolftrooperNo86
--https://github.com/WolftrooperNo86/FastBit
--licensed under GNU General Public License v3.0.

local function colorToHexWeb(aseColor)
    return string.format("%06x",
        aseColor.red << 0x10
        | aseColor.green << 0x08
        | aseColor.blue)
end

local function expandColorTo256(
    rDepth, gDepth, bDepth, aDepth,
    r, g, b, a,
    aseColor)

    local ase = aseColor or Color(0, 0, 0, 0)

    ase.red = r * 255 // ((1 << rDepth) - 1)
    ase.green = g * 255 // ((1 << gDepth) - 1)
    ase.blue = b * 255 // ((1 << bDepth) - 1)
    ase.alpha = a * 255 // ((1 << aDepth) - 1)

    return ase
end

local function saturate(cn, co, mxNew, mxPrev)
    -- co & 1 == 0 tests for even or odd, like co % 2.
    if cn > 0 and cn < mxNew and co & 1 == 0 then
        -- return cn + mxNew // mxPrev
        return cn + 1
    else
        return cn
    end
end

local function contract256Channel(cDepth, cOld)
    local cNew = cOld
    if cDepth < 2 then
        if cOld < 128 then cNew = 0 else cNew = 1 end
    elseif cDepth < 8 then
        local cMax = (1 << cDepth) - 1
        cNew = math.ceil(cMax * cNew * 0.00392156862745098)
    end
    return cNew
end

local function contract256Color(
    rDepth, gDepth, bDepth, aDepth,
    r, g, b, a)

    local rNew = contract256Channel(rDepth, r)
    local gNew = contract256Channel(gDepth, g)
    local bNew = contract256Channel(bDepth, b)
    local aNew = contract256Channel(aDepth, a)

    return rNew, gNew, bNew, aNew
end

local function updatePreview(dialog)
    local args = dialog.data

    local newClr = expandColorTo256(
        args.redDepth,
        args.greenDepth,
        args.blueDepth,
        args.alphaDepth,

        args.redChannel,
        args.greenChannel,
        args.blueChannel,
        args.alphaChannel)

    dialog:modify {
        id = "preview",
        colors = { newClr }
    }

    dialog:modify {
        id = "hexCode",
        text = colorToHexWeb(newClr)
    }
end

local function adoptAseColor(dlg, aseColor)
    local args = dlg.data
    local rNew, gNew, bNew, aNew = contract256Color(
        args.redDepth,
        args.greenDepth,
        args.blueDepth,
        args.alphaDepth,
        aseColor.red,
        aseColor.green,
        aseColor.blue,
        aseColor.alpha)

    -- TODO: Reciprocity problem: Where getting a color
    -- from the wheel created by the same channel values
    -- is one less than it should be.
    dlg:modify { id = "redChannel", value = rNew }
    dlg:modify { id = "greenChannel", value = gNew }
    dlg:modify { id = "blueChannel", value = bNew }
    dlg:modify { id = "alphaChannel", value = aNew }

    updatePreview(dlg)
end

local function updateSlider(dialog, depth, oldVal, maxPrev, sliderName)
    local newVal = oldVal
    local newMax = (1 << depth) - 1
    if depth < 2 then
        local halfMax = maxPrev * 0.5
        if oldVal < halfMax then newVal = 0 else newVal = 1 end
    else
        newVal = newMax * oldVal // maxPrev
        if newMax < maxPrev then
            newVal = saturate(newVal, oldVal, newMax, maxPrev)
        end
    end

    dialog:modify { id = sliderName, max = newMax }
    dialog:modify { id = sliderName, value = newVal }

    return newMax
end

local rMaxPrev = 255
local gMaxPrev = 255
local bMaxPrev = 255
local aMaxPrev = 255

local dlg = Dialog { title = "Low Bits" }

dlg:button {
    id = "getFore",
    label = "Get",
    text = "&FORE",
    focus = false,
    onclick = function()
        local srcClr = app.fgColor
        adoptAseColor(dlg, srcClr)
    end
}

dlg:button {
    id = "getBack",
    text = "&BACK",
    focus = false,
    onclick = function()
        app.command.SwitchColors()
        local srcClr = app.fgColor
        app.command.SwitchColors()
        adoptAseColor(dlg, srcClr)
    end
}

dlg:newrow { always = false }

dlg:shades {
    id = "preview",
    label = "Color",
    mode = "pick",
    colors = { Color(255, 255, 255, 255) },
    onclick=function(ev)
        if ev.button == MouseButton.LEFT then
            app.fgColor = ev.color
        elseif ev.button == MouseButton.RIGHT then
            -- Bug where assigning to app.bgColor leads to
            -- unlocked palette color assignment instead.
            -- app.bgColor = ev.color
            app.command.SwitchColors()
            app.fgColor = ev.color
            app.command.SwitchColors()
        end
    end
}

dlg:newrow { always = false }

dlg:entry {
    id = "hexCode",
    label = "Hex #",
    text = "ffffff",
    focuse = false
}

dlg:separator{
    id = "channelsSep",
    text = "Depth - Value" }

-- dlg:check {
--     id = "uniformDepth",
--     label = "Uniform",
--     selected = true,
--     onclick = function()
--     end
-- }

dlg:newrow { always = false }

dlg:slider {
    id = "redDepth",
    -- label = "Depth R",
    label = "Red",
    min = 1,
    max = 8,
    value = 8,
    onchange = function()
        local args = dlg.data
        rMaxPrev = updateSlider(
            dlg, args.redDepth,
            args.redChannel, rMaxPrev,
            "redChannel")
        updatePreview(dlg)
    end
}

dlg:slider {
    id = "redChannel",
    -- label = "R",
    min = 0,
    max = 255,
    value = 255,
    onchange = function()
        updatePreview(dlg)
    end
}

dlg:newrow { always = false }

dlg:slider {
    id = "greenDepth",
    -- label = "Depth G",
    label = "Green",
    min = 1,
    max = 8,
    value = 8,
    onchange = function()
        local args = dlg.data
        gMaxPrev = updateSlider(
            dlg, args.greenDepth,
            args.greenChannel, gMaxPrev,
            "greenChannel")
        updatePreview(dlg)
    end
}

dlg:slider {
    id = "greenChannel",
    -- label = "G",
    min = 0,
    max = 255,
    value = 255,
    onchange = function()
        updatePreview(dlg)
    end
}

dlg:newrow { always = false }

dlg:slider {
    id = "blueDepth",
    -- label = "Depth B",
    label = "Blue",
    min = 1,
    max = 8,
    value = 8,
    onchange = function()
        local args = dlg.data
        bMaxPrev = updateSlider(
            dlg, args.blueDepth,
            args.blueChannel, bMaxPrev,
            "blueChannel")
        updatePreview(dlg)
    end
}

dlg:slider {
    id = "blueChannel",
    -- label = "B",
    min = 0,
    max = 255,
    value = 255,
    onchange = function()
        updatePreview(dlg)
    end
}

dlg:newrow { always = false }

dlg:slider {
    id = "alphaDepth",
    -- label = "Depth A",
    label = "Alpha",
    min = 1,
    max = 8,
    value = 8,
    onchange = function()
        local args = dlg.data
        aMaxPrev = updateSlider(
            dlg, args.alphaDepth,
            args.alphaChannel, aMaxPrev,
            "alphaChannel")
        updatePreview(dlg)
    end
}

dlg:slider {
    id = "alphaChannel",
    -- label = "A",
    min = 0,
    max = 255,
    value = 255,
    onchange = function()
        updatePreview(dlg)
    end
}

dlg:newrow { always = false }

dlg:button {
    id = "colorWheel",
    text = "&WHEEL",
    focus = false,
    onclick = function()

        local args = dlg.data
        local rDepth = args.redDepth
        local gDepth = args.greenDepth
        local bDepth = args.blueDepth
        local aDepth = args.alphaDepth
        local maxDepth = math.max(rDepth, gDepth, bDepth)
        local frameCount = 1 + (1 << maxDepth)

        local width = 256
        local height = 256
        local sprite = Sprite(width, height)
        local layer = sprite.layers[1]
        layer.name = string.format("Color.Wheel.R%d.G%d.B%d",
            rDepth, gDepth, bDepth)

        local cels = { sprite.cels[1] }
        app.transaction(function()
            for i = 2, frameCount, 1 do
                local frame = sprite:newEmptyFrame()
                local cel = sprite:newCel(layer, frame)
                cels[i] = cel
            end
        end)

        local clrDict = {}
        app.transaction(function()
            local iToPercent = 1.0 / (frameCount + 1.0)
            local xToPercent = 1.0 / (width - 1.0)
            local yToPercent = 1.0 / (height - 1.0)
            local atan2 = math.atan
            local deg = math.deg
            local sqrt = math.sqrt
            local rt_2 = 1.4142135623730951
            for i = 0, frameCount - 1, 1 do
                local cel = cels[i + 1]
                local image = Image(width, height)
                local itr = image:pixels()
                local iPrc = (i + 1) * iToPercent
                for elm in itr do
                    local x = elm.x
                    local xPrc = x * xToPercent
                    local xSgn = xPrc + xPrc - 1.0

                    local y = elm.y
                    local yPrc = y * yToPercent
                    local ySgn = yPrc + yPrc - 1.0

                    local magSq = xSgn * xSgn + ySgn * ySgn
                    if magSq > 0.000001 and magSq <= 1.0 then
                        local angleRad = atan2(ySgn, xSgn)
                        local angleDeg = deg(angleRad) % 360.0
                        local sat = sqrt(magSq * rt_2)
                        local aseColor = Color {
                            h = angleDeg,
                            s = sat,
                            l = iPrc,
                            a = 255
                        }

                        local r = aseColor.red
                        local g = aseColor.green
                        local b = aseColor.blue
                        local a = aseColor.alpha

                        r, g, b, a = contract256Color(
                            rDepth,
                            gDepth,
                            bDepth,
                            aDepth,
                            r, g, b, a)

                        local newClr = expandColorTo256(
                            rDepth,
                            gDepth,
                            bDepth,
                            aDepth,
                            r, g, b, a,
                            aseColor)

                        local hex = newClr.rgbaPixel
                        clrDict[hex] = true
                        elm(hex)
                    else
                        local aseColor = Color {
                            h = 0.0,
                            s = 0.0,
                            l = iPrc,
                            a = 255
                        }
                        elm(aseColor.rgbaPixel)
                    end
                end

                cel.image = image
            end
        end)

        local clrArr = {}
        for k, _ in pairs(clrDict) do
            table.insert(clrArr, Color(k))
        end
        local clrsLen = #clrArr

        local palette = Palette(math.min(256, clrsLen + 1))
        palette:setColor(0, Color(0, 0, 0, 0))
        for i = 1, #palette - 1, 1 do
            palette:setColor(i, clrArr[i])
        end

        sprite:setPalette(palette)

        app.activeFrame = 1 + frameCount // 2
        app.refresh()
    end
}

dlg:button {
    id = "cancel",
    text = "&CANCEL",
    focus = false,
    onclick = function()
        dlg:close()
    end
}

dlg:show { wait = false }

-- local mx = (1 << 6) - 1
-- local str = ""
-- local prev = 0
-- for i = 0, mx, 1 do
--     local c = recalcColor(
--         6,
--         i,i,i, 255, false)
--     str = str .. string.format("%d|%d|%02X|%d\n", i, c.blue, c.blue, c.blue - prev)

--     prev = c.blue
-- end
-- print(str)

-- local file = io.open("C:\\Users\\Jeremy Behreandt\\blah.txt", "a")
-- file:write(str, "\n")
-- file:close()
-- return