require_relative 'LoxCallable.rb'
require_relative 'Environment.rb'
require_relative 'Return.rb'
require_relative 'LoxInstance.rb'


class LoxClass < LoxCallable
    attr_reader :name, :Methods, :superclass

    def self.Methods()
        return @Methods
    end

    def initialize(name, superclass, methods)
        @name = name
        @superclass = superclass
        @Methods = methods
    end

    def findMethod(name)
        if @Methods.has_key?(name) then
            return @Methods.fetch(name)
        end

        if @superclass != nil then
            return @superclass.findMethod(name)
        end

        return nil
     end

    def arity()
        initializer = findMethod("init")
        if initializer == nil then return 0 end
        return initializer.arity()
    end

    def call(interpreter, argumnets)
        instance = LoxInstance.new(self)
        # При вызове класса после создания LoxInstance мы ищем метод «init». 
        # Если мы его находим, мы немедленно связываем и вызываем его, как обычный вызов метода. 
        # Список аргументов пересылается вместе.
        initializer = findMethod("init")
        if initializer != nil then
            initializer.bind(instance).call(interpreter, argumnets)
        end
        return instance
    end

    def to_s()
        return name
    end
end