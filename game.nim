import
   std / [random, monotimes], sdl2,
   game_types, blueprints, registry, storage, utils,
   systems / [collide, control_ball, control_brick, control_paddle, draw2d,
      fade, move, shake, transform2d, handle_events]

proc initGame*(windowWidth, windowHeight: int32): Game =
   discard sdl2.init(INIT_VIDEO or INIT_EVENTS)

   let window = createWindow("Breakout", SDL_WINDOWPOS_CENTERED,
         SDL_WINDOWPOS_CENTERED, windowWidth, windowHeight, SDL_WINDOW_SHOWN)

   let renderer = createRenderer(window, -1, Renderer_Accelerated or Renderer_PresentVsync)

   result = Game(
      world: initStorage[set[HasComponent]](maxEntities),
      entities: initRegistry(),
      isRunning: true,

      windowWidth: windowWidth,
      windowHeight: windowHeight,

      window: window,
      renderer: renderer,

      clearColor: [0'u8, 0, 0, 255],

      collide: newSeq[Collide](maxEntities),
      draw2d: newSeq[Draw2d](maxEntities),
      fade: newSeq[Fade](maxEntities),
      hierarchy: newSeq[Hierarchy](maxEntities),
      move: newSeq[Move](maxEntities),
      previous: newSeq[Previous](maxEntities),
      shakePtr: newShake(),
      transform: newSeq[Transform2d](maxEntities))

proc update(game: var Game) =
   # The Game engine that consist of these systems
   # Player input and AI
   sysControlBall(game)
   sysControlBrick(game)
   sysControlPaddle(game)
   # Game logic
   sysShake(game)
   sysFade(game)
   # Garbage collection
   cleanup(game)
   # Animation and movement
   sysMove(game)
   sysTransform2d(game)
   # Post-transform logic
   sysCollide(game)

proc render(game: var Game, intrpl: float32) =
   sysDraw2d(game, intrpl)
   game.renderer.present()

proc run(game: var Game) =
   const
      ticksPerSec = 25
      skippedTicks = 1_000_000_000 div ticksPerSec # to nanosecs per tick
      maxFramesSkipped = 5 # 20% of ticksPerSec

   var
      lastTime = getMonoTime().ticks
      accumulator = 0'i64

   while true:
      handleEvents(game)
      if not game.isRunning: break

      let now = getMonoTime().ticks
      accumulator += now - lastTime
      lastTime = now

      var isUpdated = false
      var framesSkipped = 0
      while accumulator >= skippedTicks and framesSkipped < maxFramesSkipped:
         game.update()
         accumulator -= skippedTicks
         framesSkipped.inc
         isUpdated = true

      if isUpdated: game.render(accumulator.float32 / skippedTicks.float32)

proc main =
   randomize()
   var game = initGame(740, 555)

   sceneMain(game)
   game.run()

   destroy(game.window)
   destroy(game.renderer)
   sdl2.quit()

main()
