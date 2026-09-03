local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local EAT_DURATION = 5
local MOVE_TIMEOUT = 8
local WAYPOINT_REACH_DISTANCE = 5

-- Wait at the starting waypoint before each lap
local START_WAIT = 23

-- Food/store location
local STORE_POSITION = Vector3.new(
    -120.56571197509766,
    2.9999887943267822,
    -133.24757385253906
)

--==================================================
-- OPTIMIZED ONE-LAP WAYPOINTS
--==================================================

local RACE_WAYPOINTS = {

    Vector3.new(-113.4639, 3.2, -113.6049),

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
    Vector3.new(-282.9152, 2.5613, -406.9911),
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

    Vector3.new(-116.7533, 2.4058, -111.5681),

    Vector3.new(-113.4639, 3.2, -113.6049)
}

--==================================================
-- STATE
--==================================================

local currentWaypoint = 1
local isEating = false
local waitingForRace = false

--==================================================
-- CHARACTER
--==================================================

local function getCharacter()
    local character = player.Character or player.CharacterAdded:Wait()

    local humanoid = character:WaitForChild("Humanoid")
    local root = character:WaitForChild("HumanoidRootPart")

    return character, root, humanoid
end

--==================================================
-- HUNGER CHECK
--==================================================

local function checkHunger()

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
-- FAST MOVEMENT
--==================================================

local function moveTo(humanoid, root, position)

    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    humanoid:MoveTo(position)

    local startTime = os.clock()

    while humanoid.Health > 0 do

        local distance =
            (root.Position - position).Magnitude

        if distance <= WAYPOINT_REACH_DISTANCE then
            return true
        end

        if os.clock() - startTime >= MOVE_TIMEOUT then
            return false
        end

        task.wait(0.05)
    end

    return false
end

--==================================================
-- FIND FOOD SEAT
--==================================================

local function getNearestFoodSeat(root)

    local nearestSeat = nil
    local nearestDistance = math.huge

    for _, object in ipairs(workspace:GetDescendants()) do

        if object:IsA("Seat") then

            local name = tostring(object.Name)

            if name == "1"
                or name == "2"
                or name == "3" then

                local distance =
                    (root.Position - object.Position).Magnitude

                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestSeat = object
                end
            end
        end
    end

    return nearestSeat
end

--==================================================
-- EAT
--==================================================

local function goEat(root, humanoid)

    if isEating then
        return
    end

    isEating = true

    -- Go to food/store
    moveTo(
        humanoid,
        root,
        STORE_POSITION
    )

    task.wait(0.3)

    local seat = getNearestFoodSeat(root)

    if seat then

        seat:Sit(humanoid)

        task.wait(EAT_DURATION)

        if humanoid.Parent then
            humanoid.Sit = false
        end

        task.wait(0.5)
    end

    isEating = false
end

--==================================================
-- WAIT FOR RACE START
--==================================================

local function waitForRaceStart(humanoid, root)

    if waitingForRace then
        return
    end

    waitingForRace = true

    -- Make sure we're actually at the starting point
    moveTo(
        humanoid,
        root,
        RACE_WAYPOINTS[1]
    )

    -- 23 SECOND STARTING WAIT
    task.wait(START_WAIT)

    waitingForRace = false
end

--==================================================
-- MAIN LOOP
--==================================================

while true do

    local character, root, humanoid =
        getCharacter()

    if humanoid.Health <= 0 then

        task.wait(1)

        currentWaypoint = 1

        continue
    end

    --==================================================
    -- HUNGER HAS PRIORITY
    --==================================================

    if checkHunger() then

        goEat(
            root,
            humanoid
        )

    else

        --==================================================
        -- START OF LAP
        --==================================================

        if currentWaypoint == 1 then

            waitForRaceStart(
                humanoid,
                root
            )

            -- Start moving to waypoint 2
            currentWaypoint = 2

        else

            --==================================================
            -- NORMAL RACE MOVEMENT
            --==================================================

            local waypoint =
                RACE_WAYPOINTS[currentWaypoint]

            if waypoint then

                moveTo(
                    humanoid,
                    root,
                    waypoint
                )

                currentWaypoint =
                    currentWaypoint + 1

                --==================================================
                -- LAP COMPLETE
                --==================================================

                if currentWaypoint > #RACE_WAYPOINTS then

                    currentWaypoint = 1

                end

            else

                -- Safety reset
                currentWaypoint = 1

            end
        end
    end

    task.wait(0.05)
end
