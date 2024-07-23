require_relative 'LoxCallable.rb'
require_relative 'Environment.rb'
require_relative 'Return.rb'


class LoxFunction < LoxCallable
    include ReturnModule
    attr_reader :Declaration, :Closure    # Декларация функции и окружение, в котором она была определена.

    def self.Declaration()
        return @Declaration
    end
    private_class_method :Declaration

    def self.Closure()
        return @Closure
    end
    private_class_method :Closure

    def initialize(declaration, interpreter, closure)
        @Declaration = declaration
        @interpreter = interpreter
        @Closure = closure
    end

    def arity()
        return @Declaration.params.length
    end

    def call(interpreter, arguments)
        # Создание нового окружения.
        environment = Environment.new(@Closure)
        # Заполнение окружения параметрами функции.
        for i in 0...(@Declaration.params.length) do
            environment.define(@Declaration.params.at(i).lexeme, arguments.at(i))
        end

        
        begin
            # Выполнение блока функции в новом окружении.       
            # Если в блоке функции возникает оператор return, 
            # метод executeBlock выбрасывает исключение Return.
            @interpreter.executeBlock(@Declaration.body.statements, environment)
        rescue ReturnModule::Return => returnValue
            # Если возникло исключение Return, то возвращаем значение,
            # которое вернул оператор return.
            return returnValue.value
        end

        return nil
    end

    def to_s()
        return "<fn #{@Declaration.name.lexeme}>"
    end
end