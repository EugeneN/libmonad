# http://jsfiddle.net/n6GHF/10/

say = (m...) ->
    #document.write "<div>Got result: #{m.join ', '}</div>"
    console.log m...

identity = (x) -> x

log_result = (x...) -> say x...

first = (s) -> s[0]

drop_while = (f, s) ->
    for i in s
        return i unless (f i)

is_null = (v...) ->
    if v.length is 0
        # special case: returning error literal when called without params
        null
    else
        v[0] is null

SEX = 'sex'
is_sex = (v...) ->
    if v.length is 0
        # special case: returning error literal when called without params
        SEX
    else
        v[0] is SEX

is_function = (v) -> typeof v is 'function'

domonad = ({result, bind}, functions, init_value) ->
    f0 = bind (result init_value), functions[0]

    ([f0].concat functions[1...]).reduce (a, b) ->
        bind a, b

maybe_m = ({is_error}) ->
    zero: -> is_error() #?

    result: (v) -> v

    bind: (mv, f) ->
        if (is_error mv) then mv else (f mv)

    plus: (mvs...) ->
        first (drop_while is_error mvs)

cont_m = ->
    result: (v) ->
        (c) -> c v

    bind: (mv, f) ->
        (c) ->
            mv ((v) -> ((f v) c))

cont_t = (inner) ->
    result: (v) ->
        (c) -> c (inner.result v)

    bind: (mv, f) ->
        (c) ->
            # pass decision on what to do with `f` and `v` to the inner monad
            # inner monads bind's result should return result, which we
            # should wrap into a function, which, when called
            # with a continuation, will return the actual result returned
            # from inner monad's wrapped function

            get_h = (v) ->
                inner_bind_res = inner.bind v, f

                # XXX: how to determine if `inner_bind_res` should be wrapped into a
                # continuation passed function?

                # theoretically `f` would probably always be a cont_m-compatible
                # function, that is:
                #
                #                    f: v -> f -> mv,
                #
                # where `mv` is cont_m's value.

                # in practice, it isn't
                if is_function inner_bind_res
                    inner_bind_res
                else
                    (c) -> c inner_bind_res

            mv ((v) -> (get_h v) c)

run = (c) -> c log_result

lift_sync1 = (f, delay) ->
    (x) ->
        (c) ->
            setTimeout(
                -> c (f x)
                delay
            )

e1 = (x) -> say 1; x * x
e2 = (x) -> say 2; x + 2; SEX
e3 = (x) -> say 3; x + 0.25

f1 = lift_sync1 e1, 100
f2 = lift_sync1 e2, 200
f3 = lift_sync1 e3, 300

#z = bind (bind (bind (result 3), f3), f2), f1

y = domonad cont_m(), [f1, f2, f3, f1], 33

cont_maybe = cont_t (maybe_m {is_error: is_sex})
u = domonad cont_maybe, [f1, f2, f3], 33

#say u
u say
