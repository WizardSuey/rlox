require_relative 'Expr.rb'
require_relative 'Stmt.rb'
require_relative 'TokenType.rb'
require_relative 'RunTimeError.rb'
require_relative 'Environment.rb'
require_relative 'LoxCallable.rb'
require_relative 'LoxFunction.rb'
require_relative 'Return.rb'
require_relative 'Resolver.rb'
require_relative 'LoxClass.rb'


# Класс интерпретатора. Он реализует интерфейс Visitor, который определяет методы
# для посещения различных типов выражений.
class Interpreter
    include Stmt
    include Expr
    include ReturnModule

    attr_reader :globals    # Глобальное окружение.
    attr_reader :Locals

    # Инициализация интерпретатора. 
    # Аргумент lox - объект класса Lox, который содержит метод для обработки ошибок.
    def initialize(lox)
        @lox = lox
        @Locals = Hash.new()
        @globals = Environment.new()
        @@Environment = @globals  # Текущее окружение.
        
        # 
        @globals.define("clock", Class.new(LoxCallable) do
            # Метод clock возвращает текущее время в секундах.
            def arity()
                return 0 
            end

            def call(interpreter, arguments)
                return Time.now.to_f * 1000
            end

            def self.to_s()
                return "<native fn>"
            end
        end)
    end

    def self.Environment
        return @@Environment
    end
    private_class_method :Environment

    def self.Locals
        return @Locals
    end
    private_class_method :Locals
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
        
        # мы ищем расстояние области действия переменной. 
        # Если он не найден, мы предполагаем, что он глобальный, 
        # и обрабатываем его так же, как и раньше. 
        # В противном случае мы вызываем assignAt
        distance = @Locals.key?(expr) ? @Locals.fetch(expr) : nil

        if distance != nil then
            @@Environment.assignAt(distance, expr.name, value)
            # puts "set local var: #{expr.name.lexeme} = #{value}"
        else
            @globals.assign(expr.name, value)
            # puts "set global var: #{expr.name.lexeme} = #{value}"
        end

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

    # Вычисляет выражение вызова, оценивая вызываемого объекта и аргументы и вызывая результирующую функцию с интерпретатором и аргументами.
    def visitCallExpr(expr)
        # Оцениваем вызываемый объект (может быть функция или класс).
        callee = self.evaluate(expr.callee)
        begin   
            # Если это встроенная функция, то создаем ее экземпляр.
            # Добавлено для того, чтобы функции, которые вызываются через интерпретатор,
            # также работали.
            instance = callee.new()
            if callee.ancestors.include?(LoxCallable) then
                callee = instance
            end
        rescue
        ensure
            # Оцениваем аргументы.
            arguments = Array.new()
            expr.arguments.each do |argument|
                arguments << self.evaluate(argument)
            end

            # Проверяем, является ли выражение вызываемым объектом.
            unless callee.is_a?(LoxCallable) then
                raise RunTimeError.new(expr.paren, "Can only call functions and classes.")
            end

            function = callee

            # Проверяем количество аргументов.
            unless arguments.length == function.arity() then
                raise RunTimeError.new(expr.paren, "Expected #{function.arity()} arguments, but got #{arguments.length}.")
            end

            # Вызываем функцию с интерпретатором и аргументами.
            return function.call(self, arguments)
        end
    end

    # Для вызова метода через точку
    def visitGetExpr(expr)
        object = self.evaluate(expr.object)
        if object.is_a?(LoxInstance) then
            return object.get(expr.name)
        end

        raise RunTimeError.new(expr.name, "Only instances have properties.")
    end

    # Метод visitGroupingExpr принимает объект класса Expr::Grouping и вызывает evaluate для его выражения.
    def visitGroupingExpr(expr)
        return self.evaluate(expr.expression)
    end

    # Метод visitLiteralExpr принимает объект класса Expr::Literal и возвращает его значение.
    def visitLiteralExpr(expr)
        return expr.value;
    end

    # Метод visitLogicalExpr принимает объект класса Expr::Logical и выполняет его.
    def visitLogicalExpr(expr)
        left = self.evaluate(expr.left)

        if expr.operator.type == TokenType::OR then
            if self.isTruthy(left) then return left end
        else
            if !self.isTruthy(left) then return left end
        end

        return self.evaluate(expr.right)
    end

    def visitSetExpr(expr)
        object = self.evaluate(expr.object)
        # Мы оцениваем объект, свойство которого устанавливается, 
        # и проверяем, является ли он LoxInstance. 
        # Если нет, то это ошибка времени выполнения. 
       
        if !object.is_a?(LoxInstance) then
            raise RunTimeError.new(expr.name, "Only instances have fields.")
        end
        # В противном случае мы оцениваем устанавливаемое значение и сохраняем его в экземпляре.
        value = self.evaluate(expr.value)
        object.set(expr.name, value)
        return value
    end

    def visitSuperExpr(expr)
        distance = @Locals.fetch(expr)
        superclass = @@Environment.getAt(distance, "super")
        object = @@Environment.getAt(distance - 1, "this")

        method = superclass.findMethod(expr.method.lexeme)

        if method == nil then
            raise RunTimeError.new(expr.method, "Undefined property '#{expr.method.lexeme}'.")
        end
        return method.bind(object)
    end

    def visitThisExpr(expr)
        return self.lookUpVariable(expr.keyword, expr)
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

    # Метод, который принимает Expr::Variable и передаёт методу lookUpVariable его имя.
    def visitVariableExpr(expr)
        return self.lookUpVariable(expr.name, expr)
    end

    # Метод для посещения выражения переменной и поиска переменной в среде.
    def lookUpVariable(name, expr)
        # Сначала мы ищем разрешенное расстояние на хэше 
        distance = @Locals.key?(expr) ? @Locals.fetch(expr) : nil
        if distance != nil then
            return @@Environment.getAt(distance, name.lexeme)
        # если мы не находим расстояние на карте, оно должно быть глобальным. 
        # В этом случае мы ищем его динамически, непосредственно в глобальной среде
        else
            return @globals.get(name)
        end
    end

    # Метод visitExpressionStmt принимает объект класса Stmt::Expression и выполняет его выражение.
    def visitExpressionStmt(stmt)
        # Выполнение выражения
        self.evaluate(stmt.expression)
        return nil
    end

    # Выполняет оператор функции, создавая новую LoxFunction на основе предоставленного оператора, 
    # определяет ее в среде и возвращает ноль.
    def visitFunctionStmt(stmt)
        function = LoxFunction.new(stmt, self, @@Environment, false)
        @@Environment.define(stmt.name.lexeme, function)
        return nil
    end

    # Метод visitIfStmt принимает объект класса Stmt::If и выполняет его.
    def visitIfStmt(stmt)
        if self.isTruthy(self.evaluate(stmt.condition)) then
            self.execute(stmt.thenBranch)
        elsif stmt.elseBranch != nil then
            self.execute(stmt.elseBranch)
        end
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

    # Метод visitClassStmt принимает объект класса Stmt::Class и создает новый класс,
    # определяет его в текущей среде исполнения и присваивает его в данное пространство имен.
    # После этого метод возвращает ноль.
    def visitClass_defStmt(stmt)
        superclass = nil
        if stmt.superclass != nil then
            superclass = self.evaluate(stmt.superclass)
            if !superclass.is_a?(LoxClass) then
                raise RunTimeError.new(stmt.superclass.name, "Superclass must be a class.")
            end
        end
        # Определение класса в текущей среде исполнения
        @@Environment.define(stmt.name.lexeme, nil)

        if stmt.superclass != nil then
            @@Environment = Environment.new(@@Environment)
            @@Environment.define("super", superclass)
        end

        methods = Hash.new()
        stmt.methods.each do |method|
            function = LoxFunction.new(method, self, @@Environment, method.name.lexeme.eql?("init"))
            methods.store(method.name.lexeme, function)
        end

        # Создание объекта класса
        klass = LoxClass.new(stmt.name.lexeme, superclass, methods)

        if superclass != nil then 
            @@Environment = @@Environment.Enclosing
        end
        
        # Определение класса в текущем пространстве имен
        @@Environment.assign(stmt.name, klass)
        
        # Возврат nil, так как класс не возвращает значение
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

    def visitReturnStmt(stmt)
        # Если у нас есть возвращаемое значение, мы оцениваем его, 
        # в противном случае мы используем nil. 
        # Затем мы берем это значение, помещаем его в собственный класс исключений и выбрасываем его.
        value = nil
        if stmt.value != nil then value = self.evaluate(stmt.value) end

        raise ReturnModule::Return.new(value)
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
        # puts "Defined variable: #{stmt.name.lexeme} = #{value.to_s}"
        return nil
    end

    # Метод для обращения к оператору For, выполнения его инициализатора, за которым следует цикл, 
    # который оценивает условие, выполняет тело и увеличивает (если присутствует) до тех пор,
    #  пока условие не станет ложным.
    def visitForStmt(stmt)  
        if stmt.initializer != nil then
            self.execute(stmt.initializer)
        end

        while self.isTruthy(self.evaluate(stmt.condition)) do
            self.execute(stmt.body)
            if stmt.increment != nil then
                self.execute(stmt.increment)
            end
        end

        return nil
    end

    # Метод visitWhileStmt принимает объект класса Stmt::While и выполняет его.
    def visitWhileStmt(stmt)
        while self.isTruthy(self.evaluate(stmt.condition)) do 
            self.execute(stmt.body)
        end
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

    # Кааждый раз, когда Resolver посещает переменную, он сообщает интерпретатору, 
    # сколько областей существует между текущей областью и областью, в которой определена переменная. 
    # Во время выполнения это точно соответствует количеству сред между текущим и окружающим, 
    # в которых интерпретатор может найти значение переменной. 
    # Resolver передает это число интерпретатору, вызывая это:
    def resolve(expr, depth)
        @Locals.store(expr, depth)
        # puts "locals: #{@Locals}"
    end

    private

    # Метод evaluate вызывает visit для выражения и возвращает результат.
    def evaluate(expr)
        return expr.accept(self)
    end

    # Метод execute вызывает visit для утверждения и возвращает результат.
    def execute(stmt)
        return stmt.accept(self)
    end

    # Метод isTruthy проверяет, является ли объект истинным или ложным значением.
    def isTruthy(object)
        return false if object.nil?
        return object if object.is_a?(TrueClass) || object.is_a?(FalseClass)
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


