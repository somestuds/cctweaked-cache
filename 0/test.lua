local function drawCircle(cx, cy, r, color)
    term.setBackgroundColor(color)

    local x = r
    local y = 0
    local err = 0

    while x >= y do
        paintutils.drawPixel(cx + x, cy + y, color)
        paintutils.drawPixel(cx + y, cy + x, color)
        paintutils.drawPixel(cx - y, cy + x, color)
        paintutils.drawPixel(cx - x, cy + y, color)

        paintutils.drawPixel(cx - x, cy - y, color)
        paintutils.drawPixel(cx - y, cy - x, color)
        paintutils.drawPixel(cx + y, cy - x, color)
        paintutils.drawPixel(cx + x, cy - y, color)

        y = y + 1

        if err <= 0 then
            err = err + 2*y + 1
        end

        if err > 0 then
            x = x - 1
            err = err - 2*x - 1
        end
    end
end

drawCircle(20, 10, 6, colors.red)