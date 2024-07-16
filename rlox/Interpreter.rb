require_relative 'Expr.rb'
require_relative 'Stmt.rb'
require_relative 'TokenType.rb'
require_relative 'RunTimeError.rb'
require_relative 'Environment.rb'


# Класс интерпретатора. Он реализует интерфейс Visitor, который определяет методы
# для посещения различных типов выражений.
class Interpreter
    include Stmt
    include Expr

    @@Environment = Environment.new()

    def self.Environment
        return @@Environment
    end

    private_class_method :Environment

    # Инициализация интерпретатора. 
    # Аргумент lox - объект класса Lox, который содержит метод для обработки ошибок.
    def initialize(lox)
        @lox = lox
    end

    # Метод interpret выполняет интерпретацию выражения.
    # 
    # Аргумент statements - массив объектов класса Stmt, представляющих
    # выражения.
    # 
    # Метод iterate по очереди вызывает метод execute для каждого выражения.
    # 
    # Если во время выполнения выражения возникает ошибка, метод runtimeError класса Lox вызывается.
    def interpret(statements)
        # Попытка выполнить каждое выражение в массиве statements.
        begin
            # Данный блок будет выполняться для каждого выражения в массиве statements.
            statements.each do |statement| 
                # Выполнить выражение statement.
                self.execute(statement)
            end
        # Если во время выполнения выражения возникла ошибка типа RunTimeError,
        # то выполнить следующий блок кода.
        rescue RunTimeError => error
            # Вызвать метод runtimeError класса Lox с объектом ошибки error.
            # Этот метод будет обработать ошибку во время выполнения.
            @lox.runtimeError(error)
        end
    end

     # Метод visitAssignExpr принимает объект класса Expr::Assign и выполняет его, присваивая значение переменной.
     def visitAssignExpr(expr) 
        # Вычисление значения выражения
        value = self.evaluate(expr.value)
        # Присвоение значения переменной
        @@Environment.assign(expr.name, value)
        return value
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

    # Метод visitGroupingExpr принимает объект класса Expr::Grouping и вызывает evaluate для его выражения.
    def visitGroupingExpr(expr)
        return self.evaluate(expr.expression)
    end

    # Метод visitLiteralExpr принимает объект класса Expr::Literal и возвращает его значение.
    def visitLiteralExpr(expr)
        return expr.value;
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

    def visitVariableExpr(expr)
        return @@Environment.get(expr.name)
    end

# Метод visitExpressionStmt принимает объект класса Stmt::Expression и выполняет его выражение.
    def visitExpressionStmt(stmt)
        # Выполнение выражения
        self.evaluate(stmt.expression)
        return nil
    end

    # Метод visitBlockStmt принимает объект класса Stmt::Block и выполняет его, создавая
    # новую среду исполнения, в которой выполняются выражения блока.
    def visitBlockStmt(stmt)
        # Создание новой среды исполнения, в которой выполняются выражения блока.
        # Область видимости новой среды исполнения - текущая среда исполнения.
        # Это означает, что внутри блока можно обращаться к переменным текущей среды исполнения.
        newEnv = Environment.new(@@Environment)
        
        # Выполнение выражений блока в новой среде исполнения
        self.executeBlock(stmt.statements, newEnv)
        
        # Возврат nil, так как блок не возвращает значение
        return nil
    end

    # Метод visitPrintStmt принимает объект класса Stmt::Print и выполняет его, выводя результат на стандартный вывод.
    def visitPrintStmt(stmt)
        # Вычисление значения выражения
        value = self.evaluate(stmt.expression)
        # Печать значения на стандартный вывод
        $stdout << self.stringify(value) << "\n"
        return nil
    end

    # Метод visitVarStmt принимает объект класса Stmt::Var и выполняет его, определяя переменную в среде исполнения.
    def visitVarStmt(stmt)
        # Инициализация значения переменной
        value = nil
        if stmt.initializer != nil then
            value = self.evaluate(stmt.initializer)
        end

        # Определение переменной в текущей среде исполнения
        @@Environment.define(stmt.name.lexeme, value)
        return nil
    end

    # выполняет список операторов в контексте заданной среды
    def executeBlock(statements, environment)
        previous = @@Environment
        begin
            @@Environment = environment

            statements.each do |statement|
                self.execute(statement)
            end    
        ensure
            @@Environment = previous
        end
    end

    private

    # Метод evaluate вызывает visit для выражения и возвращает результат.
    def evaluate(expr)
        return expr.accept(self)
    end

    def execute(stmt)
        stmt.accept(self)
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





