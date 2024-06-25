local utils = require("utils")

local player = {}

function player.init(world)
  player.model = lovr.graphics.newModel('assets/models/PISTOLETPINK.glb')
  player.position = lovr.math.newVec3(0, 1, -2)
  player.hands = {
    left = {model = lovr.graphics.newModel('assets/models/left.glb'), skeleton = nil, holdingGun = false},
    right = {model = lovr.graphics.newModel('assets/models/right.glb'), skeleton = nil, holdingGun = false}
  }
  player.map = utils.getHandMap()

  for i, hand in ipairs(lovr.headset.getHands()) do
    local position = lovr.math.newVec3(lovr.headset.getPosition(hand .. '/point'))
    local orientation = lovr.math.quat(lovr.headset.getOrientation(hand .. '/point'))

    local collider = world:newBoxCollider(position, 0.5, 0.5, 0.5)
    collider:setFriction(0.8)
  end
end

function player.update(dt)
  for device, hand in pairs(player.hands) do
    hand.skeleton = lovr.headset.getSkeleton(device)
    utils.animateHand(device, hand.skeleton, hand.model, player.map)

    if lovr.headset.isDown(device, 'grip') then
      hand.holdingGun = true
    else
      hand.holdingGun = false
    end
  end
end

function player.draw(pass)
  for device, hand in pairs(player.hands) do
    if hand.skeleton then
      pass:setColor(0x8000ff)
      pass:setDepthWrite(false)
      for i = 1, #hand.skeleton do
        local x, y, z, _, angle, ax, ay, az = unpack(hand.skeleton[i])
        pass:sphere(mat4(x, y, z, angle, ax, ay, az):scale(0.003))
      end
      pass:setDepthWrite(true)

      for _, handName in ipairs(lovr.headset.getHands()) do
        local position = lovr.math.newVec3(lovr.headset.getPosition(handName .. '/point'))
        local orientation = lovr.math.quat(lovr.headset.getOrientation(handName .. '/point'))

        local scale = 0.03
        local offsetPosition = lovr.math.newVec3(0, -0.05, 0.05)
        local offsetOrientation = lovr.math.quat(math.rad(180), 1, 0, 0) * lovr.math.quat(math.rad(180), 1, 0, 0)

        local modelPosition = position + orientation:mul(offsetPosition)
        local modelOrientation = orientation * offsetOrientation

        pass:setColor(1, 1, 1)
        if hand.holdingGun then
          pass:draw(player.model, modelPosition, scale, modelOrientation)
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
end

function player.getHands()
  return player.hands
end

return player
