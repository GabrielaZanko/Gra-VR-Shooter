local funkcje1 = require("funkcje")

function initGrid()
  shader = lovr.graphics.newShader([[
    vec4 lovrmain() {
      return DefaultPosition;
    }
  ]], [[
    const float gridSize = 25.0;
    const float cellSize = 0.5;

    vec4 lovrmain() {
      vec2 uv = UV;

      float alpha = 1.0 - smoothstep(0.4, 0.5, distance(uv, vec2(0.5)));

      uv *= gridSize;
      uv /= cellSize;
      vec2 c = abs(fract(uv - 0.5) - 0.5) / fwidth(uv);

      float line = clamp(1.0 - min(c.x, c.y), 0.0, 1.0);
      line = smoothstep(0.1, 0.3, line);

      vec3 pink = vec3(1.0, 0.2, 0.6);

      return vec4(pink * line * alpha, alpha);
    }
  ]], { flags = { highp = true } })

  lovr.graphics.setBackgroundColor(0.05, 0.05, 0.05)
end

function lovr.load()
  cubeSize = 0.2
  redCubeSize = 0.1
  bulletsSpeed = 50
  gameTime = 30
  gameTimer = gameTime
  bestScore = funkcje1.readBestScore() or 0

  initGrid()

  backgroundTexture1 = lovr.graphics.newTexture('background1.jpg')
  backgroundTexture2 = lovr.graphics.newTexture('background2.jpg')
  backgroundMaterial1 = lovr.graphics.newMaterial({ texture = backgroundTexture1 })
  backgroundMaterial2 = lovr.graphics.newMaterial({ texture = backgroundTexture2 })

  transitionTime = 2.0
  transitionTimer = 0
  transitioning = false
  currentBackground = 1

  shotSound = lovr.audio.newSource('sounds/shot.mp3', { decode = true })
  hitSound = lovr.audio.newSource('sounds/hit.mp3', { decode = true })
  gameplaySound = lovr.audio.newSource('sounds/LookAss.mp3', { decode = true })
  scoreSound = lovr.audio.newSource('sounds/score.mp3', { decode = true })
  startSound = lovr.audio.newSource('sounds/start.mp3', { decode = true })

  assert(shotSound, "Failed to load shot.mp3")
  assert(hitSound, "Failed to load hit.mp3")
  assert(gameplaySound, "Failed to load gameplay.mp3")
  assert(scoreSound, "Failed to load score.mp3")
  assert(startSound, "Failed to load start.mp3")

  world = lovr.physics.newWorld(0, -9.81, 0, true)
  world:setLinearDamping(0.01)
  world:setAngularDamping(0.005)

  local startTime = lovr.timer.getTime()
  pass = {
    text = function(self, text, x, y, z)
      lovr.graphics.print(text, x, y, z, 0.5)
    end
  }

  world:newBoxCollider(0, 0, 0, 50, 0.05, 50):setKinematic(true)
  
  ModelUSP = lovr.graphics.newModel('models/PISTOLETPINK.glb')

  RedCubeModel = lovr.graphics.newModel('models/redCube.glb')
  BlueCubeModel = lovr.graphics.newModel('models/bluecube.glb')
  
  for i, hand in ipairs(lovr.headset.getHands()) do
    local position = vec3(lovr.headset.getPosition(hand .. '/point'))
    local orientation = quat(lovr.headset.getOrientation(hand .. '/point'))
  
    ModelUSP = world:newBoxCollider(position, 0.5, 0.5, 0.5)
    ModelUSP:setFriction(0.8)
  end
  
  ModelUSPPosition = lovr.math.newVec3(0, 1, -2)
  playerStartPosition = lovr.math.newVec3(0, 1, 0)
  
  bullets = {}
  
  Hands = {
    left = {
      model = lovr.graphics.newModel('left.glb'),
      skeleton = nil,
      holdingGun = false
    },
    right = {
      model = lovr.graphics.newModel('right.glb'),
      skeleton = nil,
      holdingGun = false
    }
  }

  cubes = {}
  redCube = nil
  
  hitCounter = 0

  hitTexts = {}

  for i = 1, 10 do
    funkcje1.createCube(world, cubes, math.random(-5, 5), math.random(0.5, 5), math.random(-5, 5), "orange")
  end
  
  redCube = funkcje1.createCube(world, cubes, math.random(-5, 5), math.random(0.5, 5), math.random(-5, 5), "red")

  map = {
    [2] = 'wrist',
    [3] = 'thumb-metacarpal',
    [4] = 'thumb-phalanx-proximal',
    [5] = 'thumb-phalanx-distal',
    [7] = 'index-finger-metacarpal',
    [8] = 'index-finger-phalanx-proximal',
    [9] = 'index-finger-phalanx-intermediate',
    [10] = 'index-finger-phalanx-distal',
    [12] = 'middle-finger-metacarpal',
    [13] = 'middle-finger-phalanx-proximal',
    [14] = 'middle-finger-phalanx-intermediate',
    [15] = 'middle-finger-phalanx-distal',
    [17] = 'ring-finger-metacarpal',
    [18] = 'ring-finger-phalanx-proximal',
    [19] = 'ring-finger-phalanx-intermediate',
    [20] = 'ring-finger-phalanx-distal',
    [22] = 'pinky-finger-metacarpal',
    [23] = 'pinky-finger-phalanx-proximal',
    [24] = 'pinky-finger-phalanx-intermediate',
    [25] = 'pinky-finger-phalanx-distal'
  }
end

function startGame()
  hitCounter = 0
  gameTimer = gameTime
  transitioning = false
  currentBackground = 2
  gameplaySound:play()
end

function endGame()
  gameplaySound:stop()
  currentBackground = 1
  if hitCounter > bestScore then
    bestScore = hitCounter
    funkcje1.writeBestScore(bestScore)
  end
end

function lovr.update(dt)
  world:update(dt)
  
  for device, hand in pairs(Hands) do
    hand.skeleton = lovr.headset.getSkeleton(device)
    funkcje1.animateHand(device, hand.skeleton, hand.model, map)

    if lovr.headset.isDown(device, 'grip') then
      hand.holdingGun = true
    else
      hand.holdingGun = false
    end
  end

  for i = #bullets, 1, -1 do
    local bullet = bullets[i]
    local pos = bullet.position
    local vel = bullet.velocity

    pos.x = pos.x + vel.x * dt
    pos.y = pos.y + vel.y * dt
    pos.z = pos.z + vel.z * dt

    bullet.lifespan = bullet.lifespan - dt
    if bullet.lifespan <= 0 or not bullet.collider:isAwake() then
      bullet.collider:destroy()
      table.remove(bullets, i)
    end
  end

  if currentBackground == 2 and not transitioning then
    gameTimer = gameTimer - dt
    if gameTimer <= 0 then
      endGame()
    end

    for _, cube in ipairs(cubes) do
      local pos = cube.position
      local vel = cube.velocity

      pos.x = pos.x + vel.x * dt
      pos.y = pos.y + math.sin(lovr.timer.getTime() * vel.y) * dt
      pos.z = pos.z + vel.z * dt

      if pos.x > 5 or pos.x < -5 then vel.x = -vel.x end
      if pos.y > 5 or pos.y < 0.5 then vel.y = -vel.y end
      if pos.z > 5 or pos.z < -5 then vel.z = -vel.z end

      cube.collider:setPosition(pos.x, pos.y, pos.z)
    end
  end

  for i = #hitTexts, 1, -1 do
    hitTexts[i].timer = hitTexts[i].timer - dt
    if hitTexts[i].timer <= 0 then
      table.remove(hitTexts, i)
    end
  end

  for _, hand in ipairs({'left', 'right'}) do
    local handDevice = 'hand/' .. hand
    if Hands[hand].holdingGun and lovr.headset.wasPressed(handDevice, 'trigger') then
      local x, y, z = lovr.headset.getPosition(handDevice .. '/point')
      local orientation = quat(lovr.headset.getOrientation(handDevice .. '/point'))
      local direction = orientation:direction()
      local offset = 0.1
      local bulletStartX = x + direction.x * offset
      local bulletStartY = y + direction.y * offset
      local bulletStartZ = z + direction.z * offset
      funkcje1.createBullet(world, bullets, bulletStartX, bulletStartY, bulletStartZ, direction.x * bulletsSpeed, direction.y * bulletsSpeed, direction.z * bulletsSpeed)

      if shotSound then
        shotSound:stop()
        shotSound:play()
      else
        print("shotSound is nil")
      end
    end
  end

  for i = #bullets, 1, -1 do
    local bullet = bullets[i]
    if bullet.collider then
      for j = #cubes, 1, -1 do
        local cube = cubes[j]
        if world:collide(bullet.collider:getShapes()[1], cube.collider:getShapes()[1]) then
          local hitText = {}
          hitText.x, hitText.y, hitText.z = cube.collider:getPosition()
          hitText.timer = 1
          if cube.color == "red" then
            hitCounter = hitCounter + 2
            hitText.text = "+2"
            funkcje1.respawnCube(cube, true)
          else
            hitCounter = hitCounter + 1
            hitText.text = "+1"
            funkcje1.respawnCube(cube, false)
          end
          table.insert(hitTexts, hitText)
          bullet.collider:destroy()
          table.remove(bullets, i)

          if hitSound then
            hitSound:stop()
            hitSound:play()
          else
            print("hitSound is nil")
          end

          break
        end
      end
    end
  end

  if transitioning then
    transitionTimer = transitionTimer + dt
    if transitionTimer >= transitionTime then
      transitionTimer = 0
      transitioning = false
      currentBackground = 3 - currentBackground

      if currentBackground == 2 then
        gameplaySound:play()
      else
        gameplaySound:stop()
      end
    end
  end

  if lovr.headset.wasPressed('hand/left', 'x') and not transitioning then
    transitioning = true
    transitionTimer = 0

    if currentBackground == 1 then
      startSound:stop()
      startSound:play()
      startGame()
    else
      scoreSound:stop()
      scoreSound:play()
    end
  end
end

function lovr.draw(pass)
  lovr.graphics.setBackgroundColor(0x202224)

  pass:setMaterial(currentBackground == 1 and backgroundMaterial1 or backgroundMaterial2)
  pass:sphere(0, 0, 0, 50, 0, 1, 0, 0)
  pass:setMaterial()

  if transitioning then
    local alpha = transitionTimer / transitionTime
    pass:setColor(1, 1, 1, alpha)
    pass:setMaterial(currentBackground == 1 and backgroundMaterial2 or backgroundMaterial1)
    pass:sphere(0, 0, 0, 50, 0, 1, 0, 0)
    pass:setColor(1, 1, 1, 1)
    pass:setMaterial()
  end

  pass:setShader(shader)
  pass:plane(0, 0, 0, 25, 25, -math.pi / 2, 1, 0, 0)
  pass:setShader()

  pass:setColor(1, 1, 1)
  for _, bullet in ipairs(bullets) do
    if bullet.collider then
      local x, y, z = bullet.collider:getPosition()
      pass:setColor(1, 0, 0)
      pass:sphere(x, y, z, 0.02)
    end
  end

  if not Hands.left.skeleton and not Hands.right.skeleton then
    pass:text('No skelly :(', 0, 1, -1, 0.1)
    return
  end

  if currentBackground == 2 then
    for _, cube in ipairs(cubes) do
      local x, y, z = cube.collider:getPosition()
      if cube.color == "red" then
        pass:setColor(1, 1, 1)
        pass:draw(RedCubeModel, x, y, z, redCubeSize)
      else
        pass:setColor(1, 1, 1)
        pass:draw(BlueCubeModel, x, y, z, cubeSize)
      end
    end
  end

  pass:setColor(1, 1, 1)
  for _, hitText in ipairs(hitTexts) do
    local textX, textY, textZ = hitText.x, hitText.y + 0.5, hitText.z
    local direction = lovr.math.vec3(playerStartPosition):sub(lovr.math.vec3(textX, textY, textZ)):normalize()
    local angle = math.atan2(direction.x, direction.z)
    pass:push()
    pass:translate(textX, textY, textZ)
    pass:rotate(angle, 0, 1, 0)
    pass:text(hitText.text, 0, 0, 0)
    pass:pop()
  end

  for device, hand in pairs(Hands) do
    if hand.skeleton then
      pass:setColor(0x8000ff)
      pass:setDepthWrite(false)
      for i = 1, #hand.skeleton do
        local x, y, z, _, angle, ax, ay, az = unpack(hand.skeleton[i])
        pass:sphere(mat4(x, y, z, angle, ax, ay, az):scale(0.003))
      end
      pass:setDepthWrite(true)

      for i, handName in ipairs(lovr.headset.getHands()) do
        local position = vec3(lovr.headset.getPosition(handName .. '/point'))
        local orientation = quat(lovr.headset.getOrientation(handName .. '/point'))
        
        local scale = 0.03
        local offsetPosition = vec3(0, -0.05, 0.05)
        local offsetOrientationZ = lovr.math.quat(math.rad(180), 1, 0, 0)
        local offsetOrientationX = lovr.math.quat(math.rad(180), 1, 0, 0)
        local offsetOrientation = offsetOrientationZ * offsetOrientationX

        local modelPosition = position + orientation:mul(offsetPosition)
        local modelOrientation = orientation * offsetOrientation
      
        pass:setColor(1, 1, 1)
        if hand.holdingGun then
          pass:draw(ModelUSP, modelPosition, scale, modelOrientation)
          if lovr.headset.isDown('right', 'a') then
            pass:setColor(0, 1, 0)
            local direction = orientation:direction()
            pass:line(position, position + direction * 50)
          end
        end
      end
      
      pass:setColor(1, 1, 1)
      if currentBackground == 2 then
        local remainingTime = string.format("Pozostaly czas: %d", gameTimer)
        pass:text(remainingTime, 1, 7, -10)
      end

      local worldFromGrip = mat4(lovr.headset.getPose(device))
      pass:setColor(0xffffff)
      pass:setWireframe(true)
      pass:draw(hand.model, worldFromGrip)
      pass:setWireframe(false)
    end
  end

  pass:setColor(1, 1, 1)
  if currentBackground == 2 then
    pass:text('Hit Counter: ' .. hitCounter, 1, 10, -10)
  end
  if currentBackground == 1 then
    pass:text('Twoj wynik: ' .. hitCounter, 1, 2, -7)
    pass:text('Aby rozpoczac kliknij X na lewyn kontrolerze ', 1, 1, -7)
    pass:text('Najlepszy wynik: ' .. bestScore, 1, 3, -7)
    pass:text('Credits:',1,8,-15)
    pass:text('Created by: Gabriela Zanko, Kacper Skotnicki, Adam Wawrzyk, Mateusz Wisniewski',-3,7.3,-15)
    pass:text('Music: LookAss',1,6.6,-15)
  end
end
