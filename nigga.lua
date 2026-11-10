local Tween = {}
Tween.__index = Tween

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function lerpColor(a, b, t)
    return Color3.new(
        lerp(a.R, b.R, t),
        lerp(a.G, b.G, t),
        lerp(a.B, b.B, t)
    )
end

local function lerpUDim2(a, b, t)
    return UDim2.new(
        lerp(a.X.Scale, b.X.Scale, t),
        lerp(a.X.Offset, b.X.Offset, t),
        lerp(a.Y.Scale, b.Y.Scale, t),
        lerp(a.Y.Offset, b.Y.Offset, t)
    )
end

local function lerpVector2(a, b, t)
    return Vector2.new(lerp(a.X, b.X, t), lerp(a.Y, b.Y, t))
end

local function lerpValue(from, to, t)
    local ty = typeof(to)

    if ty == "number" then
        return lerp(from, to, t)
    elseif ty == "Color3" then
        return lerpColor(from, to, t)
    elseif ty == "UDim2" then
        return lerpUDim2(from, to, t)
    elseif ty == "Vector2" then
        return lerpVector2(from, to, t)
    elseif ty == "UDim" then
        return UDim.new(lerp(from.Scale, to.Scale, t), lerp(from.Offset, to.Offset, t))
    elseif ty == "Vector3" then
        return Vector3.new(lerp(from.X, to.X, t), lerp(from.Y, to.Y, t), lerp(from.Z, to.Z, t))
    end

    return (t >= 1) and to or from
end

-- easing curves
local function ease(style, t)
    -- Drawing lib uses: Linear, Quad, Quart, Quint, Sine, Back, Bounce, Elastic, Expo, Circ, Cubic
    if style == 0 or style == nil then -- Linear
        return t
    elseif style == 1 then -- Sine
        return 1 - math.cos(t * math.pi / 2)
    elseif style == 2 then -- Quad
        return t * t
    elseif style == 3 then -- Quart
        return t * t * t * t
    elseif style == 4 then -- Quint
        return t ^ 5
    elseif style == 5 then -- Back
        local c1 = 1.70158
        local c3 = c1 + 1
        return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
    elseif style == 6 then -- Bounce
        local n1, d1 = 7.5625, 2.75
        if t < 1 / d1 then
            return n1 * t * t
        elseif t < 2 / d1 then
            t = t - 1.5 / d1
            return n1 * t * t + 0.75
        elseif t < 2.5 / d1 then
            t = t - 2.25 / d1
            return n1 * t * t + 0.9375
        else
            t = t - 2.625 / d1
            return n1 * t * t + 0.984375
        end
    elseif style == 7 then -- Elastic
        local c4 = (2 * math.pi) / 3
        if t == 0 then return 0 end
        if t == 1 then return 1 end
        return 2 ^ (-10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
    elseif style == 8 then -- Expo
        return t == 0 and 0 or 2 ^ (10 * t - 10)
    elseif style == 9 then -- Circ
        return 1 - math.sqrt(1 - t * t)
    elseif style == 10 then -- Cubic
        return t * t * t
    end
    return t
end

function Tween.new(object, info, properties)
    local self = setmetatable({}, Tween)
    self.object = object
    self.info = info
    self.properties = properties or {}
    self.playing = false
    self.cancelled = false
    self.thread = nil
    self.startTime = nil
    self.startValues = {}
    return self
end

function Tween:Cancel()
    self.cancelled = true
    self.playing = false
    if self.thread then
        pcall(task.cancel, self.thread)
        self.thread = nil
    end
end

function Tween:Pause()
    self.playing = false
    if self.thread then
        pcall(task.cancel, self.thread)
        self.thread = nil
    end
end

function Tween:Play()
    if self.playing then
        self:Cancel()
    end
    self.cancelled = false
    self.playing = true

    local duration = (self.info and self.info.Time) or 0
    local style = (self.info and self.info.EasingStyle) or 0
    local props = self.properties

    for k in pairs(props) do
        self.startValues[k] = self.object[k]
    end

    if duration <= 0 then
        for k, v in pairs(props) do
            self.object[k] = v
        end
        self.playing = false
        return
    end

    self.startTime = os.clock()

    self.thread = task.spawn(function()
        while self.playing and not self.cancelled do
            local elapsed = os.clock() - self.startTime
            local alpha = math.clamp(elapsed / duration, 0, 1)
            local eased = ease(style, alpha)

            for k, target in pairs(props) do
                local from = self.startValues[k]
                if from ~= nil then
                    self.object[k] = lerpValue(from, target, eased)
                end
            end

            if alpha >= 1 then
                self.playing = false
                break
            end
            task.wait()
        end
    end)
end

Tween.EasingStyle = {
    Linear = 0, Sine = 1, Quad = 2, Quart = 3, Quint = 4,
    Back = 5, Bounce = 6, Elastic = 7, Expo = 8, Circ = 9, Cubic = 10,
}
Tween.EasingDirection = { In = 0, Out = 1, InOut = 2 }

return Tween
