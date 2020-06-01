import ".." / [game_types, vmath, dsl]

const Query = {HasTransform2d, HasMove}

proc update(game: var Game, entity: Entity) =
   template transform: untyped = game.transform[entity]
   template move: untyped = game.move[entity]

   if move.direction.x != 0.0 or move.direction.y != 0.0:
      transform.translation.x += move.direction.x * move.speed
      transform.translation.y += move.direction.y * move.speed

      game.mixDirty(entity)

proc sysMove*(game: var Game) =
   for i in 0 ..< MaxEntities:
      if game.world[i] * Query == Query:
         update(game, Entity(i))
