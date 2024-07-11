require_relative 'TokenType.rb'
require_relative 'Token.rb'
    

class Scanner
    attr_reader :source, :tokens, :start, :current, :line, :lox

    # Зарезервированные слова
    KEYWORDS = {
        "and" => :AND,
        "class" => :CLASS,
        "else" => :ELSE,
        "false" => :FALSE,
        "for" => :FOR,
        "fun" => :FUN,
        "if" => :IF,
        "nil" => :NIL,
        "or" => :OR,
        "print" => :PRINT,
        "return" => :RETURN,
        "super" => :SUPER,
        "this" => :THIS,
        "true" => :TRUE,
        "var" => :VAR,
        "while" => :WHILE
    }.freeze
    private_constant :KEYWORDS

    def initialize(source, lox)
        @source = source
        @tokens = Array.new()
        @start = 0  #  указывает на первый символ сканируемой лексемы
        @current = 0    # указывает на рассматриваемый в данный момент символ
        @line = 1
        @lox = lox
    end

    def scanTokens()
        """
        Сканирует токены в исходном коде до тех пор, пока не будет достигнут конец. 
        Он создает новые токены для каждого сканируемого токена и добавляет их в список токенов.
        """
        while !self.isAtEnd?()
            @start = @current
            self.scanToken()
        end

        @tokens << Token.new(TokenType::EOF, "", nil, @line)
        return @tokens
    end

    private

    def isAtEnd?()
        # сообщает, израсходовали ли все символы
        return @current >= @source.length
    end

    # @return [void]
    def scanToken()
        # Сканирует один символ в исходном коде
        char = self.peek()
        @current += 1
        case char
            when "(" then self.addToken(TokenType::LEFT_PAREN)
            when ")" then self.addToken(TokenType::RIGHT_PAREN)
            when "{" then self.addToken(TokenType::LEFT_BRACE)
            when "}" then self.addToken(TokenType::RIGHT_BRACE)
            when "," then self.addToken(TokenType::COMMA)
            when "." then self.addToken(TokenType::DOT)
            when "-" then self.addToken(TokenType::MINUS)
            when "+" then self.addToken(TokenType::PLUS)
            when ";" then self.addToken(TokenType::SEMICOLON)
            when "*" then self.addToken(TokenType::STAR)
            when "!" then self.match('=') ? self.addToken(TokenType::BANG_EQUAL) : self.addToken(TokenType::BANG)
            when "=" then self.match('=') ? self.addToken(TokenType::EQUAL_EQUAL) : self.addToken(TokenType::EQUAL)
            when "<" then self.match('=') ? self.addToken(TokenType::LESS_EQUAL) : self.addToken(TokenType::LESS)
            when ">" then self.match('=') ? self.addToken(TokenType::GREATER_EQUAL) : self.addToken(TokenType::GREATER)
            when "/" then 
                if self.match('/')
                    # Комментарий идет до конца строки.
                    while self.peek() != "\n" && !self.isAtEnd?() 
                        self.advance()
                    end
                else
                    self.addToken(TokenType::SLASH)
                end
            when " " then # ignore
            when "\r" then # ignore
            when "\t" then # ignore
            when "\n" then @line += 1
            when '"' then self.string()
            when "o" then addToken(match('r') ? TokenType::OR : TokenType::IDENTIFIER)
            else 
                if self.isDigit(char)
                    self.number()
                elsif self.isAlpha(char)
                    self.identifier()
                else
                    @lox.error(@line, "Unexpected character.")
                end
        end
    end
    
    def identifier()
        # Сканирует исходный код на наличие идентификаторов и добавляет для них токены.
        #
        # Этот метод перемещает текущую позицию в исходном коде, пока следующий символ — буквенно-цифровой. 
        # Затем он извлекает текст между начальной и текущей позициями.
        # Тип идентификатора определяется путем проверки соответствия текста какому-либо из ключевых слов. 
        # Если оно не соответствует ни одному ключевому слову, устанавливается тип TokenType::IDENTIFIER.
        while (self.isAlphaNumeric(self.peek())) do self.advance() end
        text = @source[@start...@current]
        type = KEYWORDS[text]
        if type == nil then type = TokenType::IDENTIFIER end
        self.addToken(type)
    end

    def number()
        # Функция для поиска чисел в исходном коде и добавления токенов для числовых значений.
        while self.isDigit(self.peek()) do self.advance() end
            
        # Найдите дробную часть
        if self.peek() == '.' && self.isDigit(self.peekNext())
            self.advance()
            while self.isDigit(peek()) do self.advance() end
        end

        self.addToken(TokenType::NUMBER, @source[@start...@current].to_f)
    end

    def string()
        # Сканирует строку в исходном коде.
        # Этот метод сканирует строку в исходном коде, пока не встретит закрывающую двойную кавычку ("),
        # или достигает конца исходного кода. Он увеличивает счетчик строк, если символ новой строки встречается.
        # Затем он продвигает текущую позицию и проверяет, достигла ли она конца
        # исходного кода. Если да, он вызывает метод Lox.error. В противном случае он добавляет токен
        # типа `TOKENS[:string]` со значением отсканированной строки в списке токенов.

        while self.peek() != '"' && !self.isAtEnd?()
            if self.peek() == "\n" then @line += 1 end
            self.advance()
        end

        if self.isAtEnd?()
            @lox.error(@line, "Unterminated string.")
            return
        end
        self.advance() # The closing quote.

        # Обрежьте окружающие кавычки.
        value = @source[@start + 1...@current - 1]
        self.addToken(TokenType::STRING, value)
    end

    def advance()
        # возвращает следующий символ исходного кода.
        return @source[@current+=1]
    end

    def addToken(type, literal=nil)
        # Добавляет токен в список токенов на основе предоставленного типа и литерала.
        text = @source[@start...@current]
        tokens << Token.new(type, text, literal, @line)
    end

    def match(expected)
        # Проверяет, совпадает ли следующий символ с expected
        if isAtEnd?() || @source[@current] != expected
            return false
        end

        @current += 1
        return true
    end

    def peek()
        # Возвращает следующий символ в исходном коде, не перемещая текущую позицию.
        # Если достигнут конец исходного кода, возвращается "\0".
        isAtEnd?() ? "\0" : @source[@current] 
    end

    def peekNext()
        @current + 1 >= @source.length ? "\0" : @source[@current + 1]
    end

    def isAlpha(c)
        # Проверяет, является ли символ буквой.
        return false if c.nil?
        return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
    end

    def isAlphaNumeric(c)
        # Проверяет, является ли символ буквой или цифрой.
        return isAlpha(c) || isDigit(c)
    end

    def isDigit(c)
        # Проверяет, является ли символ цифрой.
        # Проверяет, что c не равно нулю, прежде чем проверять его значение.
        # Возвращает false, если c равно нулю.
        return false if c.nil?
        return c >= '0' && c <= '9'
    end
end






