local funkcje = {}

function funkcje.animateHand(device, skeleton, model, map)
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

function funkcje.createBullet(world, bullets, x, y, z, vx, vy, vz)
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

function funkcje.createCube(world, cubes, x, y, z, color)
  local size
  if color == "red" then
    size = redCubeSize * 2
  else
    size = cubeSize * 2
  end

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

function funkcje.moveCubeRandomly(cube)
  local x = math.random(-5, 5)
  local y = math.random(0.5, 5)
  local z = math.random(-5, 5)
  cube:setPosition(x, y, z)
end

function funkcje.respawnCube(cube, isRed)
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

function funkcje.readBestScore()
  local file = io.open("best_score.txt", "r")
  if file then
    local bestScore = tonumber(file:read("*all"))
    file:close()
    return bestScore
  end
  return 0
end

function funkcje.writeBestScore(bestScore)
  local file = io.open("best_score.txt", "w")
  if file then
    file:write(tostring(bestScore))
    file:close()
  end
end

return funkcje
