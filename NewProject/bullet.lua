local utils = require("utils")
local enemy = require("enemy")

local bullet = {}

function bullet.init(world)
  bullet.bullets = {}
  bullet.world = world
end

function bullet.update(dt)
  if not bullet.world then
    return
  end

  for i = #bullet.bullets, 1, -1 do
    local b = bullet.bullets[i]
    local pos = b.position
    local vel = b.velocity

    pos.x = pos.x + vel.x * dt
    pos.y = pos.y + vel.y * dt
    pos.z = pos.z + vel.z * dt

    b.lifespan = b.lifespan - dt
    if b.lifespan <= 0 or not b.collider:isAwake() then
      b.collider:destroy()
      table.remove(bullet.bullets, i)
    end
  end

  for i = #bullet.bullets, 1, -1 do
    local bullet = bullet.bullets[i]
    if bullet.collider then
      for j = #enemy.cubes, 1, -1 do
        local cube = enemy.cubes[j]
        if bullet.world:collide(bullet.collider:getShapes()[1], cube.collider:getShapes()[1]) then
          local hitText = {}
          hitText.x, hitText.y, hitText.z = cube.collider:getPosition()
          hitText.timer = 1
          if cube.color == "red" then
            hitCounter = hitCounter + 2
            hitText.text = "+2"
            utils.respawnCube(cube, true)
          else
            hitCounter = hitCounter + 1
            hitText.text = "+1"
            utils.respawnCube(cube, false)
          end
          table.insert(hitTexts, hitText)
          bullet.collider:destroy()
          table.remove(bullet.bullets, i)

          if input.hitSound then
            input.hitSound:stop()
            input.hitSound:play()
          else
            print("hitSound is nil")
          end

          break
        end
      end
    end
  end
end

function bullet.draw(pass)
  pass:setColor(1, 0, 0)
  for _, b in ipairs(bullet.bullets) do
    local x, y, z = b.collider:getPosition()
    pass:sphere(x, y, z, 0.02)
  end
end

function bullet.create(x, y, z, vx, vy, vz)
  if not bullet.world then
    print("Error: World is not initialized in bullet module")
    return
  end
  local b = utils.createBullet(bullet.world, bullet.bullets, x, y, z, vx, vy, vz)
  table.insert(bullet.bullets, b)
end

return bullet
