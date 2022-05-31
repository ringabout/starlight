type
  WeakMap*[K; V] = ref object


proc newWeakMap*[K; V](): WeakMap[K, V] {.importjs: "new WeakMap()".}
# proc `[]`*[K, V](d: WeakMap[K, V], k: K): V {.importjs: "#[#]".}
# proc `[]=`*[K, V](d: WeakMap[K, V], k: K, v: V) {.importjs: "#[#] = #".}

proc get*[K, V](d: WeakMap[K, V], k: K): V {.importjs: "#.get(#)".}
proc put*[K, V](d: WeakMap[K, V], k: K, v: V) {.importjs: "#.set(#, #)".}
proc contains*[K, V](d: WeakMap[K, V], k: K): bool {.importjs: "#.has(#)".}

when isMainModule:
  import jsconsole


  let x = newWeakMap[int, cstring]()
  x[1] = cstring"12"
  console.log x[1]


# type
#   WeakMap*[K: string; V] = ref object


# proc newWeakMap*[K: string; V](): WeakMap[K, V] = discard


# let x = newWeakMap[int, cstring]()