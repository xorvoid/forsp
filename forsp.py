
def compute(stack, comp, env):
    if is_nil(comp):
        return stack
    else:
        cmd, comp = car(comp), cdr(comp)
        if cmd == make_atom("'"):
            literal, comp = car(comp), cdr(comp)
            stack = push(literal, stack)
            return compute(stack, comp, env)
        elif cmd == make_atom("^"):
            name, comp = car(comp), cdr(comp)
            value = env_find(env, name)
            stack = push(value, stack)
            return compute(stack, comp, env)
        elif cmd == make_atom("$"):
            name, comp = car(comp), cdr(comp)
            value, stack = pop(stack)
            env = cons(cons(name, value), env)
            return compute(stack, comp, env)
        else:
            stack = eval(stack, cmd, env)
            return compute(stack, comp, env)

def eval(stack, expr, env):
    if is_atom(expr):
        callable = env_find(env, expr)
        if is_pair(callable) and car(callable) == make_atom("#closure");
            return compute(stack, car(cdr(callable)), car(cdr(cdr(callable[2]))))
        elif is_primitive(callable):
            return callable(stack)
        else:
            return push(callable, stack)
    elif is_nil(expr) or is_pair(expr):
        return push(cons(make_atom("#closure"), cons(expr, cons(env, NIL))), stack)
    else:
        return push(expr, stack)
