local player = require("player")
local utils = require("utils")

local input = {}

function input.init(world, hands, createBullet)
  input.shotSound = lovr.audio.newSource('assets/sounds/shot.mp3', { decode = true })
  input.hitSound = lovr.audio.newSource('assets/sounds/hit.mp3', { decode = true })
  input.gameplaySound = lovr.audio.newSource('assets/sounds/LookAss.mp3', { decode = true })
  input.scoreSound = lovr.audio.newSource('assets/sounds/score.mp3', { decode = true })
  input.startSound = lovr.audio.newSource('assets/sounds/start.mp3', { decode = true })
  input.world = world
  input.hands = hands
  input.createBullet = createBullet
end

function input.update(dt)
  if not utils.isGameRunning() and lovr.headset.wasPressed('hand/left', 'x') then
    startGame()
  end

  for _, hand in ipairs({'left', 'right'}) do
    local handDevice = 'hand/' .. hand
    if player.getHands()[hand].holdingGun and lovr.headset.wasPressed(handDevice, 'trigger') then
      local x, y, z = lovr.headset.getPosition(handDevice .. '/point')
      local orientation = quat(lovr.headset.getOrientation(handDevice .. '/point'))
      local direction = orientation:direction()
      local offset = 0.1
      local bulletStartX = x + direction.x * offset
      local bulletStartY = y + direction.y * offset
      local bulletStartZ = z + direction.z * offset
      input.createBullet(bulletStartX, bulletStartY, bulletStartZ, direction.x * bulletsSpeed, direction.y * bulletsSpeed, direction.z * bulletsSpeed)

      if input.shotSound then
        input.shotSound:stop()
        input.shotSound:play()
      else
        print("shotSound is nil")
      end
    end
  end
end

function input.playStartSound()
  input.startSound:play()
end

function input.playGameplaySound()
  input.gameplaySound:play()
end

function input.stopGameplaySound()
  input.gameplaySound:stop()
end

return input
