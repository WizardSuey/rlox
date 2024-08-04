require_relative 'Expr.rb'
require_relative 'Token.rb'
require_relative 'TokenType.rb'

# Класс для печати AST-дерева в виде строки
class AstPrinter
    """ 
    Метод print принимает на вход выражение и печатает его в виде строки,
    рекурсивно вызывая соответствующие методы.
    """

    def print(expr)
        return expr.accept(self)
    end

    def visitBinaryExpr(expr)
        """ 
        Метод visitBinaryExpr печатает бинарное выражение, окружая его 
        скобками.
        """
        return self.parenthesize(expr.operator.lexeme, expr.left, expr.right)
    end

    def visitGroupingExpr(expr)
        """ 
        Метод visitGroupingExpr печатает группировку, окружая ее скобками.
        """
        return self.parenthesize("group", expr.expression)
    end

    def visitLiteralExpr(expr)
        """ 
        Метод visitLiteralExpr печатает литеральное выражение, если оно 
        nil, то печатает nil.
        """
        if expr.value == nil then return "nil" end
        return expr.value.to_s
    end

    def visitUnaryExpr(expr)
        """ 
        Метод visitUnaryExpr печатает унарное выражение, окружая его 
        скобками.
        """
        return self.parenthesize(expr.operator.lexeme, expr.right)
    end

    def parenthesize(name, *exprs)
        """ 
        Метод parenthesize формирует строку, окружающую выражения 
        скобками.
        """
        builder = "(#{name}"
        exprs.each do |expr|
            builder << " "
            builder << expr.accept(self)
        end
        builder << ")"

        return builder.to_s
    end
    private :parenthesize
end

# def main()
#     """ 
#     Создание примерного выражения.
#     """

#     expression = Expr::Binary.new(Expr::Literal.new(2.0), Token.new(TokenType::PLUS, "+", nil, 1), Expr::Binary.new(Expr::Literal.new(2.0), Token.new(TokenType::STAR, "*", nil, 1), Expr::Literal.new(2.0)))

#     """ 
#     Печать выражения в виде строки.
#     """
#     $stdout << AstPrinter.new.print(expression) << "\n"
# end

# main()

