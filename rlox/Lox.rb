require_relative 'TokenType.rb'
require_relative 'Token.rb'
require_relative 'scanner.rb'

class Lox
    @@hadError = false

    def error(line_index, message)
        #Сообщает пользователю, что в данной строке произошла синтаксическая ошибка.
        self.report(line_index, "", message)
    end

    #private 

    def runFile(path)
        """
        Запускает интерпретатор в цикле, 
        постоянно запрашивая у пользователя ввод данных пока не будет введена пустая строка.
        """
        if @@hadError
            return
        end

        begin
            bytes = File.open(path, 'r') { |f| f.read }
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

    private

    def run(source)
        # Запускает заданный исходный код и печатает токены, сгенерированные сканером.
        scanner = Scanner.new(source, lox=self)
        tokens = scanner.scanTokens()
        tokens.each do |token|
            puts token.toString()
        end
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
main()
#"C:/crafting interpreters/rlox/lox.lox"