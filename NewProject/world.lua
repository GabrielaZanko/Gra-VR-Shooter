local world = {}

function world.initWorld()
  world.world = lovr.physics.newWorld(0, -9.81, 0, true)
  world.world:setLinearDamping(0.01)
  world.world:setAngularDamping(0.005)
  world.world:newBoxCollider(0, 0, 0, 50, 0.05, 50):setKinematic(true)
end

function world.update(dt)
  world.world:update(dt)
end

function world.getWorld()
  return world.world
end

return world
