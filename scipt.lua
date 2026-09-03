local Players = game:GetService("Players")

local lp = Players.LocalPlayer

local EAT_DURATION = 6
local STORE_POSITION = Vector3.new(55.5, 20.75, 282.5)

local currentWaypoint = 1
local isEating = false

local RACE_WAYPOINTS = {
    -- Keep your existing waypoint Vector3 values here.
}

local function getCharacter()
    local char = lp.Character or lp.CharacterAdded:Wait()

    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:WaitForChild("Humanoid")

    return char, hrp, hum
end

local function checkHunger()
    local playerGui = lp:FindFirstChild("PlayerGui")
    if not playerGui then
        return false
    end

    for _, gui in ipairs(playerGui:GetDescendants()) do
        if gui:IsA("TextLabel") then
            local text = gui.Text

            if typeof(text) == "string"
                and text:upper():find("YOU ARE HUNGRY", 1, true) then
                return true
            end
        end
    end

    return false
end

local function moveTo(hum, position)
    hum:MoveTo(position)

    local reached = hum.MoveToFinished:Wait()

    return reached
end

local function getNearestFoodSeat(hrp)
    local names = {
        ["1"] = true,
        ["2"] = true,
        ["3"] = true
    }

    local nearest = nil
    local nearestDist = math.huge

    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Seat") and names[v.Name] then
            local distance = (hrp.Position - v.Position).Magnitude

            if distance < nearestDist then
                nearest = v
                nearestDist = distance
            end
        end
    end

    return nearest
end

local function goEat(char, hrp, hum)
    if isEating then
        return
    end

    isEating = true

    moveTo(hum, STORE_POSITION)

    local seat = getNearestFoodSeat(hrp)

    if seat and seat.Parent then
        seat:Sit(hum)
        task.wait(EAT_DURATION)

        if hum and hum.Parent then
            hum.Sit = false
        end
    end

    isEating = false
end

while true do
    local char, hrp, hum = getCharacter()

    if checkHunger() then
        goEat(char, hrp, hum)
    else
        local waypoint = RACE_WAYPOINTS[currentWaypoint]

        if waypoint then
            moveTo(hum, waypoint)

            currentWaypoint =
                (currentWaypoint % #RACE_WAYPOINTS) + 1
        else
            currentWaypoint = 1
        end
    end

    task.wait(0.1)
end
