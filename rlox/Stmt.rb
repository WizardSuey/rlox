module Stmt
    class Visitor
        def visitExpressionStmt(stmt) end
        def visitPrintStmt(stmt) end
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
end

