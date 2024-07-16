require_relative 'TokenType.rb'
require_relative 'Token.rb'
require_relative 'Expr.rb'
require_relative 'Stmt.rb'


class Parser
    class ParseError < RuntimeError

    end 

    attr_reader :tokens

    @@current = 0

    def initialize(tokens, lox)
        @tokens = tokens
        @lox = lox
    end

    def parse()
        # Парсер выражений
        statements = Array.new()
        while !self.isAtEnd?() do
            statements << self.statement()
        end
        return statements
    end

    private 

    def expression()
        # Правила выражений
        return self.equality()
    end

    def statement()
        if self.match(TokenType::PRINT) then return self.printStatement() end

        return self.expressionStatement()
    end

    def printStatement()
        value = self.expression()
        self.consume(TokenType::SEMICOLON, "Expect ';' after value.")
        return Stmt::Print.new(value)
    end

    def expressionStatement()
        expr = self.expression()
        self.consume(TokenType::SEMICOLON, "Expect ';' after expression.")
        return Stmt::Expression.new(expr)
    end

    def equality()
        # Правило равенства
        expr = self.comparison()

        while self.match(TokenType::BANG_EQUAL, TokenType::EQUAL_EQUAL) do
            operator = self.previous()
            right = self.comparison()
            expr = Expr::Binary.new(expr, operator, right)
        end

        return expr
    end

    def comparison()
        # Правило сравнения
        expr = self.term()

        while self.match(TokenType::GREATER, TokenType::GREATER_EQUAL, TokenType::LESS, TokenType::LESS_EQUAL) do
            operator = self.previous()
            right = self.term()
            expr = Expr::Binary.new(expr, operator, right)
        end

        return expr
    end

    def term()
        # Правило сложения и вычитания
        expr = self.factor()

        while self.match(TokenType::MINUS, TokenType::PLUS) do
            operator = self.previous()
            right = self.factor()
            expr = Expr::Binary.new(expr, operator, right)
        end

        return expr
    end

    def factor()
        # Правило умножения и деления
        expr = self.unary()

        while self.match(TokenType::SLASH, TokenType::STAR) do
            operator = self.previous()
            right = self.unary()
            expr = Expr::Binary.new(expr, operator, right)
        end

        return expr
    end

    def unary()
        # Правило унарной операции
        if self.match(TokenType::BANG, TokenType::MINUS) then
            operator = self.previous()
            right = self.unary()
            return Expr::Unary.new(operator, right)
        end

        return self.primary()
    end

    def primary()
        # Правило первичных выражений
        if self.match(TokenType::FALSE) then return Expr::Literal.new(false) end
        if self.match(TokenType::TRUE) then return Expr::Literal.new(true) end
        if self.match(TokenType::NIL) then return Expr::Literal.new(nil) end

        if self.match(TokenType::NUMBER, TokenType::STRING) then
            return Expr::Literal.new(self.previous().literal)
        end

        if self.match(TokenType::LEFT_PAREN) then
            expr = self.expression()
            self.consume(TokenType::RIGHT_PAREN, "Expect ')' after expression.")
            return Expr::Grouping.new(expr)
        end

        raise self.error(self.peek(), "Expect expression.")
    end

    

    def match(*types)
        # проверяет, имеет ли текущий токен какой-либо из заданных типов
        # Если да, он потребляет токен и возвращает true. 
        # В противном случае он возвращает false и оставляет текущий токен в покое.
        types.each do |type|
            if self.check(type) then 
                self.advance()
                return true
            end
        end

        return false
    end

    def consume(type, message)
        # Проверяет, соответствует ли следующий токен ожидаемому типу. 
        # Если да, то он потребляет токен, и все в порядке. 
        # Если там есть какой-то другой токен, значит, мы столкнулись с ошибкой.
        if self.check(type) then return self.advance() end

        raise self.error(peek(), message)
    end

    def check(type)
        #  возвращает true, если текущий токен имеет заданный тип
        if (self.isAtEnd?()) then return false end
        return self.peek().type == type
    end
    

    def advance()
        # потребляет текущий токен и возвращает его
        if self.isAtEnd?() then return self.previous() end
        @@current += 1
        return @tokens[@@current - 1]
    end

    def isAtEnd?()
        # проверяет, закончились ли у нас токены для анализа.
        return self.peek().type == TokenType::EOF
    end

    def peek()
        # возвращает текущий токен, который нам еще предстоит использовать
        return @tokens[@@current]
    end

    def previous()
        # возвращает последний использованный токен
        return @tokens[@@current - 1]
    end

    def error(token, message)
        @lox.error(token, message)
        return Parser::ParseError.new()
    end

    def synchronize()
        # Он отбрасывает токены до тех пор, пока не решит, что нашел границу оператора. 
        # После обнаружения ошибки ParseError мы вызовем это и затем, будем надеяться, снова синхронизируемся
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






