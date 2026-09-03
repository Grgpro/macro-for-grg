local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local START_WAIT = 20
local EAT_DURATION = 5

local MOVE_TIMEOUT = 8
local REACH_DISTANCE = 5
local CHECK_INTERVAL = 0.1

--==================================================
-- FOOD LOCATION
--==================================================

local STORE_POSITION = Vector3.new(
    -120.56571197509766,
    2.9999887943267822,
    -133.24757385253906
)

--==================================================
-- RACE ROUTE
--==================================================
-- First point = race starting gate.
-- The script waits 20 seconds there before starting.

local START_POSITION = Vector3.new(
    -113.46387481689453,
    3.1999995708465576,
    -113.60486602783203
)

local RACE_WAYPOINTS = {

    Vector3.new(-118.9842, 2.0954, -102.0009),
    Vector3.new(-118.9426, 2.3510, -101.9871),

    Vector3.new(-90.7577, 2.4390, -105.5932),
    Vector3.new(-57.4879, 2.3833, -101.7272),
    Vector3.new(-20.7289, 2.4221, -108.6993),

    Vector3.new(3.1172, 2.3859, -225.2284),
    Vector3.new(7.0257, 2.3386, -314.5869),
    Vector3.new(3.9567, 2.3842, -356.9861),
    Vector3.new(-0.7738, 2.4126, -396.6245),

    Vector3.new(-34.1933, 2.4405, -421.5387),
    Vector3.new(-98.2086, 2.3267, -408.4409),
    Vector3.new(-161.5845, 2.2414, -384.3363),

    Vector3.new(-223.7415, 2.3768, -366.2542),
    Vector3.new(-280.8906, 2.5485, -396.0000),
    Vector3.new(-270.8307, 2.3142, -448.3929),

    Vector3.new(-254.0071, 3.3066, -465.9801),
    Vector3.new(-210.7297, 2.7763, -509.0767),
    Vector3.new(-199.9876, 2.4135, -553.3884),
    Vector3.new(-205.9117, 2.3732, -583.1159),

    Vector3.new(-246.5808, 2.5065, -614.9449),
    Vector3.new(-284.1248, 2.5461, -716.5131),
    Vector3.new(-376.1253, 2.4695, -685.0591),

    Vector3.new(-448.3311, 2.4479, -450.0660),
    Vector3.new(-450.1932, 2.4317, -274.0122),
    Vector3.new(-448.4456, 2.3898, -208.4369),

    Vector3.new(-435.8524, 2.4063, -132.1963),
    Vector3.new(-400.7567, 2.3655, -113.5710),

    Vector3.new(-303.8779, 2.3773, -103.8498),
    Vector3.new(-256.7598, 2.3726, -101.2406),
    Vector3.new(-174.4693, 2.3887, -101.8843),
    Vector3.new(-126.4541, 2.3878, -101.9831),

    Vector3.new(-116.7533, 2.4058, -111.5681)
}

--==================================================
-- STATE
--==================================================

local eating = false
local raceStarted = false
local waypointIndex = 1

--==================================================
-- CHARACTER
--==================================================

local function getCharacter()

    local character = player.Character
        or player.CharacterAdded:Wait()

    local humanoid = character:WaitForChild("Humanoid")
    local root = character:WaitForChild("HumanoidRootPart")

    return character, root, humanoid
end

--==================================================
-- HUNGER
--==================================================

local function isHungry()

    for _, gui in ipairs(playerGui:GetDescendants()) do

        if gui:IsA("TextLabel") then

            local text = tostring(gui.Text):upper()

            if text:find("YOU ARE HUNGRY", 1, true) then
                return true
            end
        end
    end

    return false
end

--==================================================
-- MOVEMENT
--==================================================

local function moveTo(humanoid, root, position)

    if not humanoid
        or not root
        or humanoid.Health <= 0 then

        return false
    end

    humanoid:MoveTo(position)

    local started = os.clock()

    while humanoid.Health > 0 do

        local distance =
            (root.Position - position).Magnitude

        if distance <= REACH_DISTANCE then
            return true
        end

        if os.clock() - started >= MOVE_TIMEOUT then
            return false
        end

        task.wait(CHECK_INTERVAL)
    end

    return false
end

--==================================================
-- FIND FOOD SEAT
--==================================================

local function findFoodSeat(root)

    local closest = nil
    local closestDistance = math.huge

    for _, object in ipairs(workspace:GetDescendants()) do

        if object:IsA("Seat") then

            local name = tostring(object.Name)

            if name == "1"
                or name == "2"
                or name == "3" then

                local distance =
                    (root.Position - object.Position).Magnitude

                if distance < closestDistance then

                    closest = object
                    closestDistance = distance
                end
            end
        end
    end

    return closest
end

--==================================================
-- EAT
--==================================================

local function eat(root, humanoid)

    if eating then
        return
    end

    eating = true

    -- Go to food area
    moveTo(
        humanoid,
        root,
        STORE_POSITION
    )

    task.wait(0.25)

    local seat = findFoodSeat(root)

    if seat then

        seat:Sit(humanoid)

        task.wait(EAT_DURATION)

        if humanoid.Parent then
            humanoid.Sit = false
        end

        task.wait(0.5)
    end

    eating = false
end

--==================================================
-- WAIT AT START
--==================================================

local function waitForRaceStart(root, humanoid)

    raceStarted = false

    -- Get to starting gate
    moveTo(
        humanoid,
        root,
        START_POSITION
    )

    -- Wait for race
    local remaining = START_WAIT

    while remaining > 0 do

        -- Hunger still takes priority
        if isHungry() then
            eat(root, humanoid)

            -- Return to starting gate
            moveTo(
                humanoid,
                root,
                START_POSITION
            )
        end

        task.wait(1)
        remaining -= 1
    end

    raceStarted = true
end

--==================================================
-- RUN ONE LAP
--==================================================

local function runLap(root, humanoid)

    waypointIndex = 1

    while waypointIndex <= #RACE_WAYPOINTS do

        -- Hunger interruption
        if isHungry() then

            eat(root, humanoid)

            -- Resume by returning to the current waypoint
            if waypointIndex <= #RACE_WAYPOINTS then

                moveTo(
                    humanoid,
                    root,
                    RACE_WAYPOINTS[waypointIndex]
                )
            end
        end

        local waypoint =
            RACE_WAYPOINTS[waypointIndex]

        moveTo(
            humanoid,
            root,
            waypoint
        )

        waypointIndex += 1

        task.wait(0.05)
    end
end

--==================================================
-- MAIN
--==================================================

while true do

    local character, root, humanoid =
        getCharacter()

    if humanoid.Health <= 0 then

        task.wait(2)

    else

        --==========================================
        -- GO TO START + WAIT 20 SECONDS
        --==========================================

        waitForRaceStart(
            root,
            humanoid
        )

        --==========================================
        -- RUN ONE LAP
        --==========================================

        if raceStarted then

            runLap(
                root,
                humanoid
            )
        end

        --==========================================
        -- LAP FINISHED
        --==========================================

        raceStarted = false

        -- Return to starting gate
        moveTo(
            humanoid,
            root,
            START_POSITION
        )

        task.wait(0.5)
    end
end
