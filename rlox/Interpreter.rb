require_relative 'Expr.rb'
require_relative 'TokenType.rb'
require_relative 'RunTimeError.rb'


# Класс интерпретатора. Он реализует интерфейс Visitor, который определяет методы
# для посещения различных типов выражений.
class Interpreter < Expr::Visitor

    # Инициализация интерпретатора. 
    # Аргумент lox - объект класса Lox, который содержит метод для обработки ошибок.
    def initialize(lox)
        @lox = lox
    end

    # Исполнение выражения. 
    # Аргумент expression - объект класса Expr, представляющий выражение.
    # Метод evaluate вызывает visit для выражения и возвращает результат.
    # Если во время выполнения выражения возникает ошибка, метод RunTimeError класса Lox вызывается.
    def interpret(expression)
        begin
            value = evaluate(expression)
            $stdout << self.stringify(value) << "\n"
        rescue RunTimeError => error
            @lox.runtimeError(error)
        end
    end

    # Метод visitLiteralExpr принимает объект класса Expr::Literal и возвращает его значение.
    def visitLiteralExpr(expr)
        return expr.value;
    end

    # Метод visitGroupingExpr принимает объект класса Expr::Grouping и вызывает evaluate для его выражения.
    def visitGroupingExpr(expr)
        return self.evaluate(expr.expression)
    end

    # Метод visitUnaryExpr принимает объект класса Expr::Unary и выполняет его.
    def visitUnaryExpr(expr)
        right = self.evaluate(expr.right)

        case expr.operator.type
            when TokenType::MINUS then 
                self.checkNumberOperand(expr.operator, right)
                return -(right.to_f)
            when TokenType::BANG then return !self.isTruthy(right)
        end

        return nil
    end

    # Метод visitBinaryExpr принимает объект класса Expr::Binary и выполняет его.
    def visitBinaryExpr(expr)
        left = evaluate(expr.left)
        right = evaluate(expr.right)

        case expr.operator.type
            when TokenType::GREATER then 
                self.checkNumberOperands(expr.operator, left, right)
                return left.to_f > right.to_f
            when TokenType::GREATER_EQUAL then 
                self.checkNumberOperands(expr.operator, left, right)
                return left.to_f >= right.to_f
            when TokenType::LESS then 
                self.checkNumberOperands(expr.operator, left, right)
                return left.to_f < right.to_f
            when TokenType::LESS_EQUAL then 
                self.checkNumberOperands(expr.operator, left, right)
                return left.to_f <= right.to_f
            when TokenType::BANG_EQUAL then return !self.isEqual(left, right)
            when TokenType::EQUAL_EQUAL then return self.isEqual(left, right)
            when TokenType::MINUS then 
                self.checkNumberOperands(expr.operator, left, right)
                return left.to_f - right.to_f
            when TokenType::PLUS then 
                if left.is_a?(Float) && right.is_a?(Float) then return left.to_f + right.to_f end
                if left.is_a?(String) && right.is_a?(String) then return left.to_s + right.to_s end
                raise RunTimeError.new(expr.operator, "Operands must be two numbers or two strings.")
            when TokenType::SLASH then 
                self.checkNumberOperands(expr.operator, left, right)
                return left.to_f / right.to_f
            when TokenType::STAR then 
                self.checkNumberOperands(expr.operator, left, right)
                return left.to_f * right.to_f
        end
    end

    private

    # Метод evaluate вызывает visit для выражения и возвращает результат.
    def evaluate(expr)
        return expr.accept(self)
    end

    # Метод isTruthy проверяет, является ли объект истинным или ложным значением.
    def isTruthy(object)
        if object == nil then return false end
        if object.is_a?(Bool) then return object end
        return true
    end

    # Метод isEqual проверяет, равны ли два объекта.
    def isEqual(a, b)
        if a == nil && b == nil then return true end
        if a == nil then return false end

        return a == b
    end

    # Метод stringify возвращает строковое представление объекта.
    def stringify(object)
        if object == nil then return "nil" end
        
        if object.is_a?(Float) then
            text = object.to_s
            if text.end_with?(".0") then 
                text = text.slice(0, text.length - 2)
            end
            return text
        end
        return object.to_s
    end

    # Метод checkNumberOperand проверяет, является ли операнд числом.
    def checkNumberOperand(operator, operand)
        if operand.is_a?(Float) then return end
        raise RunTimeError.new(operator, "Operand must be a number.")
    end

    # Метод checkNumberOperands проверяет, являются ли операнды числами.
    def checkNumberOperands(operator, left, right)
        if left.is_a?(Float) && right.is_a?(Float) then return end
        raise RunTimeError.new(operator, "Operand must be a number.")
    end
end



