function love.load()
    love.window.setMode(1000, 768)

    anim8 = require 'libraries/anim8/anim8'
    sti = require 'libraries/Simple-Tiled-Implementation/sti'
    cameraFile = require 'libraries/hump/camera'

    cam = cameraFile()

    sounds = {}
    sounds.jump = love.audio.newSource('audio/jump.wav', 'static')
    sounds.jump:setVolume(0.1)
    sounds.music = love.audio.newSource('audio/music.mp3', 'stream')
    sounds.music:setLooping(true)
    sounds.music:setVolume(0.1)

    sounds.music:play()

    sprites = {}
    sprites.playerSheet = love.graphics.newImage('sprites/playerSheet.png')
    sprites.enemySheet = love.graphics.newImage('sprites/enemySheet.png')
    sprites.background = love.graphics.newImage('sprites/background.png')


    local grid = anim8.newGrid(614, 564, sprites.playerSheet:getWidth(), sprites.playerSheet:getHeight())
    local enemyGrid = anim8.newGrid(100, 79, sprites.enemySheet:getWidth(), sprites.enemySheet:getHeight())

    animations = {}
    animations.idle = anim8.newAnimation(grid('1-15', 1), .05)
    animations.jump = anim8.newAnimation(grid('1-7', 2), .05)
    animations.run = anim8.newAnimation(grid('1-15', 3), .05)
    animations.enemy = anim8.newAnimation(enemyGrid('1-2', 1), .05)

    wf = require 'libraries/windfield'
    world = wf.newWorld(0, 800, false)
    world:setQueryDebugDrawing(true)
    
    world:addCollisionClass('Platform')
    world:addCollisionClass('Player')
    world:addCollisionClass('Danger')

    require 'player'
    require 'enemy'

    dangerZone = world:newRectangleCollider(-500, 800, 5000, 50, {collision_class = 'Danger'})
    dangerZone:setType('static')

    platforms = {}

    flagX = 0
    flagY = 0

    require 'libraries/show'

    saveData = {}
    saveData.level = 1

    if love.filesystem.getInfo('save.lua') then
        local save = love.filesystem.load('save.lua')
        save()
    end

    loadMap(saveData.level)

    love.window.setTitle('Platformer')
end

function love.update(dt)
    world:update(dt)
    gameMap:update(dt)
    playerUpdate(dt)
    updateEnemies(dt)

    local px, py = player:getPosition()
    cam:lookAt(px, love.graphics.getHeight()/2)

    -- If player reaches flag
    local colliders = world:queryCircleArea(flagX, flagY, 10, {'Player'})
    if #colliders > 0 then
        loadNextMap()
    end
end

function love.draw()
    love.graphics.draw(sprites.background, 0, 0)

    cam:attach()

    gameMap:drawLayer(gameMap.layers['Tile Layer 1'])
    --world:draw() -- DEBUG: show hitboxes
    drawPlayer()
    drawEnemies()

    cam:detach()
end

function love.keypressed(key)
    if key == 'space' then
        if player.grounded then player:applyLinearImpulse(0, -4000) end
        sounds.jump:play()
    end
end

function spawnPlatform(x, y, w, h)
    --if w > 0 and h > 0 then
    local platform = world:newRectangleCollider(x, y, w, h, {collision_class = 'Platform'})
    platform:setType('static')

    table.insert(platforms, platform)
    --end
end

function loadMap(number)
    love.filesystem.write('save.lua', table.show(saveData, 'saveData'))
    
    destroyAll()

    -- no plan for level 3 and beyond of course, this is just a learning project
    if number == 3 then number = 1 end

    gameMap = sti('maps/level' .. number .. '.lua')

    -- Load starting points
    for i, obj in pairs(gameMap.layers['Start'].objects) do
        playerStartX, playerStartY = obj.x, obj.y
    end

    player:setPosition(playerStartX, playerStartY)

    -- Load platforms
    for i, obj in pairs(gameMap.layers['Platforms'].objects) do
        spawnPlatform(obj.x, obj.y, obj.width, obj.height)
    end

    -- Load enemies
    for i, obj in pairs(gameMap.layers['Enemies'].objects) do
        spawnEnemy(obj.x, obj.y)
    end

    -- Load flags
    for i, obj in pairs(gameMap.layers['Flag'].objects) do
        flagX = obj.x
        flagY = obj.y
    end
end

function loadNextMap()
    saveData.level = saveData.level + 1
    loadMap(saveData.level)
end

function destroyAll()
    local i = #platforms
    while i > -1 do
        if platforms[i] ~= nil then platforms[i]:destroy() end
        table.remove(platforms, i)
        i = i - 1
    end

    local i = #enemies
    while i > -1 do
        if enemies[i] ~= nil then enemies[i]:destroy() end
        table.remove(enemies, i)
        i = i - 1
    end
end