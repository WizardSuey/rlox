module Stmt
    class Visitor
        def visitBlockStmt(stmt) end
        def visitClass_defStmt(stmt) end
        def visitExpressionStmt(stmt) end
        def visitFunctionStmt(stmt) end
        def visitIfStmt(stmt) end
        def visitPrintStmt(stmt) end
        def visitReturnStmt(stmt) end
        def visitVarStmt(stmt) end
        def visitForStmt(stmt) end
        def visitWhileStmt(stmt) end
    end
  class Block
     include Stmt

     attr_reader :statements

    def initialize(statements)
      @statements = statements
    end

    def accept(visitor)
      visitor.visitBlockStmt(self)
    end
  end
  class Class_def
     include Stmt

     attr_reader :name, :superclass, :methods

    def initialize(name, superclass, methods)
      @name = name
      @superclass = superclass
      @methods = methods
    end

    def accept(visitor)
      visitor.visitClass_defStmt(self)
    end
  end
  class Expression
     include Stmt

     attr_reader :expression

    def initialize(expression)
      @expression = expression
    end

    def accept(visitor)
      visitor.visitExpressionStmt(self)
    end
  end
  class Function
     include Stmt

     attr_reader :name, :params, :body

    def initialize(name, params, body)
      @name = name
      @params = params
      @body = body
    end

    def accept(visitor)
      visitor.visitFunctionStmt(self)
    end
  end
  class If
     include Stmt

     attr_reader :condition, :thenBranch, :elseBranch

    def initialize(condition, thenBranch, elseBranch)
      @condition = condition
      @thenBranch = thenBranch
      @elseBranch = elseBranch
    end

    def accept(visitor)
      visitor.visitIfStmt(self)
    end
  end
  class Print
     include Stmt

     attr_reader :expression

    def initialize(expression)
      @expression = expression
    end

    def accept(visitor)
      visitor.visitPrintStmt(self)
    end
  end
  class Return
     include Stmt

     attr_reader :keyword, :value

    def initialize(keyword, value)
      @keyword = keyword
      @value = value
    end

    def accept(visitor)
      visitor.visitReturnStmt(self)
    end
  end
  class Var
     include Stmt

     attr_reader :name, :initializer

    def initialize(name, initializer)
      @name = name
      @initializer = initializer
    end

    def accept(visitor)
      visitor.visitVarStmt(self)
    end
  end
  class For
     include Stmt

     attr_reader :initializer, :condition, :increment, :body

    def initialize(initializer, condition, increment, body)
      @initializer = initializer
      @condition = condition
      @increment = increment
      @body = body
    end

    def accept(visitor)
      visitor.visitForStmt(self)
    end
  end
  class While
     include Stmt

     attr_reader :condition, :body

    def initialize(condition, body)
      @condition = condition
      @body = body
    end

    def accept(visitor)
      visitor.visitWhileStmt(self)
    end
  end
end
