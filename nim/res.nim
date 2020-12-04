# We expect this to be used as `res.ult`

type
    ult*[T, E] = object
        case isOk*: bool
        of false:
            error*: E
        of true:
            value*: T


template ok*[E](r: type ult[void, E]): r =
    r(isOk: true)

template ok*[T, E](r: type ult[T, E], theValue: auto): r =
    r(isOk: true, value: theValue)

template err*[T](r: type ult[T, void]): r =
    r(isOk: false)

template err*[T, E](r: type ult[T, E], theError: auto): r =
    r(isOk: false, error: theError)

template ok*(value: auto): auto = ok(typeof(result), value)

template err*(error: auto): auto = err(typeof(result), error)

