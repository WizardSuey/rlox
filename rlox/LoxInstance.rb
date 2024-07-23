require_relative 'RunTimeError.rb'


class LoxInstance
    attr_reader :Klass, :Fileds

    def self.Klass()
        return @Klass
    end
    private_class_method :Klass

    def self.Fileds()
        return @Fileds
    end
    private_class_method :Fileds

    def initialize(klass)
        @Klass = klass
        @Fileds = Hash.new()
    end

# Метод get проверяет, существует ли в экземпляре поле с заданным именем.
    # Если поле с таким именем существует, возвращает его значение.
    # В противном случае выбрасывает исключение RunTimeError с информацией об отсутствующем свойстве.
    def get(name)
        if @Fileds.has_key?(name.lexeme) then
            return @Fileds.fetch(name.lexeme)
        end

        raise RunTimeError.new(name, "Undefined property '#{name.lexeme}'.")
    end

    def set(name, value)
        @Fields.store(name.lexeme, value)
    end

    def to_s()
        return "#{@Klass.name} instance"
    end
end