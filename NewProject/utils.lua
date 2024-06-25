local utils = {}

local gameTimer
local bestScore
local hitCounter = 0
local isRunning = false
local hitTexts = {}

function utils.initGlobals()
  gameTimer = 30
  bestScore = utils.readBestScore() or 0
end

function utils.resetGame()
  hitCounter = 0
  gameTimer = 30
  isRunning = true
end

function utils.isGameRunning()
  return isRunning
end

function utils.updateGameTimer(dt, endGameCallback)
  gameTimer = gameTimer - dt
  if gameTimer <= 0 then
    isRunning = false
    endGameCallback()
  end
end

function utils.updateBestScore()
  if hitCounter > bestScore then
    bestScore = hitCounter
    utils.writeBestScore(bestScore)
    return true
  end
  return false
end

function utils.drawBackground(pass, backgroundMaterial1, backgroundMaterial2)
  lovr.graphics.setBackgroundColor(0x202224)

  pass:setMaterial(isRunning and backgroundMaterial2 or backgroundMaterial1)
  pass:sphere(0, 0, 0, 50, 0, 1, 0, 0)
  pass:setMaterial()
end

function utils.drawGameInfo(pass)
  pass:text('Hit Counter: ' .. hitCounter, 1, 10, -10)
end

function utils.drawMenu(pass)
  pass:text('Twoj wynik: ' .. hitCounter, 1, 2, -7)
  pass:text('Aby rozpoczac kliknij X na lewyn kontrolerze ', 1, 1, -7)
  pass:text('Najlepszy wynik: ' .. bestScore, 1, 3, -7)
  pass:text('Credits:', 1, 8, -15)
  pass:text('Created by: Gabriela Zanko', -3, 7.3, -15)
  pass:text('Music: LookAss', 1, 6.6, -15)
end

function utils.getHandMap()
  return {
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

function utils.animateHand(device, skeleton, model, map)
  model:resetNodeTransforms()
  
  if not skeleton then return end
  
  local modelFromWrist = mat4(model:getNodeTransform(map[2]))
  local wristFromModel = mat4(modelFromWrist):invert()
  
  local x, y, z, _, angle, ax, ay, az = unpack(skeleton[2])
  local worldFromWrist = mat4(x, y, z, angle, ax, ay, az)
  local wristFromWorld = mat4(worldFromWrist):invert()
  
  local modelFromWorld = modelFromWrist * wristFromWorld
  
  for index, node in pairs(map) do
    local x, y, z, _, angle, ax, ay, az = unpack(skeleton[index])
    local jointWorld = mat4(x, y, z, angle, ax, ay, az)
    local jointModel = modelFromWorld * jointWorld
    model:setNodeTransform(node, jointModel)
  end
  
  local worldFromGrip = mat4(lovr.headset.getPose(device))
  local gripFromWorld = mat4(worldFromGrip):invert()
  model:setNodeTransform(model:getRootNode(), gripFromWorld * worldFromWrist * wristFromModel)
end

function utils.createBullet(world, bullets, x, y, z, vx, vy, vz)
  local bulletCollider = world:newSphereCollider(x, y, z, 0.1)
  bulletCollider:setLinearVelocity(vx, vy, vz)
  bulletCollider:setMass(0.1)
  bulletCollider:setUserData({type = 'bullet', lifespan = 2})

  table.insert(bullets, {
    position = lovr.math.newVec3(x, y, z),
    velocity = lovr.math.newVec3(vx, vy, vz),
    collider = bulletCollider,
    lifespan = 2
  })
end

function utils.createCube(world, cubes, x, y, z, color)
  local size = color == "red" and redCubeSize * 2 or cubeSize * 2

  local cubeCollider = world:newBoxCollider(x, y, z, size, size, size)
  cubeCollider:setKinematic(true)

  local velocity = lovr.math.newVec3(math.random(-1, 1), math.random(-1, 1), math.random(-1, 1))
  if color == "red" then
    velocity:mul(1.8)
  end

  table.insert(cubes, {
    collider = cubeCollider,
    position = lovr.math.newVec3(x, y, z),
    velocity = velocity,
    color = color
  })

  return cubes[#cubes]
end

function utils.respawnCube(cube, isRed)
  local x = math.random(-5, 5)
  local y = math.random(0.5, 5)
  local z = math.random(-5, 5)
  cube.position:set(x, y, z)
  cube.collider:setPosition(x, y, z)

  cube.velocity:set(math.random(-1, 1), math.random(-1, 1), math.random(-1, 1))
  if isRed then
    cube.velocity:mul(1.8)
  end
end

function utils.readBestScore()
  local file = io.open("best_score.txt", "r")
  if file then
    local bestScore = tonumber(file:read("*all"))
    file:close()
    return bestScore
  end
  return 0
end

function utils.writeBestScore(bestScore)
  local file = io.open("best_score.txt", "w")
  if file then
    file:write(tostring(bestScore))
    file:close()
  end
end

return utils
