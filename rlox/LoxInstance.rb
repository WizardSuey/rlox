require_relative 'RunTimeError.rb'


class LoxInstance
    attr_reader :Klass, :Fields

    def self.Klass()
        return @Klass
    end
    private_class_method :Klass

    def self.Fields()
        return @Fields
    end
    private_class_method :Fields

    def initialize(klass)
        @Klass = klass
        @Fields = Hash.new()
    end

    # Метод get проверяет, существует ли в экземпляре поле с заданным именем.
    # Если поле с таким именем существует, возвращает его значение.
    # В противном случае выбрасывает исключение RunTimeError с информацией об отсутствующем свойстве.
    def get(name)
        if @Fields.has_key?(name.lexeme) then
            return @Fields.fetch(name.lexeme)
        end

        method = @Klass.findMethod(name.lexeme)
        if method != nil then return method.bind(self) end

        raise RunTimeError.new(name, "Undefined property '#{name.lexeme}'.")
    end

    def set(name, value)
        @Fields.store(name.lexeme, value)
    end

    def to_s()
        return "#{@Klass.name} instance"
    end
end