# Это модуль парсит язык программирования RLOX.
# Он определяет класс Parser, который отвечает за парсинг выражений.
require_relative 'TokenType.rb'
require_relative 'Token.rb'
require_relative 'Expr.rb'
require_relative 'Stmt.rb'
require_relative 'Environment.rb'


class Parser
    # Этот класс представляет ошибку при парсинге.
    class ParseError < RuntimeError
    end 

    # Токены, которые нужно парсить.
    attr_reader :tokens

    # Текущий индекс токена.
    @@current = 0

    # Инициализирует Parser с заданными токенами и Lox-экземпляром.
    def initialize(tokens, lox)
        @tokens = tokens
        @lox = lox
    end

    # Парсит токены и возвращает список выражений.
    def parse()
        # Парсер для выражений.
        statements = Array.new()
        # Парсим каждый токен до тех пор, пока не достигнем конца.
        while !self.isAtEnd?() do
            statements << self.declaration()
        end
        return statements
    end

    private 

    # Парсит выражение.
     def expression()
        return self.assignment()
    end

    def declaration()
        begin
            if self.match(TokenType::CLASS) then return self.classDeclaration() end
            if self.match(TokenType::FUN) then return self.function("function") end
            if self.match(TokenType::VAR) then return self.varDeclaration() end
            return self.statement()
        rescue ParseError => error
            self.synchronize()
            return nil
        end
    end

    def classDeclaration()
        name = self.consume(TokenType::IDENTIFIER, "Expect class name.")

        superclass = nil
        if self.match(TokenType::LESS) then
            self.consume(TokenType::IDENTIFIER, "Expect superclass name.")
            superclass = Expr::Variable.new(self.previous())
        end

        self.consume(TokenType::LEFT_BRACE, "Expect '{' before class body.")

        methods = Array.new()
        while (!self.check(TokenType::RIGHT_BRACE) && !self.isAtEnd?()) do
            methods << self.function("method")
        end

        self.consume(TokenType::RIGHT_BRACE, "Expect '}' after class body.")

        return Stmt::Class_def.new(name, superclass, methods)
    end

    # Анализирует утверждение.
    # Анализирует различные типы операторов в зависимости от типа токена.
    def statement()
        if self.match(TokenType::FOR) then return self.forStatement() end
        if self.match(TokenType::IF) then return self.ifStatement() end
        if self.match(TokenType::PRINT) then return self.printStatement() end
        if self.match(TokenType::RETURN) then return self.returnStatement() end
        if self.match(TokenType::WHILE) then return self.whileStatement() end 
        if self.match(TokenType::LEFT_BRACE) then return self.block() end

        return self.expressionStatement()
    end

    # Парсит оператор for.
    # Возвращает объект Stmt::For.
    def forStatement()
        # Ожидаем '(' после ключевого слова 'for'.
        self.consume(TokenType::LEFT_PAREN, "Expected '(' after 'for'.")

        # Инициализатор может быть переменной, выражением или пустым.
        initializer = nil
        if self.match(TokenType::SEMICOLON)
            # Если после '(' нет ';', то инициализатор пустой.
            initializer = nil
        elsif self.match(TokenType::VAR)
            # Если после '(' следует ключевое слово 'var', то инициализатор - объявление переменной.
            initializer = self.varDeclaration()
        else
            # В противном случае инициализатор - выражение.
            initializer = self.expressionStatement()
        end

        # Условие может быть пустым.
        condition = nil
        if !self.check(TokenType::SEMICOLON)
            # Если после инициализатора нет ';', то условие - выражение.
            condition = self.expression()
        end
        # Ожидаем ';' после условия.
        self.consume(TokenType::SEMICOLON, "Expected ';' after loop condition.")

        # Инкремент может быть пустым.
        increment = nil
        if !self.check(TokenType::RIGHT_PAREN)
            # Если после условия нет ')', то инкремент - выражение.
            increment = self.expression()
        end

        # Ожидаем ')' после инкремента.
        self.consume(TokenType::RIGHT_PAREN, "Expected ')' after for clauses.")
        
        # Тело цикла - это состояние.
        body = self.statement()

        # Если условие пустое, то устанавливаем его в литерал 'true'.
        if condition == nil
            condition = Expr::Literal.new(true)
        end

        # Создаем новый объект класса Stmt::For, передавая в него параметры инициализатора, условия и инкремента, а также тело цикла.
        body = Stmt::For.new(initializer, condition, increment, body)
        
        # Возвращаем тело цикла.
        return body
    end

    # Анализирует оператор if.
    # Возвращает объект Stmt::If.
    def ifStatement()
        self.consume(TokenType::LEFT_PAREN, "Expect '(' sfter 'if'.")
        condition = self.expression()
        self.consume(TokenType::RIGHT_PAREN, "Expect ')' after if condition.")

        thenBranch = self.statement()
        esleBranch = nil
        if self.match(TokenType::ELSE)
            elseBranch = self.statement()
        end

        return Stmt::If.new(condition, thenBranch, elseBranch)
    end

    # Парсит выражение для печати.
    def printStatement()
        value = self.expression()
        self.consume(TokenType::SEMICOLON, "Expect ';' after variable value.")
        return Stmt::Print.new(value)
    end

    # Анализирует оператор возврата.
    # Возвращает объект Stmt::Return, который представляет оператор возврата.
    def returnStatement()
        # Получаем предыдущий токен и сохраняем его в переменную keyword.
        keyword = self.previous()
        
        value = nil
    
        if !self.check(TokenType::SEMICOLON) then
            value = self.expression()
        end
        
        self.consume(TokenType::SEMICOLON, "Expect ';' after return value.")
        # Создаем новый объект класса Stmt::Return, передавая в него параметры keyword и value.
        return Stmt::Return.new(keyword, value)
    end

     # Парсит объявление переменной.
    def varDeclaration()
        name = self.consume(TokenType::IDENTIFIER, "Expect variable name.")

        initializer = nil
        if self.match(TokenType::EQUAL) then
            initializer = self.expression()
        end

        self.consume(TokenType::SEMICOLON, "Expect ';' after variable declaration.")
        return Stmt::Var.new(name, initializer)
    end

    # Анализирует оператор while.
    # Возвращает объект Stmt::While.
    def whileStatement()
        self.consume(TokenType::LEFT_PAREN, "Expect '(' after 'while'.")
        condition = self.expression()
        self.consume(TokenType::RIGHT_PAREN, "Expect ')' after condition.")
        body = self.statement()

        return Stmt::While.new(condition, body)
    end

    # Парсит выражение для выражения.
    def expressionStatement()
        expr = self.expression()
        self.consume(TokenType::SEMICOLON,"Expect ';' after variable declaration.")
        return Stmt::Expression.new(expr)
    end

    # Парсит объявление функции.
    def function(kind)
        name = self.consume(TokenType::IDENTIFIER, "Expect #{kind} name.")
        self.consume(TokenType::LEFT_PAREN, "Expect '(' after #{kind} name.")
        parameters = Array.new()
        if !self.check(TokenType::RIGHT_PAREN) then 
            loop do 
                if parameters.length >= 255 then
                    self.error(self.peek(), "Can't have more than 255 parameters.")
                end

                parameters << self.consume(TokenType::IDENTIFIER, "Expect parameter name.")
                break if !self.match(TokenType::COMMA)
            end
        end
        self.consume(TokenType::RIGHT_PAREN, "Expect ')' after parameters.")

        # Парсим тело функции
        self.consume((TokenType::LEFT_BRACE), "Expect '{' before #{kind} body.")
        body = self.block()
        return Stmt::Function.new(name, parameters, body)
    end

    def block()
        statements = Array.new()

        while !self.check(TokenType::RIGHT_BRACE) && !self.isAtEnd?() do
            statements << self.declaration()
        end

        self.consume(TokenType::RIGHT_BRACE, "Expect '}' after block.")
        return Stmt::Block.new(statements)
    end

    # Парсит выражение присваивания.
    # 
    # В данном методе происходит парсинг выражения равенства, а затем проверяется
    # наличие оператора присваивания (=). Если оператор присваивания присутствует,
    # то происходит парсинг нового выражения присваивания, а затем проверяется,
    # является ли исходное выражение переменной. Если это так, то создается новое выражение
    # присваивания и возвращается из метода.
    # 
    # Если исходное выражение не является переменной, то вызывается метод error и генерируется
    # исключение ParseError.
    # 
    # Возвращается исходное выражение или новое выражение присваивания.
    def assignment()
        expr = self.or()

        # Проверка наличия оператора присваивания (=).
        if self.match(TokenType::EQUAL) then
            # Потребление текущего токена.
            equals = self.previous()

            # Парсинг нового выражения присваивания.
            value = self.assignment()

            # Проверка, является ли исходное выражение переменной.
            if expr.is_a?(Expr::Variable) then 
                # Получение имени переменной.
                name = expr.name

                # Создание нового выражения присваивания.
                return Expr::Assign.new(name, value)
            # если исходное выражение является состояние. Н-р: plate.cost = 5
            elsif expr.is_a?(Expr::Get) then
                get = expr
                return Expr::Set.new(get.object, get.name, value)
            end

            # Если исходное выражение не является переменной, вызывается метод error
            # и генерируется исключение ParseError.
            self.error(equals, "Invalid assignment target.")
        end

        # Возвращается исходное выражение или новое выражение присваивания.
        return expr
    end

    # Анализирует выражение OR.
    #
    # Этот метод начинается с анализа выражения AND с использованием метода and.
    # Затем он входит в цикл, который продолжается до тех пор, пока текущий токен является оператором ИЛИ.
    # Внутри цикла извлекается предыдущий токен (оператор ИЛИ),
    # анализирует другое выражение AND, используя метод `and`,
    # и создает новое логическое выражение с текущим выражением, оператором и анализируемым выражением.
    # Этот процесс продолжается до тех пор, пока не останется операторов ИЛИ.
    #
    # Возвращает проанализированное выражение ИЛИ.
    def or()
        expr = self.and()
        while self.match(TokenType::OR) do
            operator = self.previous()
            right = self.and()
            expr = Expr::Logical.new(expr, operator, right)
        end

        return expr
    end

    # Парсит логическое выражение оператора AND.
    def and()
        expr = self.equality()

        while self.match(TokenType::AND) do
            operator = self.previous()
            right = self.equality()
            expr = Expr::Logical(expr, operator, right)
        end

        return expr
    end

    # Парсит выражение равенства.
    def equality()
        expr = self.comparison()

        while self.match(TokenType::BANG_EQUAL, TokenType::EQUAL_EQUAL) do
            operator = self.previous()
            right = self.comparison()
            expr = Expr::Binary.new(expr, operator, right)
        end

        return expr
    end

    # Парсит выражение сравнения.
    def comparison()
        expr = self.term()

        while self.match(TokenType::GREATER, TokenType::GREATER_EQUAL, TokenType::LESS, TokenType::LESS_EQUAL) do
            operator = self.previous()
            right = self.term()
            expr = Expr::Binary.new(expr, operator, right)
        end

        return expr
    end

    # Парсит выражения Сложения и Вычитания.
    def term()
        expr = self.factor()

        while self.match(TokenType::MINUS, TokenType::PLUS) do
            operator = self.previous()
            right = self.factor()
            expr = Expr::Binary.new(expr, operator, right)
        end

        return expr
    end

    # Парсит выражения Умножения и Деления.
    def factor()
        expr = self.unary()

        while self.match(TokenType::SLASH, TokenType::STAR) do
            operator = self.previous()
            right = self.unary()
            expr = Expr::Binary.new(expr, operator, right)
        end

        return expr
    end

    # Парсит унарное выражение.
    def unary()
        if self.match(TokenType::BANG, TokenType::MINUS) then
            operator = self.previous()
            right = self.unary()
            return Expr::Unary.new(operator, right)
        end

        return self.call()
    end
    
    # Обработка функции
    def finishCall(callee)
        # Парсим аргументы функции.
        arguments = Array.new()
        if !self.check(TokenType::RIGHT_PAREN) then
            loop do 
                if arguments.length >= 255 then
                    self.error(self.peek(), "Can't have more than 255 arguments.")
                end
                arguments << self.expression()
                break if !self.match(TokenType::COMMA)
            end
        end

        paren = self.consume(TokenType::RIGHT_PAREN, "Expect ')' after arguments.")

        return Expr::Call.new(callee, paren, arguments)
    end

    # Парсит вызываемое выражение.
    def call()
        expr = self.primary()

        while true do
            if self.match(TokenType::LEFT_PAREN) then
                expr = self.finishCall(expr)
            elsif self.match(TokenType::DOT) then
                name = self.consume(TokenType::IDENTIFIER, "Expect property name after '.'.")
                expr = Expr::Get.new(expr, name)
            else
                break
            end
        end

        return expr
    end

    # Парсит первичное выражение.
    def primary()
        if self.match(TokenType::FALSE) then return Expr::Literal.new(false) end
        if self.match(TokenType::TRUE) then return Expr::Literal.new(true) end
        if self.match(TokenType::NIL) then return Expr::Literal.new(nil) end

        if self.match(TokenType::NUMBER, TokenType::STRING) then
            return Expr::Literal.new(self.previous().literal)
        end

        if self.match(TokenType::SUPER) then
            keyword = self.previous()
            self.consume(TokenType::DOT, "Expect '.' after 'super'.")
            method = self.consume(TokenType::IDENTIFIER, "Expect superclass method name.")
            return Expr::Super.new(keyword, method)
        end

        if self.match(TokenType::THIS) then
            return Expr::This.new(self.previous()) 
        end

        if self.match(TokenType::IDENTIFIER) then
            return Expr::Variable.new(self.previous())
        end

        if self.match(TokenType::LEFT_PAREN) then
            expr = self.expression()
            self.consume(TokenType::RIGHT_PAREN, "Expect ')' after expression.")
            return Expr::Grouping.new(expr)
        end

        raise self.error(self.peek(), "Expect expression.")
    end
    

    # Проверяет, имеет ли текущий токен любой из заданных типов и потребляет его, если да.
    def match(*types)
        types.each do |type|
            if self.check(type) then 
                self.advance()
                return true
            end
        end

        return false
    end

    # Потребляет текущий токен, если он имеет заданный тип.
    # Если он не имеет заданный тип, вызывает ошибку.
    def consume(type, message)
        if self.check(type) then return self.advance() end

        raise self.error(peek(), message)
    end

    # Проверяет, имеет ли текущий токен заданный тип.
    # Если он имеет заданный тип, возвращает true.
    # Если он не имеет заданный тип, возвращает false.
    def check(type)
        if (self.isAtEnd?()) then return false end
        return self.peek().type == type
    end   
    

    # Потребляет текущий токен и возвращает его.
    def advance()
        if self.isAtEnd?() then return self.previous() end
        @@current += 1
        return @tokens[@@current - 1]
    end

    # Проверяет, достигли ли мы конца токенов.
    def isAtEnd?()
        return self.peek().type == TokenType::EOF
    end

    # Возвращает текущий токен.
    def peek()
        return @tokens[@@current]
    end

    # Возвращает предыдущий токен.
    def previous()
        return @tokens[@@current - 1]
    end

    # Создает ошибку ParseError и вызывает ее.
    def error(token, message)
        @lox.error(token, message)
        return Parser::ParseError.new()
    end

    # Синхронизирует парсер после ошибки.
    def synchronize()
        self.advance()

        while !self.isAtEnd?() do 
            if self.previous.type == TokenType::SEMICOLON then return end
                case self.peek().type
                when TokenType::CLASS, TokenType::FUN, TokenType::VAR, TokenType::FOR, TokenType::IF, TokenType::WHILE,  TokenType::PRINT, TokenType::RETURN then
                    return
                end
            self.advance()
        end
    end
end









