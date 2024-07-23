require_relative 'TokenType.rb'
require_relative 'Token.rb'
require_relative 'scanner.rb'
require_relative 'parser.rb'
require_relative 'AstPrinter.rb'
require_relative 'Interpreter.rb'
require_relative 'RunTimeError.rb'
require_relative 'Resolver.rb'


class Lox
    @@hadError = false
    @@hadRuntimeError = false
    @@Interpreter = Interpreter.new(self)

    def self.Interpreter
        return @@Interpreter
    end

    private_class_method :Interpreter

    def runFile(path)
        """
        Запускает интерпретатор в цикле, 
        постоянно запрашивая у пользователя ввод данных пока не будет введена пустая строка.
        """
        if @@hadError then exit(65) end
        if @@hadRuntimeError then exit(70) end

        begin
            if File.extname(path) == ".lox"
                bytes = File.open(path, 'r') { |f| f.read }
            else
                $stdout << "Неверное расширение файла. Ожидалось расширение .lox\n"
            end
        rescue Exception => e
            $stdout << "Error: Could not open file: #{path}\n"
            return
        end

        self.run(bytes)
    end

    def runPrompt()
        """
        Запускает интерпретатор в цикле, 
        постоянно запрашивая у пользователя ввод данных пока не будет введена пустая строка.
        """
        loop do 
            $stdout.print "> "
            line = $stdin.readline
            break if line.nil?
            self.run(line)
            @@hadError = false
        end
    end

    def error(arg1, arg2)
        # Вызывается, когда произошла синтаксическая ошибка.
        # Типа перегрузка метода
        if arg1.is_a?(Integer)
            line_index = arg1
            message = arg2
            report(line_index, "", message)
        elsif arg1.is_a?(Token)
            token = arg1
            message = arg2
            if token.type == TokenType::EOF
                report(token.line, " at end", message)
            else
                report(token.line, "at '#{token.lexeme}'", message)
            end
        end
    end

    def self.runtimeError(error)
        # Обрабатывает ошибку во время выполнения, печатая сообщение об ошибке вместе с номером строки, в которой произошла ошибка.
        $stdout << "[line #{error.token.line}] #{error.message}\n"
        @@hadRuntimeError = true
    end

    private

    def run(source)
        # Запускает заданный исходный код и печатает токены, сгенерированные сканером.
        scanner = Scanner.new(source, lox=self)
        tokens = scanner.scanTokens()

        # tokens.each do |token|
        #     $stdout << "#{token.toString()}\n"
        # end

        parser = Parser.new(tokens, lox=self)
        statements = parser.parse()

        # Остановиться, если произошла синтаксическая ошибка
        if @@hadError then return end

        resolver = Resolver.new(@@Interpreter, self)
        resolver.resolve(statements)

        if @@hadError then return end
        
        @@Interpreter.interpret(statements)
    end

    def report(line_index, where, message)
        #Сообщает пользователю, что в данной строке произошла синтаксическая ошибка.
        $stdout << "[line #{line_index}] Error #{where}: #{message}\n"
        @@hadError = true
    end


end



def main(*args)
    lox = Lox.new()
    if args.length > 1
        $stdout << "Usage: rlox [script]"
        exit(64)
    elsif args.length == 1
        lox.runFile(args[0])
    else
        lox.runPrompt()
    end
end
main("./lox.lox")
#"./lox.lox"
