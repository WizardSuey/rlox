# Класс среды исполнения. 
# Представляет собой словарь, где ключи - имена переменных, а значения - их значения.
class Environment 
    # Словарь, содержащий переменные окружения 
    attr_reader :values
    attr_reader :Enclosing
    

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
        if @values&.has_key?(name&.lexeme) then 
            return @values.fetch(name.lexeme)
        end

        # Если переменная не найдена, проверяем внешнее окружение
        if @Enclosing != nil then 
            return @Enclosing.get(name) 
        end

        # Если переменная не найдена, генерируется исключение RunTimeError
        raise RunTimeError.new(name, "Not initialized variable '#{name.lexeme}'.")
    end

    # Присваивает значение переменной по ее имени
    #
    # @param name [Token] токен с именем переменной
    # @param value [Object] значение, которое присваивается переменной
    def assign(name, value)
        if @values&.has_key?(name&.lexeme) then
            @values.store(name.lexeme, value)
            return
        end
        
        # Если переменная не найдена, проверяем внешнее окружение
        if @Enclosing != nil then 
            @Enclosing.assign(name, value)
            return
        end

        raise RunTimeError.new(name, "Not initialized variable '#{name.lexeme}'.")
    end

    # Определяет переменную в окружении
    #
    # @param name [String] имя переменной
    # @param value [Object] значение переменной
    def define(name, value)
        @values.store(name, value)
    end

    def ancestor(distance)
        # Это проходит фиксированное количество прыжков вверх по родительской цепочке и возвращает туда среду. 
        # Как только мы это получим, getAt() просто возвращает значение переменной на карте этой среды.
        environment = self
        distance.times do
            environment = environment.Enclosing
        end
        
        return environment  
    end

    # Возвращает значение переменной в окружении
    def getAt(distance, name)
        return self.ancestor(distance).values.fetch(name)
    end

    # Присваивает значение переменной в окружении
    def assignAt(distance, name, value)         
        self.ancestor(distance).values.store(name.lexeme, value)
    end
end

