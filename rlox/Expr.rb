class Expr
    class Visitor
        def visitBinaryExpr(expr) end
        def visitGroupingExpr(expr) end
        def visitLiteralExpr(expr) end
        def visitUnaryExpr(expr) end
    end
  class Binary < Expr
     attr_reader :left, :operator, :right

    def initialize(left, operator, right)
      @left = left
      @operator = operator
      @right = right
    end

    def accept(visitor)
      visitor.visitBinaryExpr(self)
    end
  end
  class Grouping < Expr
     attr_reader :expression

    def initialize(expression)
      @expression = expression
    end

    def accept(visitor)
      visitor.visitGroupingExpr(self)
    end
  end
  class Literal < Expr
     attr_reader :value

    def initialize(value)
      @value = value
    end

    def accept(visitor)
      visitor.visitLiteralExpr(self)
    end
  end
  class Unary < Expr
     attr_reader :operator, :right

    def initialize(operator, right)
      @operator = operator
      @right = right
    end

    def accept(visitor)
      visitor.visitUnaryExpr(self)
    end
  end
end
