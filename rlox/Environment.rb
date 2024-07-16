require_relative 'RunTimeError.rb'


# Класс среды исполнения. 
# Представляет собой словарь, где ключи - имена переменных, а значения - их значения.
class Environment 
    # Словарь, содержащий переменные окружения 
    attr_reader :values

    @Enclosing

    def self.Enclosing()
        return @Enclosing
    end
    private_class_method :Enclosing

    # Инициализирует новый объект Environment
    #
    # @return [Environment] новый объект Environment
    def initialize(enclosing = nil)
        @values = Hash.new()       # Словарь, содержащий переменные окружения
        @Enclosing = enclosing # Внешнее окружение
    end

    # Возвращает значение переменной по ее имени
    #
    # @param name [Token] токен с именем переменной
    # @return [Object] значение переменной
    def get(name)
        if @values.has_key?(name.lexeme) then 
            return @values.fetch(name.lexeme)
        end

        # Если переменная не найдена, проверяем внешнее окружение
        if @Enclosing != nil then return @Enclosing.get(name) end

        # Если переменная не найдена, генерируется исключение RunTimeError
        raise RunTimeError.new(name, "Неопределенная переменная '#{name.lexeme}'.")
    end

    # Присваивает значение переменной по ее имени
    #
    # @param name [Token] токен с именем переменной
    # @param value [Object] значение, которое присваивается переменной
    def assign(name, value)
        if @values.has_key?(name.lexeme) then
            @values.store(name.lexeme, value)
            return
        end
        
        # Если переменная не найдена, проверяем внешнее окружение
        if @enclosing != nil then 
            @enclosing.assign(name, value)
            return
        end

        raise RunTimeError.new(name, "Неопределенная переменная '#{name.lexeme}'.")
    end

    # Определяет переменную в окружении
    #
    # @param name [String] имя переменной
    # @param value [Object] значение переменной
    def define(name, value)
        @values.store(name, value)
    end
end


