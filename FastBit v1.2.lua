--A fork of the original FastBit by WolftrooperNo86
--https://github.com/WolftrooperNo86/FastBit
--licensed under GNU General Public License v3.0.

local function saturate(cn, co, mxNew, mxPrev)
    -- co & 1 == 0 tests for even or odd, like co % 2.
    if cn > 0 and cn < mxNew and co & 1 == 0 then
        return cn + mxNew // mxPrev
    else
        return cn
    end
end

local function recalcColor(bd, r, g, b, a, constrainAlpha, aseColor)
    local ase = aseColor or Color(0, 0, 0, 0)

    local mx = (1 << bd) - 1
    ase.red = r * 255 // mx
    ase.green = g * 255 // mx
    ase.blue = b * 255 // mx

    if constrainAlpha then
        ase.alpha = a * 255 // mx
    else
        ase.alpha = a
    end

    return ase
end

local function colorToHexWeb(aseColor)
    return string.format("%06x",
        aseColor.red << 0x10
        | aseColor.green << 0x08
        | aseColor.blue)
end

local function updatePreview(dlg)
    local args = dlg.data
    local newClr = recalcColor(
            args.bitDepth,
            args.redChannel,
            args.greenChannel,
            args.blueChannel,
            args.alphaChannel,
            args.constrainAlpha)

    dlg:modify {
        id = "preview",
        colors = { newClr }
    }

    dlg:modify {
        id = "hexCode",
        text = colorToHexWeb(newClr)
    }
end

local function adoptAseColor(dlg, aseColor)

    local rOld = aseColor.red
    local gOld = aseColor.green
    local bOld = aseColor.blue
    local aOld = aseColor.alpha

    local rNew = rOld
    local gNew = gOld
    local bNew = bOld
    local aNew = aOld

    local args = dlg.data
    local bd = args.bitDepth
    if bd < 2 then
        if rOld < 127.5 then rNew = 0 else rNew = 1 end
        if gOld < 127.5 then gNew = 0 else gNew = 1 end
        if bOld < 127.5 then bNew = 0 else bNew = 1 end
        if args.constrainAlpha then
            aNew = 1
        end
    elseif bd < 8 then
        local mx = (1 << bd) - 1
        rNew = mx * rNew // 255
        gNew = mx * gNew // 255
        bNew = mx * bNew // 255

        rNew = saturate(rNew, rOld, mx, 255)
        gNew = saturate(gNew, gOld, mx, 255)
        bNew = saturate(bNew, bOld, mx, 255)

        if args.constrainAlpha then
            aNew = aNew * 255 // mx
            aNew = saturate(aNew, aOld, mx, 255)
        end
    end

    dlg:modify { id = "redChannel", value = rNew }
    dlg:modify { id = "greenChannel", value = gNew }
    dlg:modify { id = "blueChannel", value = bNew }
    dlg:modify { id = "alphaChannel", value = aNew }

    updatePreview(dlg)
end

local prevMax = 255

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

dlg:entry {
    id = "hexCode",
    label = "Hex #",
    text = "ffffff",
    focuse = false
}

dlg:slider {
    id = "bitDepth",
    label = "Depth",
    min = 1,
    max = 8,
    value = 8,
    onchange = function()
        local args = dlg.data

        local bd = args.bitDepth
        local rOld = args.redChannel
        local gOld = args.greenChannel
        local bOld = args.blueChannel
        local aOld = args.alphaChannel

        local rNew = rOld
        local gNew = gOld
        local bNew = bOld
        local aNew = aOld

        -- 2 ^ n = 1 << n
        local newMax = (1 << bd) - 1
        if bd < 2 then
            local halfMax = prevMax * 0.5
            if rOld < halfMax then rNew = 0 else rNew = 1 end
            if gOld < halfMax then gNew = 0 else gNew = 1 end
            if bOld < halfMax then bNew = 0 else bNew = 1 end
            if args.constrainAlpha then
                aNew = 1
            end
        elseif newMax < prevMax then
            -- Issue with slider drift when moving from more to less
            -- information. E.g., 127 * 85 // 255 = 42
            --                    255 * 42 // 127 = 84
            --                    127 * 84 // 255 = 41
            --                    255 * 41 // 127 = 82
            -- To fix, an increment is added to odd numbers unless they
            -- are on either the lower or upper bound.

            rNew = newMax * rOld // prevMax
            gNew = newMax * gOld // prevMax
            bNew = newMax * bOld // prevMax

            rNew = saturate(rNew, rOld, newMax, prevMax)
            gNew = saturate(gNew, gOld, newMax, prevMax)
            bNew = saturate(bNew, bOld, newMax, prevMax)

            if args.constrainAlpha then
                aNew = newMax * aOld // prevMax
                aNew = saturate(aNew, aOld, newMax, prevMax)
            end
        elseif newMax > prevMax then
            rNew = newMax * rOld // prevMax
            gNew = newMax * gOld // prevMax
            bNew = newMax * bOld // prevMax

            if args.constrainAlpha then
                aNew = newMax * aOld // prevMax
            end
        end

        dlg:modify { id = "redChannel", max = newMax }
        dlg:modify { id = "greenChannel", max = newMax }
        dlg:modify { id = "blueChannel", max = newMax }

        dlg:modify { id = "redChannel", value = rNew }
        dlg:modify { id = "greenChannel", value = gNew }
        dlg:modify { id = "blueChannel", value = bNew }

        if args.constrainAlpha then
            dlg:modify { id = "alphaChannel", max = newMax }
            dlg:modify { id = "alphaChannel", value = aNew }
        end

        updatePreview(dlg)

        prevMax = newMax
    end
}

dlg:slider {
    id = "redChannel",
    label = "R",
    min = 0,
    max = 255,
    value = 255,
    onchange = function()
        updatePreview(dlg)
    end
}

dlg:slider {
    id = "greenChannel",
    label = "G",
    min = 0,
    max = 255,
    value = 255,
    onchange = function()
        updatePreview(dlg)
    end
}

dlg:slider {
    id = "blueChannel",
    label = "B",
    min = 0,
    max = 255,
    value = 255,
    onchange = function()
        updatePreview(dlg)
    end
}

dlg:slider {
    id = "alphaChannel",
    label = "A",
    min = 0,
    max = 255,
    value = 255,
    onchange = function()
        updatePreview(dlg)
    end
}

dlg:check {
    id = "constrainAlpha",
    text = "Reduce Alpha",
    selected = false,
    onclick = function()
        local args = dlg.data
        if args.constrainAlpha then
            local bd = args.bitDepth
            local newMax = (1 << bd) - 1
            dlg:modify { id = "alphaChannel", max = newMax }
            dlg:modify { id = "alphaChannel", value = newMax }
        else
            dlg:modify { id = "alphaChannel", max = 255 }
            dlg:modify { id = "alphaChannel", value = 255 }
        end

        updatePreview(dlg)
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