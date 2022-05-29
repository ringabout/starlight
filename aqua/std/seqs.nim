type
  JSeq*[T] = ref object

func `[]`*[T](s: JSeq[T], i: int): T {.importjs: "#[#]".}
func `[]=`*[T](s: JSeq[T], i: int, v: T) {.importjs: "#[#] = #".}

func newJSeq*[T](len: int = 0): JSeq[T] {.importjs: "new Array(#)".}
func len*[T](s: JSeq[T]): int {.importjs: "#.length".}
proc add*[T](s: JSeq[T]; x: T) {.importjs: "#.push(#)".}
proc pop*[T](s: JSeq[T]; x: T) {.importjs: "#.pop(#)".}

proc shrink*[T](s: JSeq[T]; shorterLen: int) {.importjs: "#.length = #", noSideEffect.}
