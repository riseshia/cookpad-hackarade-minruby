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
def evaluate(exp, lenv, function_definitions)
  # exp: A current node of AST
  # lenv: An environment (explained later)

  case exp[0]
  when "lit"
    exp[1] # return the immediate value as is
  when "+"
    evaluate(exp[1], lenv, function_definitions) + evaluate(exp[2], lenv, function_definitions)
  when "-"
    evaluate(exp[1], lenv, function_definitions) - evaluate(exp[2], lenv, function_definitions)
  when "*"
    evaluate(exp[1], lenv, function_definitions) * evaluate(exp[2], lenv, function_definitions)
  when "%"
    evaluate(exp[1], lenv, function_definitions) % evaluate(exp[2], lenv, function_definitions)
  when "/"
    evaluate(exp[1], lenv, function_definitions) / evaluate(exp[2], lenv, function_definitions)
  when "=="
    evaluate(exp[1], lenv, function_definitions) == evaluate(exp[2], lenv, function_definitions)
  when ">"
    evaluate(exp[1], lenv, function_definitions) > evaluate(exp[2], lenv, function_definitions)
  when "<"
    evaluate(exp[1], lenv, function_definitions) < evaluate(exp[2], lenv, function_definitions)
  when "stmts"
    i = 1
    last = nil
    while exp[i]
      last = evaluate(exp[i], lenv, function_definitions)
      i = i + 1
    end
    last
  when "const_ref"
    eval(exp[1])
  when "var_ref"
    lenv[exp[1]]
  when "var_assign"
    lenv[exp[1]] = evaluate(exp[2], lenv, function_definitions)
  when "if"
    if evaluate(exp[1], lenv, function_definitions)
      evaluate(exp[2], lenv, function_definitions)
    else
      evaluate(exp[3], lenv, function_definitions)
    end
  when "while"
    while evaluate(exp[1], lenv, function_definitions)
      evaluate(exp[2], lenv, function_definitions)
    end
  when "func_call"
    # Lookup the function definition by the given function name.
    func = function_definitions[exp[1]]

    # builtin
    if func == nil
      case exp[1]
      when "p"
        p(evaluate(exp[2], lenv, function_definitions))
      when "pp"
        pp(evaluate(exp[2], lenv, function_definitions))
      when "Integer"
        Integer(evaluate(exp[2], lenv, function_definitions))
      when "fizzbuzz"
        fizzbuzz(evaluate(exp[2], lenv, function_definitions))
      when "require"
        require(evaluate(exp[2], lenv, function_definitions))
      when "minruby_parse"
        minruby_parse(evaluate(exp[2], lenv, function_definitions))
      when "minruby_load"
        minruby_load()
      else
        puts exp[1]
        raise("unknown builtin function")
      end
    else
      # prepare args
      args = []
      i = 0
      while exp[i + 2]
        args[i] = evaluate(exp[i + 2], lenv, function_definitions)
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
      evaluate(func[1], new_env, function_definitions)
    end
  when "func_def"
    function_definitions[exp[1]] = [exp[2], exp[3]]
  when "ary_new"
    ary = []
    i = 0
    while exp[i + 1]
      ary[i] = evaluate(exp[i + 1], lenv, function_definitions)
      i = i + 1
    end
    ary
  when "ary_ref"
    ary = evaluate(exp[1], lenv, function_definitions)
    idx = evaluate(exp[2], lenv, function_definitions)
    ary[idx]
  when "ary_assign"
    ary = evaluate(exp[1], lenv, function_definitions)
    idx = evaluate(exp[2], lenv, function_definitions)
    val = evaluate(exp[3], lenv, function_definitions)
    ary[idx] = val
  when "hash_new"
    hsh = {}
    i = 0
    while exp[i + 1]
      key = evaluate(exp[i + 1], lenv, function_definitions)
      val = evaluate(exp[i + 2], lenv, function_definitions)
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

function_definitions = {}
lenv = {}

# `minruby_load()` == `File.read(ARGV.shift)`
# `minruby_parse(str)` parses a program text given, and returns its AST
load './optimizer.rb'

source = minruby_load()
ast = minruby_parse(source)
puts "Original AST"
pp ast
new_ast = optimize(ast)
puts "Optimized AST"
pp new_ast
evaluate(ast, lenv, function_definitions)
