-- Game constants
local game_state 
local GAME_WIDTH = 384
local GAME_HEIGHT = 384
local LEVEL_NUM_COLUMNS = 24
local LEVEL_NUM_ROWS = 24
local LEVEL_DATA = [[
........................
........o...............
......oop...So....popoo.
XSo..XXXX..XXp...XXXXXXX
XXo.........XXo.........
.XX.p.....o..XX.S.....o.
..XXXXX...o...X.XXX...o.
o........po.S.........o.
p......o.XXXX........XXX
Xo...ooS....X....ooS....
ooS..XXX....X....XXX....
XXXXXX..................
..ooo.........oo.....o..
.........oo......X...o..
.o...p.o.SS.p....Xp..Soo
Xo...XXX.XXXXo...XXXXXXX
XXp....X....XX...o......
.XXp.oo...o..XX..S....o.
..XXXXX...o...XoXXX...o.
..........o.p.........p.
X........XXXX.....o..XXX
X....oo.....X....oop....
X.H.pXXX....X....XXX....
XXXXXX.........X........
]]

-- Game variables
local player
local platforms
local gems
local stones
local pumpkins
local score = 0

-- Assets
local playerImage
local objectsImage
local stoneImage
local pumpkinImage
local candyImage

-- Initializes the game
function love.load()
  game_state = 'menu'
  -- Load assets
  love.graphics.setDefaultFilter('nearest', 'nearest')
  playerImage = love.graphics.newImage('img/player1.png')
  objectsImage = love.graphics.newImage('img/objects.png')
  stoneImage = love.graphics.newImage('img/stone.png')
  pumpkinImage = love.graphics.newImage('img/pumpkin.png')
  candyImage = love.graphics.newImage('img/candycorn.png')

  -- Create platforms and game objects from the level data
 
  platforms = {}
  gems = {}
  stones = {}
  pumpkins = {}
  for col = 1, LEVEL_NUM_COLUMNS do
    for row = 1, LEVEL_NUM_ROWS do
      local i = (LEVEL_NUM_ROWS + 1) * (row - 1) + col
      local x, y = 16 * (col - 1), 16 * (row - 1)
      local symbol = string.sub(LEVEL_DATA, i, i)
      if symbol == 'H' then
        -- Create the hero
        player = {
          x = x,
          y = y,
          vx = 0,
          vy = 0,
          width = 16,
          height = 16,
          isFacingLeft = false,
          isGrounded = false,
          landingTimer = 0.00,
          walkTimer = 0.00
        }
      elseif symbol == 'X' then
        -- Create a platform
        table.insert(platforms, {
          x = x,
          y = y,
          width = 16,
          height = 16
        })
      elseif symbol == 'S' then 
        -- Create stones
        table.insert(stones, {
            x = x, 
            y = y, 
            width = 16, 
            height = 16,
            
        })
      elseif symbol == 'p' then 
        -- Create pumpkins
        table.insert(pumpkins, {
          x = x,
          y = y,
          width = 16, 
          height = 16,
          isSmashed = false
        })
        
      elseif symbol == 'o' then
        -- Create a gem
        table.insert(gems, {
          x = x,
          y = y,
          width = 16,
          height = 16,
          isCollected = false
        })
      end
    end
  end
end

-- Updates the game state
function love.update(dt)
  if game_state == 'game' then 
    player.landingTimer = math.max(0, player.landingTimer - dt) 

    -- Figure out which direction the player is moving
    local moveX = (love.keyboard.isDown('left') and -1 or 0) + (love.keyboard.isDown('right') and 1 or 0)

    -- Keep track of the player's walk cycle
    player.walkTimer = moveX == 0 and 0.00 or ((player.walkTimer + dt) % 0.60)

    -- Move the player left / right
    player.vx = 62 * moveX
    if moveX < 0 then
      player.isFacingLeft = true
    elseif moveX > 0 then
      player.isFacingLeft = false
    end

    -- Jump when space is pressed
    if player.isGrounded and love.keyboard.isDown('space') then
      player.vy = -200
    end

    -- Accelerate downward (a la gravity)
    player.vy = player.vy + 480 * dt

    -- Apply the player's velocity to her position
    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt

    -- Check for collisions with platforms
    local wasGrounded = player.isGrounded
    player.isGrounded = false
    for _, platform in ipairs(platforms) do
      local collisionDir = checkForCollision(player, platform)
      if collisionDir == 'top' then
        player.y = platform.y + platform.height
        player.vy = math.max(0, player.vy)
      elseif collisionDir == 'bottom' then
        player.y = platform.y - player.height
        player.vy = math.min(0, player.vy)
        player.isGrounded = true
        if not wasGrounded then
          player.landingTimer = 0.15
        end
      elseif collisionDir == 'left' then
        player.x = platform.x + platform.width
        player.vx = math.max(0, player.vx)
      elseif collisionDir == 'right' then
        player.x = platform.x - player.width
        player.vx = math.min(0, player.vx)
      end
    end
    -- Check for stone collision
    local wasGrounded = player.isGrounded
    for _, stone in ipairs(stones) do 
      local collisionDir = checkForCollision(player, stone)
      if collisionDir == 'top' then 
          player.y = stone.y + stone.height
          player.vy = math.max(0, player.vy)
      elseif collisionDir == 'bottom' then 
          player.y = stone.y - player.height
          player.vy = math.min(0, player.vy)
          player.isGrounded = true
          if not wasGrounded then 
            player.landingTimer = 0.15
          end
      elseif collisionDir == 'left' then 
          player.x = stone.x + stone.width 
          player.vx = math.max(0, player.vx)
      elseif collisionDir == 'right' then 
          player.x = stone.x - stone.width
          player.vx = math.min(0, player.vx)
      end
  end
  --check for pumpkin collision / smashing
  local wasGrounded = player.isGrounded
  for _, pumpkin in ipairs(pumpkins) do
    if not pumpkin.isSmashed then  --hacky af way to get the player to be able to smash
      local collisionDir = checkForCollision(player, pumpkin)
      if collisionDir == 'top' then 
        player.y = pumpkin.y + pumpkin.height 
        player.vy = math.max(0, player.vy)
      elseif collisionDir == 'bottom' then 
        player.y = pumpkin.y - player.height 
        player.vy = math.min(0, player.vy)
        player.isGrounded = true 
        if not wasGrounded then 
          player.landingTimer = 0.15 
        end
        pumpkin.isSmashed = true
        score = score + 2
      elseif collisionDir == 'left' then 
        player.x = pumpkin.x + pumpkin.width 
        player.vx = math.max(0, player.vx)
      elseif collisionDir == 'right' then 
        player.x = pumpkin.x - pumpkin.width 
        player.vx = math.min(0, player.vx)
      end
    end
  end
    -- Check for gem collection
    for _, gem in ipairs(gems) do
      if not gem.isCollected and entitiesOverlapping(player, gem) then
        gem.isCollected = true
        score = score + 1
      end
    end  

    -- Keep the player in bounds
    if player.x < 0 then
      player.x = 0
    elseif player.x > GAME_WIDTH - player.width then
      player.x = GAME_WIDTH - player.width
    end
    if player.y > GAME_HEIGHT + 50 then
      player.y = -10
    end
  end
end

-- Renders the game
function love.draw()
  if game_state == 'menu' then 
    local font = love.graphics.setNewFont(15)
    love.graphics.printf('press ENTER to play', 200, 200, 255)
    love.graphics.draw(candyImage, 245, 225)
    love.graphics.draw(candyImage, 260, 230)
    love.graphics.draw(candyImage, 275, 225)
    love.graphics.draw(candyImage, 290, 230)
    if love.keyboard.isDown("return") then 
      game_state = 'game'
    end
  elseif game_state == 'game' then 
    if game_state == 'game' and score < 86 then 
      -- Clear the screen
      love.graphics.clear(0,0,0)
      love.graphics.setColor(1, 1, 1)
      love.graphics.printf(score, 5, 5, 255)
      
      -- Draw  the platforms
      for _, platform in ipairs(platforms) do
        drawSprite(objectsImage, 16, 16, 1, platform.x, platform.y)
      end

      -- Draw the gems
      for _, gem in ipairs(gems) do
        if not gem.isCollected then
          drawSprite(objectsImage, 16, 16, 4, gem.x, gem.y)
        end
      end

      -- Draw the stones
      for _, stone in ipairs(stones) do 
        drawSprite(stoneImage, 16, 16, 1, stone.x, stone.y)
      end
      
      -- Draw the pumpkins
      --add an 'isSmashed'
      local sprite
      for _, pumpkin in ipairs(pumpkins) do 
        if pumpkin.isSmashed then 
          sprite = 2
        else
          sprite = 1
        end
        drawSprite(pumpkinImage, 16, 16, sprite, pumpkin.x, pumpkin.y)
      end

      -- Draw the player
      local sprite
      if player.isGrounded then
        -- When standing
        if player.vx == 0 then
          if player.landingTimer > 0.00 then
            sprite = 7
          else
            sprite = 1
          end
        -- When running
        elseif player.walkTimer < 0.2 then
          sprite = 2
        elseif player.walkTimer < 0.3 then
          sprite = 3
        elseif player.walkTimer < 0.5 then
          sprite = 4
        else
          sprite = 3
        end
      -- When jumping
      elseif player.vy > 0 then
        sprite = 6
      else
        sprite = 5
      end
      drawSprite(playerImage, 16, 16, sprite, player.x, player.y, player.isFacingLeft)
    else 
      love.graphics.clear(0, 0, 0)
      love.graphics.printf('you won!', 192, 192, 255)
      love.graphics.draw(stoneImage, 215, 215, sprite)
    end
  end
end


  -- Draws a sprite from a sprite sheet, spriteNum=1 is the upper-leftmost sprite
  function drawSprite(spriteSheetImage, spriteWidth, spriteHeight, sprite, x, y, flipHorizontal, flipVertical, rotation)
    local width, height = spriteSheetImage:getDimensions()
    local numColumns = math.floor(width / spriteWidth)
    local col, row = (sprite - 1) % numColumns, math.floor((sprite - 1) / numColumns)
    love.graphics.draw(spriteSheetImage,
      love.graphics.newQuad(spriteWidth * col, spriteHeight * row, spriteWidth, spriteHeight, width, height),
      x + spriteWidth / 2, y + spriteHeight / 2,
      rotation or 0,
      flipHorizontal and -1 or 1, flipVertical and -1 or 1,
      spriteWidth / 2, spriteHeight / 2)
  end

  -- Determine whether two rectangles are overlapping
  function rectsOverlapping(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 + w1 > x2 and x2 + w2 > x1 and y1 + h1 > y2 and y2 + h2 > y1
  end

  -- Returns true if two entities are overlapping, by checking their bounding boxes
  function entitiesOverlapping(a, b)
    return rectsOverlapping(a.x, a.y, a.width, a.height, b.x, b.y, b.width, b.height)
  end

  -- Checks to see if two entities are colliding, and if so from which side. This is
  -- accomplished by checking the four quadrants of the axis-aligned bounding boxes
  function checkForCollision(a, b)
    local indent = 3
    if rectsOverlapping(a.x + indent, a.y + a.height / 2, a.width - 2 * indent, a.height / 2, b.x, b.y, b.width, b.height) then
      return 'bottom'
    elseif rectsOverlapping(a.x + indent, a.y, a.width - 2 * indent, a.height / 2, b.x, b.y, b.width, b.height) then
      return 'top'
    elseif rectsOverlapping(a.x, a.y + indent, a.width / 2, a.height - 2 * indent, b.x, b.y, b.width, b.height) then
      return 'left'
    elseif rectsOverlapping(a.x + a.width / 2, a.y + indent, a.width / 2, a.height - 2 * indent, b.x, b.y, b.width, b.height) then
      return 'right'
    end
  end