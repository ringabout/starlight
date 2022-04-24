type
  JDict*[K, V] = ref object

proc `[]`*[K, V](d: JDict[K, V], k: K): V {.importjs: "#[#]".}
proc `[]=`*[K, V](d: JDict[K, V], k: K, v: V) {.importjs: "#[#] = #".}

proc newJDict*[K, V](): JDict[K, V] {.importjs: "{@}".}

proc contains*[K, V](d: JDict[K, V], k: K): bool {.importjs: "#.hasOwnProperty(#)".}

proc del*[K, V](d: JDict[K, V], k: K) {.importjs: "delete #[#]".}

iterator keys*[K, V](d: JDict[K, V]): K =
  var kkk: K
  {.emit: ["for (", kkk, " in ", d, ") {"].}
  yield kkk
  {.emit: ["}"].}