def optimize(ast)
  # space name => { ref => {}, assign => {}, value => {} }
  usage_space = {}
  prove(ast, usage_space)

  traverse(ast, usage_space)

  ast
end

def prove(ast, usage_space)
  return unless ast.is_a? Array
  # p ast
  op, *tail = ast

  space_name = op == "func_def" ? tail.first : "main"
  usage_space[space_name] ||= { ref: {}, assign: {}, value: {} }

  if op == "var_assign"
    usage_space[space_name][:assign][tail.first] ||= 0
    usage_space[space_name][:assign][tail.first] += 1
    usage_space[space_name][:value][tail.first] = tail.last
  end

  if op == "var_ref"
    usage_space[space_name][:ref][tail.first] ||= 0
    usage_space[space_name][:ref][tail.first] += 1
  end

  tail.each do |c_ast|
    prove(c_ast, usage_space)
  end
end

def traverse(ast, usage_space)
  return unless ast.is_a? Array
  op, *tail = ast

  space_name = op == "func_def" ? tail.first : "main"

  tail.each do |c_ast|
    traverse(c_ast, usage_space)
  end

  arithmetic(ast, usage_space, space_name)
  if op == "stmts"
    remove_lit(ast)
    remove_unused_assign(ast, usage_space, space_name)
  end
end

def remove_unused_assign(ast, usage_space, space_name)
  i = ast.size - 2
  while i > 0
    if ast[i].first == 'var_assign'
      if usage_space[space_name][:ref][ast[i][1]].nil? || usage_space[space_name][:ref][ast[i][1]] == 0
        ast.delete_at(i)
      end
    end
    i -= 1
  end
end

def remove_lit(ast)
  i = ast.size - 2
  while i > 0
    if ast[i].first == 'lit'
      ast.delete_at(i)
    end
    i -= 1
  end
end

def arithmetic(ast, usage_space, space_name)
  op, *tail = ast

  case op
  when "+", "-", "*", "/", "%"
    left, right = tail
    if left.first == 'lit' && right.first == 'lit'
      ast.pop(3)
      ast << 'lit'
      ast << left.last.send(op.to_sym, right.last)
    elsif left.first == 'var_ref' &&
          right.first == 'lit' &&
          usage_space[space_name][:assign][left.last] == 1 &&
          usage_space[space_name][:value][left.last].first == 'lit'
      usage_space[space_name][:ref][left.last] -= 1
      ast.pop(3)
      ast << 'lit'
      ast << usage_space[space_name][:value][left.last].last.send(op.to_sym, right.last)
    elsif right.first == 'var_ref' &&
          left.first == 'lit' &&
          usage_space[space_name][:assign][right.last] == 1 &&
          usage_space[space_name][:value][right.last].first == 'lit'
      usage_space[space_name][:ref][right.last] -= 1
      ast.pop(3)
      ast << 'lit'
      ast << left.last.send(op.to_sym, usage_space[space_name][:value][right.last].last)
    elsif right.first == 'var_ref' &&
          left.first == 'var_ref' &&
          usage_space[space_name][:assign][left.last] == 1 &&
          usage_space[space_name][:assign][right.last] == 1 &&
          usage_space[space_name][:value][left.last].first == 'lit'
          usage_space[space_name][:value][right.last].first == 'lit'
      usage_space[space_name][:ref][right.last] -= 1
      usage_space[space_name][:ref][left.last] -= 1
      ast.pop(3)
      ast << 'lit'
      ast << usage_space[space_name][:value][left.last].last.send(op.to_sym, usage_space[space_name][:value][right.last].last)
    end
  end
end
