local player = require("player")
local enemy = require("enemy")
local bullet = require("bullet")
local world = require("world")
local input = require("input")
local utils = require("utils")

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
  utils.initGlobals()
  initGrid()
  world.initWorld()
  local w = world.getWorld()
  player.init(w)
  enemy.init(w)
  bullet.init(w)
  input.init(w, player.getHands(), bullet.create)

  backgroundTexture1 = lovr.graphics.newTexture('assets/textures/background1.jpg')
  backgroundTexture2 = lovr.graphics.newTexture('assets/textures/background2.jpg')
  backgroundMaterial1 = lovr.graphics.newMaterial({ texture = backgroundTexture1 })
  backgroundMaterial2 = lovr.graphics.newMaterial({ texture = backgroundTexture2 })

  input.playStartSound()
  
  cubeSize = 0.2
  redCubeSize = 0.1
  bulletsSpeed = 50
  gameTime = 30
  gameTimer = gameTime
  bestScore = utils.readBestScore() or 0
end

function startGame()
  utils.resetGame()
  input.playGameplaySound()
  enemy.spawnCubes()
end

function endGame()
  input.stopGameplaySound()
  if utils.updateBestScore() then
    print("New high score!")
  end
end

function lovr.update(dt)
  world.update(dt)
  player.update(dt)
  bullet.update(dt)
  
  if utils.isGameRunning() then
    enemy.update(dt)
    utils.updateGameTimer(dt, endGame)
  end
  
  input.update(dt)
end

function lovr.draw(pass)
  utils.drawBackground(pass, backgroundMaterial1, backgroundMaterial2)
  
  pass:setShader(shader)
  pass:plane(0, 0, 0, 25, 25, -math.pi / 2, 1, 0, 0) 
  pass:setShader()
  
  player.draw(pass)--Błąd, jeden wielki błąd
  
  if utils.isGameRunning() then
    enemy.draw(pass)
    bullet.draw(pass)--tutaj też, do poprawy
    utils.drawGameInfo(pass)
  else
    utils.drawMenu(pass)
  end
end
