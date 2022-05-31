type
  Seq*[T] = ref object

func `[]`*[T](s: Seq[T], i: int): T {.importjs: "#[#]".}
func `[]=`*[T](s: Seq[T], i: int, v: T) {.importjs: "#[#] = #".}

func newJSeq*[T](len: int = 0): Seq[T] {.importjs: "new Array(#)".}
func len*[T](s: Seq[T]): int {.importjs: "#.length".}
proc add*[T](s: Seq[T]; x: T) {.importjs: "#.push(#)".}
proc pop*[T](s: Seq[T]): T {.importjs: "#.pop()".}

proc shrink*[T](s: Seq[T]; shorterLen: int) {.importjs: "#.length = #", noSideEffect.}
