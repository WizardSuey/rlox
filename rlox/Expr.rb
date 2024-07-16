module Expr
    class Visitor
        def visitAssignExpr(expr) end
        def visitBinaryExpr(expr) end
        def visitGroupingExpr(expr) end
        def visitLiteralExpr(expr) end
        def visitUnaryExpr(expr) end
        def visitVariableExpr(expr) end
    end
  class Assign
     include Expr

     attr_reader :name, :value

    def initialize(name, value)
      @name = name
      @value = value
    end

    def accept(visitor)
      visitor.visitAssignExpr(self)
    end
  end
  class Binary
     include Expr

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
  class Grouping
     include Expr

     attr_reader :expression

    def initialize(expression)
      @expression = expression
    end

    def accept(visitor)
      visitor.visitGroupingExpr(self)
    end
  end
  class Literal
     include Expr

     attr_reader :value

    def initialize(value)
      @value = value
    end

    def accept(visitor)
      visitor.visitLiteralExpr(self)
    end
  end
  class Unary
     include Expr

     attr_reader :operator, :right

    def initialize(operator, right)
      @operator = operator
      @right = right
    end

    def accept(visitor)
      visitor.visitUnaryExpr(self)
    end
  end
  class Variable
     include Expr

     attr_reader :name

    def initialize(name)
      @name = name
    end

    def accept(visitor)
      visitor.visitVariableExpr(self)
    end
  end
end
