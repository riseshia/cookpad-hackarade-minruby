require "minruby"

def fizzbuzz(n)
  if n % 3 == 0
    if n % 5 == 0
      "FizzBuzz"
    else
      "Fizz"
    end
  else
    if n % 5 == 0
      "Buzz"
    else
      n
    end
  end
end

# An implementation of the evaluator
def evaluate(exp, env)
  # exp: A current node of AST
  # env: An environment (explained later)

  case exp[0]
  when "lit"
    exp[1] # return the immediate value as is
  when "+"
    evaluate(exp[1], env) + evaluate(exp[2], env)
  when "-"
    evaluate(exp[1], env) - evaluate(exp[2], env)
  when "*"
    evaluate(exp[1], env) * evaluate(exp[2], env)
  when "%"
    evaluate(exp[1], env) % evaluate(exp[2], env)
  when "/"
    evaluate(exp[1], env) / evaluate(exp[2], env)
  when "=="
    evaluate(exp[1], env) == evaluate(exp[2], env)
  when ">"
    evaluate(exp[1], env) > evaluate(exp[2], env)
  when "<"
    evaluate(exp[1], env) < evaluate(exp[2], env)
  when "stmts"
    i = 1
    last = nil
    while exp[i]
      list = evaluate(exp[i], env)
      i += 1
    end
    last
  when "var_ref"
    env[exp[1]]
  when "var_assign"
    env[exp[1]] = evaluate(exp[2], env)
  when "if"
    if evaluate(exp[1], env)
      evaluate(exp[2], env)
    else
      evaluate(exp[3], env)
    end
  when "while"
    while evaluate(exp[1], env)
      evaluate(exp[2], env)
    end
  when "func_call"
    # Lookup the function definition by the given function name.
    func = $function_definitions[exp[1]]

    if func.nil?
      case exp[1]
      when "p"
        p(evaluate(exp[2], env))
      when "Integer"
        Integer(evaluate(exp[2], env))
      when "fizzbuzz"
        fizzbuzz(evaluate(exp[2], env))
      else
        puts exp[1]
        raise("unknown builtin function")
      end
    else
      # prepare args
      args = []
      i = 0
      while exp[i + 2]
        args[i] = evaluate(exp[i + 2], env)
        i = i + 1
      end
      # prepare param
      param_names = func[0]
      new_env = {}
      i = 0
      while param_names[i]
        new_env[param_names[i]] = args[i]
        i = i + 1
      end
      # eval
      evaluate(func[1], new_env)
    end

  when "func_def"
    $function_definitions[exp[1]] = [exp[2], exp[3]]
  when "ary_new"
    ary = []
    i = 0
    while exp[i + 1]
      ary[i] = evaluate(exp[i + 1], env)
      i = i + 1
    end
    ary
  when "ary_ref"
    ary = evaluate(exp[1], env)
    idx = evaluate(exp[2], env)
    ary[idx]
  when "ary_assign"
    ary = evaluate(exp[1], env)
    idx = evaluate(exp[2], env)
    val = evaluate(exp[3], env)
    ary[idx] = val
  when "hash_new"
    hsh = {}
    i = 0
    while exp[i + 1]
      key = evaluate(exp[i + 1], env)
      val = evaluate(exp[i + 2], env)
      hsh[key] = val
      i = i + 2
    end
    hsh
  else
    p("error")
    pp(exp)
    raise("unknown node")
  end
end

$function_definitions = {}
env = {}

# `minruby_load()` == `File.read(ARGV.shift)`
# `minruby_parse(str)` parses a program text given, and returns its AST
evaluate(minruby_parse(minruby_load()), env)
