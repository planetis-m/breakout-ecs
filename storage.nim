import registry, algorithm

type
   Storage*[T] = object
      len: int
      sparseToPacked: array[maxEntities, EntityImpl] # mapping from sparse handles to dense values
      packedToSparse: array[maxEntities, Entity] # mapping from dense values to sparse handles
      packed: seq[T]

proc initStorage*[T](denseCap: Natural): Storage[T] =
   result = Storage(packed: newSeq[T](denseCap))
   result.sparseToPacked.fill(invalidId.EntityImpl)
   result.packedToSparse.fill(invalidId)

proc contains*[T](s: Storage[T], entity: Entity): bool =
   # Returns true if the sparse is registered to a dense index.
   result = s.sparseToPacked[entity.index] != invalidId.EntityImpl

proc `[]=`*[T](s: var Storage[T], entity: Entity, value: T) =
   let entityIndex = entity.index
   var packedIndex = s.sparseToPacked[entityIndex]
   if packedIndex == invalidId.EntityImpl:
      packedIndex = s.len.EntityImpl
      s.packedToSparse[packedIndex] = entity
      s.packed[packedIndex] = value
      s.sparseToPacked[entityIndex] = packedIndex
      s.len.inc
   else:
      s.packed[packedIndex] = value

proc delete*[T](s: var Storage[T], entity: Entity) =
   let entityIndex = entity.index
   let packedIndex = s.sparseToPacked[entityIndex]
   if packedIndex == invalidId.EntityImpl:
      raise newException(KeyError, "Entity not in Storage")
   let lastIndex = s.packed.high
   let lastEntity = s.packedToSparse[lastIndex]
   s.sparseToPacked[entityIndex] = invalidId.EntityImpl
   s.sparseToPacked[lastEntity.index] = packedIndex
   swap(s.packed[packedIndex], s.packed[lastIndex])
   s.packed[lastIndex] = default(T)
   swap(s.packedToSparse[packedIndex], s.packedToSparse[lastIndex])
   s.packedToSparse[lastIndex] = invalidId
   s.len.dec

proc `[]`*[T](s: var Storage[T], entity: Entity): var T =
   if not s.contains(entity):
      raise newException(KeyError, "Entity not in Storage")
   let entityIndex = entity.index
   result = s.packed[s.sparseToPacked[entityIndex]]

proc `[]`*[T](s: Storage[T], entity: Entity): lent T =
   if not s.contains(entity):
      raise newException(KeyError, "Entity not in Storage")
   let entityIndex = entity.index
   result = s.packed[s.sparseToPacked[entityIndex]]

proc clear*[T](s: var Storage[T]) =
   s.sparseToPacked.fill(invalidId.EntityImpl)
   s.packedToSparse.fill(invalidId)
   s.len = 0

proc len*[T](s: Storage[T]): int = s.len

iterator pairs*[T](s: Storage[T]): (Entity, lent T) =
   for i in 0 ..< s.len:
      yield (s.packedToSparse[i], s.packed[i])
