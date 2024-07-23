
# Модуль для решения типов и проверки доступа к переменным.
# Используется в процессе анализа AST-дерева для определения типов и проверки доступа к переменным.
class Resolver
    include Stmt
    include Expr

    # Типы функций
    module FunctionType
        # Нет функции
        NONE = :NONE
        # Функция
        FUNCTION = :FUNCTION
    end

    # Внутренние переменные
    attr_reader :Interpreter, :Scopes

    # Метод для получения интерпретатора (метод Singleton)
    def self.Interpreter()
        return @Interpreter
    end
    private_class_method :Interpreter

    # Метод для получения локальных областей видимости (метод Singleton)
    def self.Scopes()
        return @Scopes
    end
    private_class_method :Scopes

    def self.CurrentFunction()
        return @CurrentFunction
    end
    private_class_method :CurrentFunction

    # Конструктор
    def initialize(interpreter, lox)
        # Массив для хранения областей видимости.
        # Каждый элемент - это хеш, где ключи - имена переменных,
        # а значения - это булевы, которые указывают, определена ли переменная.
        @Scopes = Array.new()
        @Interpreter = interpreter
        @lox = lox
        @CurrentFunction = FunctionType::NONE
    end

    # Метод для посещения блока
    def visitVarStmt(stmt)
        # Объявить переменную
        self.declare(stmt.name)

        # Если переменная инициализируется, то разрешить ее инициализатор
        if stmt.initializer != nil then
            self.resolve(stmt.initializer)
        end

        # Определить переменную
        self.define(stmt.name)
        return nil
    end

    def visitForStmt(stmt)
        # Начать новую область видимости
        self.beginScope()

        # Разрешить инициализатор
        if stmt.initializer != nil
            self.resolve(stmt.initializer)
        end

        # Разрешить условие
        self.resolve(stmt.condition)

        # Разрешить тело
        self.resolve(stmt.body)

        self.resolve(stmt.increment)

        # Закончить область видимости
        self.endScope()

        # Вернуть nil, так как блок не возвращает значение
        return nil
    end


    # Метод для посещения блока while
    def visitWhileStmt(stmt)
        # Разрешить условие
        self.resolve(stmt.condition)

        # Разрешить тело
        self.resolve(stmt.body)
        return nil
    end

    # Метод для посещения присваивания
    def visitAssignExpr(expr)
        # Разрешить правую часть
        self.resolve(expr.value)
        
        # Разрешить левую часть
        self.resolveLocal(expr, expr.name)
        return nil
    end

    # Метод для посещения бинарного выражения
    def visitBinaryExpr(expr)
        # Разрешить левую часть
        self.resolve(expr.left)

        # Разрешить правую часть
        self.resolve(expr.right)
        return nil
    end

    # Метод для посещения вызова
    def visitCallExpr(expr)
        # Разрешить вызываемый объект
        self.resolve(expr.callee)

        # Разрешить аргументы
        expr.arguments.each do |argument|
            self.resolve(argument)
        end
        return nil
    end

    # Для вызова метода через точку
    def visitGetExpr(expr)
        self.resolve(expr.object)
        return nil
    end

    # Метод для посещения группировки
    def visitGroupingExpr(expr)
        # Разрешить внутреннее выражение
        self.resolve(expr.expression)
        return nil
    end

    # Метод для посещения литерала
    def visitLiteralExpr(expr)
        # Ничего не делать, так как литералы не требуют разрешения
        return nil
    end

    # Метод для посещения логического выражения
    def visitLogicalExpr(expr)
        # Разрешить левую часть
        self.resolve(expr.left)

        # Разрешить правую часть
        self.resolve(expr.right)
        return nil
    end

    # Метод для посещения присваивания
    def visitSetExpr(expr)
        self.resolve(expr.value)
        self.resolve(expr.object)
        return nil
    end

    # Метод для посещения унарного выражения
    def visitUnaryExpr(expr)
        # Разрешить правую часть
        self.resolve(expr.right)
        return nil
    end

    # Метод для посещения переменной
    def visitVariableExpr(expr)
        # Сначала мы проверяем, осуществляется ли доступ к переменной внутри ее собственного инициализатора.
        # Если переменная существует в текущей области видимости, 
        # но ее значение ложно, это означает, что мы ее объявили, 
        # но еще не определили. Мы сообщаем об этой ошибке.
        if !@Scopes.empty? && @Scopes.last.key?(expr.name.lexeme) && @Scopes.last.fetch(expr.name.lexeme) == false then
            @lox.error(expr.name, "Can't read local variable in it's own initializer.")
        end

        # После проверки мы разрешаем использовать данную переменную в текущей области видимости.
        self.resolveLocal(expr, expr.name)
        return nil
    end

    # Метод для посещения блока
    def visitBlockStmt(stmt)
        # Начать новую область видимости
        self.beginScope()

        # Разрешить все выражения в блоке
       
        self.resolve(stmt.statements)
        

        # Завершить область видимости
        self.endScope()

        # Вернуть nil, так как блок не возвращает значение
        return nil
    end

    # Метод для посещения класса
    def visitClass_defStmt(stmt)
        self.declare(stmt.name)
        self.define(stmt.name)
        return nil
    end

    # Метод для посещения выражения
    def visitExpressionStmt(stmt)
        # Разрешить выражение
        self.resolve(stmt.expression)
        return nil
    end

    # Метод для посещения функции
    def visitFunctionStmt(stmt)
        # Объявить функцию
        self.declare(stmt.name)

        # Определить функцию
        self.define(stmt.name)
        
        # Разрешить функцию
        self.resolveFunction(stmt, FunctionType::FUNCTION)

        return nil
    end

    # Метод для посещения цикла if
    def visitIfStmt(stmt)
        # Разрешить условие
        self.resolve(stmt.condition)

        # Разрешить ветвь then
        self.resolve(stmt.thenBranch)

        # Разрешить ветвь else, если она присутствует
        if stmt.elseBranch != nil then
            self.resolve(stmt.elseBranch)
        end
        return nil
    end

    # Метод для посещения печати
    def visitPrintStmt(stmt)
        # Разрешить выражение
        self.resolve(stmt.expression)
        return nil
    end

    # Метод для посещения оператора возврата
    def visitReturnStmt(stmt)
        if @CurrentFunction == FunctionType::NONE then
            @lox.error(stmt.keyword, "Can't return from top-level code.")
        end

        # Разрешить выражение, если оно присутствует
        if stmt.value != nil then self.resolve(stmt.value) end
        return nil
    end

    # Метод для разбора AST
    # @param ast [Array(Stmt | Expr) | Stmt | Expr]
    # @return [void]
    def resolve(ast)
        if ast.is_a?(Array) then
            # Если AST - это массив, то обойтись по очереди по каждому элементу
            ast.each { |statement| self.resolve(statement) }
        # Если AST - это выражение, то вызвать метод accept() для него и передать себя в качестве посетителя
        elsif ast.is_a?(Stmt) then
            ast.accept(self)
        # Если AST - это выражение, то вызвать метод accept() для него и передать себя в качестве посетителя
        elsif ast.is_a?(Expr) then
            ast.accept(self)
        end
    end


    # Метод для разрешения функции
    def resolveFunction(function, type)
        enclosingFunction = @CurrentFunction
        @CurrentFunction = type
        # Начать новую область видимости
        self.beginScope()

        # Объявить параметры
        function.params.each do |param|
            self.declare(param)
            self.define(param)
        end

        self.resolve(function.body.statements)

        # Завершить область видимости
        self.endScope()

        # Разрешить тело
        # self.resolve(function.body)
    end

    # Приватные методы
    private

    # Метод для начала новой области видимости
    def beginScope()
        # Добавить новую пустую область видимости в стек
        @Scopes.push(Hash.new())
    end

    # Метод для окончания области видимости
    def endScope()
        # Удалить последнюю (самую новую) область видимости с стека
        @Scopes.pop()
    end

    # Метод для объявления переменной
    def declare(name)
        if @Scopes.empty? then
            return
        end

        scope = @Scopes.last
        if scope.has_key?(name.lexeme) then
            @lox.error(name, "Already a variable with this name in this scope.")
        end
        scope.store(name.lexeme, false)
    end

    # Метод для определения переменной
    def define(name)
        if @Scopes.empty? then
            return
        end
        @Scopes.last[name.lexeme] = true
    end

    # Метод для поиска переменной в стеке областей видимости
    # Мы начинаем с самой внутренней области и работаем дальше, ища на каждой карте подходящее имя. Е
    # сли мы находим переменную, мы разрешаем ее, 
    # передавая количество областей между текущей внутренней областью и областью, в которой переменная была инициализирона. 
    # Если переменная была найдена в текущей области, мы передаем 0. Если она находится в непосредственно охватывающей области, 1.
    def resolveLocal(expr, name)
        (@Scopes.size - 1).downto(0) do |i|
          if @Scopes[i].has_key?(name.lexeme)
            @Interpreter.resolve(expr, @Scopes.size - 1 - i)
            return
          end
        end
    end
    
end


