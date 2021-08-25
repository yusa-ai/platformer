playerStartX = 350
playerStartY = 300

player = world:newRectangleCollider(playerStartX, playerStartY, 40, 100, {collision_class = 'Player'})
player:setFixedRotation(true)
player.speed = 240
player.animation = animations.idle
player.isMoving = false
player.direction = 1
player.grounded = true

function playerUpdate(dt)
    if player.body then
        local colliders = world:queryRectangleArea(player:getX() - 20, player:getY() + 50, 40, 2, {'Platform'})
        if #colliders > 0 then
            player.grounded = true
        else
            player.grounded = false
        end

        player.isMoving = false

        -- Controls
        local px, py = player:getPosition()
        if love.keyboard.isDown('d') then
            player.isMoving = true
            player.direction = 1
            player:setX(px + player.speed * dt)
        end
        if love.keyboard.isDown('q') then
            player.isMoving = true
            player.direction = -1
            player:setX(px - player.speed * dt)
        end

        if player:enter('Danger') then
            player:setPosition(playerStartX, playerStartY)
        end
    end

    if player.grounded then
        if player.isMoving then
            player.animation = animations.run
        else
            player.animation = animations.idle
        end
    else
        player.animation = animations.jump
    end

    player.animation:update(dt)
end

function drawPlayer()
    if player.body then
        local px, py = player:getPosition()
        player.animation:draw(sprites.playerSheet, px, py, nil, .25 * player.direction, 0.25, 130, 300)
    end
end