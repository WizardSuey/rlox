require_relative 'LoxCallable.rb'
require_relative 'Environment.rb'
require_relative 'Return.rb'
require_relative 'LoxInstance.rb'


class LoxClass < LoxCallable
    attr_reader :name

    def initialize(name)
        @name = name
    end

    def arity()
        return 0
    end

    def call(interpreter, argumnets)
        return instance = LoxInstance.new(self)
    end

    def to_s()
        return name
    end
end