module Stmt
    class Visitor
        def visitBlockStmt(stmt) end
        def visitExpressionStmt(stmt) end
        def visitPrintStmt(stmt) end
        def visitVarStmt(stmt) end
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
end
