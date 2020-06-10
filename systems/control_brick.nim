import ".." / [game_types, blueprints, utils, registry, storage]

const Query = {HasControlBrick, HasCollide, HasFade}

proc update(game: var Game, entity: Entity) =
   template collide: untyped = game.collide[entity.index]
   template fade: untyped = game.fade[entity.index]

   if collide.collision.other != invalidId:
      fade.step = 0.02

      if rand(1.0) > 0.98:
         discard game.getBall(float32(game.windowWidth / 2),
               float32(game.windowHeight / 2))

proc sysControlBrick*(game: var Game) =
   for (entity, has) in game.world.pairs:
      if has * Query == Query:
         update(game, entity)
