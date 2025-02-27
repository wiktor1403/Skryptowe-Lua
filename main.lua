-- main.lua
local gridWidth = 10
local gridHeight = 20
local blockSize = 30
local grid = {}

local tetromino
local nextTetromino
local gameOver = false

-- Tetromino shapes
local shapes = {
    { {1, 1, 1, 1} },
    { {1, 1}, {1, 1} },
    { {0, 1, 1}, {1, 1, 0} },
    { {1, 1, 0}, {0, 1, 1} },
    { {1, 1, 0}, {1, 0, 0} },
    { {0, 1, 0}, {1, 1, 1} },
    { {0, 0, 1}, {1, 1, 1} },
}

-- Colors for each tetromino type
local colors = {
    {1, 0, 0},  -- Red
    {0, 1, 0},  -- Green
    {0, 0, 1},  -- Blue
    {1, 1, 0},  -- Yellow
    {1, 0, 1},  -- Magenta
    {0, 1, 1},  -- Cyan
    {0.7, 0.5, 0} -- Orange
}

-- Set the speed (time between each tetromino drop)
local dropInterval = 0.5  -- Adjust this value to make the game slower or faster (in seconds)
local timeSinceLastDrop = 0  -- Initialize the timer variable to 0


-- Initialize the grid
function initGrid()
    grid = {}
    for y = 1, gridHeight do
        grid[y] = {}
        for x = 1, gridWidth do
            grid[y][x] = nil
        end
    end
end

-- Check if the tetromino can be placed at the given position
function checkCollision(t, offsetX, offsetY)
    for y = 1, #t do
        for x = 1, #t[y] do
            if t[y][x] ~= 0 then
                local newX = x + offsetX
                local newY = y + offsetY
                if newX < 1 or newX > gridWidth or newY < 1 or newY > gridHeight then
                    return true
                end
                if grid[newY][newX] then
                    return true
                end
            end
        end
    end
    return false
end

-- Place the current tetromino on the grid
function placeTetromino()
    for y = 1, #tetromino do
        for x = 1, #tetromino[y] do
            if tetromino[y][x] ~= 0 then
                grid[y + tetromino.offsetY][x + tetromino.offsetX] = tetromino.color
            end
        end
    end
end

-- Clear full lines
function clearLines()
    for y = gridHeight, 1, -1 do
        local fullLine = true
        for x = 1, gridWidth do
            if not grid[y][x] then
                fullLine = false
                break
            end
        end
        
        if fullLine then
            for i = y, 2, -1 do
                grid[i] = grid[i-1]
            end
            grid[1] = {}
            for x = 1, gridWidth do
                grid[1][x] = nil
            end
        end
    end
end

-- Spawn a new tetromino
function spawnTetromino()
    tetromino = nextTetromino or shapes[math.random(1, #shapes)]
    nextTetromino = shapes[math.random(1, #shapes)]
    tetromino.offsetX = math.floor(gridWidth / 2) - math.floor(#tetromino[1] / 2)
    tetromino.offsetY = 1
    tetromino.color = colors[math.random(1, #colors)]  -- Assign a random color
    if checkCollision(tetromino, tetromino.offsetX, tetromino.offsetY) then
        gameOver = true
    end
end

-- Rotate the tetromino 90 degrees
function rotateTetromino()
    if not tetromino then return end  -- Check if tetromino is nil

    -- Store current position (offsetX and offsetY) before rotating
    local offsetX = tetromino.offsetX
    local offsetY = tetromino.offsetY
    local color = tetromino.color  -- Keep the color intact

    -- Perform the rotation (assuming the tetromino is a 2D matrix)
    local newShape = {}
    for x = 1, #tetromino[1] do
        newShape[x] = {}
        for y = 1, #tetromino do
            newShape[x][y] = tetromino[#tetromino - y + 1][x]
        end
    end

    -- Assign the rotated shape back
    tetromino = newShape
    -- Retain the original color and position
    tetromino.offsetX = offsetX
    tetromino.offsetY = offsetY
    tetromino.color = color
end


-- Move the tetromino left or right
function moveTetromino(direction)
    local offset = direction == "left" and -1 or 1
    if not checkCollision(tetromino, tetromino.offsetX + offset, tetromino.offsetY) then
        tetromino.offsetX = tetromino.offsetX + offset
    end
end

-- Move the tetromino down
function moveDown()
    if not checkCollision(tetromino, tetromino.offsetX, tetromino.offsetY + 1) then
        tetromino.offsetY = tetromino.offsetY + 1
    else
        placeTetromino()
        clearLines()
        spawnTetromino()
    end
end

-- LÖVE load function
function love.load()
    love.window.setTitle("Tetris")
    love.window.setMode(gridWidth * blockSize, gridHeight * blockSize)
    initGrid()
    spawnTetromino()
end

-- LÖVE update function
function love.update(dt)
    if gameOver then
        return
    end

    -- Increase timeSinceLastDrop by the time that passed since the last frame (dt)
    timeSinceLastDrop = timeSinceLastDrop + dt

    -- If enough time has passed, move the tetromino down
    if timeSinceLastDrop >= dropInterval then
        moveDown()  -- Move the tetromino down
        timeSinceLastDrop = timeSinceLastDrop - dropInterval  -- Reset the timer
    end
end

-- LÖVE draw function
function love.draw()
    -- Draw grid
    for y = 1, gridHeight do
        for x = 1, gridWidth do
            local block = grid[y][x]
            if block then
                love.graphics.setColor(block)
                love.graphics.rectangle("fill", (x - 1) * blockSize, (y - 1) * blockSize, blockSize, blockSize)
            end
        end
    end

    -- Draw current tetromino
    love.graphics.setColor(tetromino.color)
    for y = 1, #tetromino do
        for x = 1, #tetromino[y] do
            if tetromino[y][x] ~= 0 then
                love.graphics.rectangle("fill", (tetromino.offsetX + x - 1) * blockSize, (tetromino.offsetY + y - 1) * blockSize, blockSize, blockSize)
            end
        end
    end

    -- Game over text
    if gameOver then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Game Over", 0, gridHeight * blockSize / 2 - 20, gridWidth * blockSize, "center")
    end
end

-- LÖVE keypressed function
function love.keypressed(key)
    if key == "left" then
        moveTetromino("left")
    elseif key == "right" then
        moveTetromino("right")
    elseif key == "up" then
        rotateTetromino()
    elseif key == "down" then
        moveDown()
    end
end
