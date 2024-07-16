# Это модуль парсит язык программирования RLOX.
# Он определяет класс Parser, который отвечает за парсинг выражений.
require_relative 'TokenType.rb'
require_relative 'Token.rb'
require_relative 'Expr.rb'
require_relative 'Stmt.rb'


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
            if self.match(TokenType::VAR) then return self.varDeclaration() end
            return self.statement()
        rescue ParseError => error
            self.synchronize()
            return nil
        end
    end

    # Парсит выражение.
    def statement()
        if self.match(TokenType::PRINT) then return self.printStatement() end
        if self.match(TokenType::LEFT_BRACE) then return Stmt::Block.new(self.block()) end

        return self.expressionStatement()
    end

    # Парсит выражение для печати.
    def printStatement()
        value = self.expression()
        self.consume(TokenType::SEMICOLON, "Expect ';' after variable value.")
        return Stmt::Print.new(value)
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

    # Парсит выражение для выражения.
    def expressionStatement()
        expr = self.expression()
        self.consume(TokenType::SEMICOLON,"Expect ';' after variable declaration.")
        return Stmt::Expression.new(expr)
    end

    def block()
        statements = Array.new()

        while !self.check(TokenType::RIGHT_BRACE) && !self.isAtEnd?() do
            statements << self.declaration()
        end

        self.consume(TokenType::RIGHT_BRACE, "Expect '}' after block.")
        return statements
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
        # Парсинг выражения равенства.
        expr = self.equality()

        # Проверка наличия оператора присваивания (=).
        if self.match(TokenType::EQUAL) then
            # Потребление текущего токена.
            equals = self.previous()

            # Парсинг нового выражения присваивания.
            value = self.assignment()

            # Проверка, является ли исходное выражение переменной.
            if (expr.is_a?(Expr::Variable)) then 
                # Получение имени переменной.
                name = expr.name

                # Создание нового выражения присваивания.
                return Expr::Assign.new(name, value)
            end

            # Если исходное выражение не является переменной, вызывается метод error
            # и генерируется исключение ParseError.
            self.error(equals, "Invalid assignment target.")
        end

        # Возвращается исходное выражение или новое выражение присваивания.
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

        return self.primary()
    end

    # Парсит первичное выражение.
    def primary()
        if self.match(TokenType::FALSE) then return Expr::Literal.new(false) end
        if self.match(TokenType::TRUE) then return Expr::Literal.new(true) end
        if self.match(TokenType::NIL) then return Expr::Literal.new(nil) end

        if self.match(TokenType::NUMBER, TokenType::STRING) then
            return Expr::Literal.new(self.previous().literal)
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

