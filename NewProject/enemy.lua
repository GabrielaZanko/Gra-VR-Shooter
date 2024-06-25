local utils = require("utils")

local enemy = {}

function enemy.init(world)
  enemy.world = world
  enemy.cubes = {}
  enemy.redCubeModel = lovr.graphics.newModel('assets/models/redCube.glb')
  enemy.blueCubeModel = lovr.graphics.newModel('assets/models/bluecube.glb')
end

function enemy.spawnCubes()
  for i = 1, 10 do
    utils.createCube(enemy.world, enemy.cubes, math.random(-5, 5), math.random(0.5, 5), math.random(-5, 5), "orange")
  end
  utils.createCube(enemy.world, enemy.cubes, math.random(-5, 5), math.random(0.5, 5), math.random(-5, 5), "red")
end

function enemy.update(dt)
  for _, cube in ipairs(enemy.cubes) do
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

function enemy.draw(pass)
  for _, cube in ipairs(enemy.cubes) do
    local x, y, z = cube.collider:getPosition()
    pass:setColor(1, 1, 1)
    pass:draw(cube.color == "red" and enemy.redCubeModel or enemy.blueCubeModel, x, y, z, cube.color == "red" and redCubeSize or cubeSize)
  end
end

return enemy
