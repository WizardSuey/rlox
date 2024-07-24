require_relative 'LoxCallable.rb'
require_relative 'Environment.rb'
require_relative 'Return.rb'


class LoxFunction < LoxCallable
    include ReturnModule
    attr_reader :Declaration, :Closure, :IsInitializer    # Декларация функции и окружение, в котором она была определена.

    def self.Declaration()
        return @Declaration
    end
    private_class_method :Declaration

    def self.Closure()
        return @Closure
    end
    private_class_method :Closure

    def self.IsInitializer()
        return @IsInitializer
    end
    private_class_method :IsInitializer

    def initialize(declaration, interpreter, closure, isInitializer)
        @Declaration = declaration
        @interpreter = interpreter
        @IsInitializer = isInitializer
        @Closure = closure
    end

    # Метод bind привязывает функцию к объекту.
    def bind(instance)
        environment = Environment.new(@Closure)
        environment.define("this", instance)
        return LoxFunction.new(@Declaration, @interpreter, environment, @IsInitializer)
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
            if @IsInitializer then return @Closure.getAt(0, "this") end
            return returnValue.value
        end

        if @IsInitializer then return @Closure.getAt(0, "this") end

        return nil
    end

    def to_s()
        return "<fn #{@Declaration.name.lexeme}>"
    end
end