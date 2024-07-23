module Expr
    class Visitor
        def visitAssignExpr(expr) end
        def visitBinaryExpr(expr) end
        def visitCallExpr(expr) end
        def visitGetExpr(expr) end
        def visitGroupingExpr(expr) end
        def visitLiteralExpr(expr) end
        def visitLogicalExpr(expr) end
        def visitSetExpr(expr) end
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
  class Call
     include Expr

     attr_reader :callee, :paren, :arguments

    def initialize(callee, paren, arguments)
      @callee = callee
      @paren = paren
      @arguments = arguments
    end

    def accept(visitor)
      visitor.visitCallExpr(self)
    end
  end
  class Get
     include Expr

     attr_reader :object, :name

    def initialize(object, name)
      @object = object
      @name = name
    end

    def accept(visitor)
      visitor.visitGetExpr(self)
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
  class Logical
     include Expr

     attr_reader :left, :operator, :right

    def initialize(left, operator, right)
      @left = left
      @operator = operator
      @right = right
    end

    def accept(visitor)
      visitor.visitLogicalExpr(self)
    end
  end
  class Set
     include Expr

     attr_reader :object, :name, :value

    def initialize(object, name, value)
      @object = object
      @name = name
      @value = value
    end

    def accept(visitor)
      visitor.visitSetExpr(self)
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
