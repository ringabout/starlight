type
  Map*[K, V] = ref object

# proc `[]`*[K, V](d: Map[K, V], k: K): V {.importjs: "#[#]".}
# proc `[]=`*[K, V](d: Map[K, V], k: K, v: V) {.importjs: "#[#] = #".}

proc get*[K, V](d: Map[K, V], k: K): V {.importjs: "#.get(#)".}
proc put*[K, V](d: Map[K, V], k: K, v: V) {.importjs: "#.set(#, #)".}

proc newMap*[K, V](): Map[K, V] {.importjs: "new Map()".}

proc contains*[K, V](d: Map[K, V], k: K): bool {.importjs: "#.hasOwnProperty(#)".}

proc del*[K, V](d: Map[K, V], k: K) {.importjs: "delete #[#]".}

iterator items*[K, V](d: Map[K, V]): K =
  var kkk: K
  {.emit: ["for (", kkk, " in ", d, ") {"].}
  yield kkk
  {.emit: ["}"].}