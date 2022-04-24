type
  JSeq*[T] = ref object

proc `[]`*[T](s: JSeq[T], i: int): T {.importjs: "#[#]", noSideEffect.}
proc `[]=`*[T](s: JSeq[T], i: int, v: T) {.importjs: "#[#] = #", noSideEffect.}

proc newJSeq*[T](len: int = 0): JSeq[T] {.importjs: "new Array(#)".}
proc len*[T](s: JSeq[T]): int {.importjs: "#.length", noSideEffect.}
proc add*[T](s: JSeq[T]; x: T) {.importjs: "#.push(#)", noSideEffect.}

proc shrink*[T](s: JSeq[T]; shorterLen: int) {.importjs: "#.length = #", noSideEffect.}
