""" Генерация AST-дерева. """

def main(*args)
    if args.length != 1 then
        $stderr << "Usage: generate_ast <output directory>"
        exit(64)
    end
    outputDir = args[0]

    # Генерация выражения.
    defineAst(outputDir, "Expr", [
        "Binary   : Expr left, Token operator, Expr right",
        "Grouping : Expr expression",
        "Literal  : Object value",  
        "Unary    : Token operator, Expr right"
    ])
end


def defineAst(outputDir, baseName, types) 
    """ Создает определение базового типа в абстрактном синтаксическом дереве (AST) """
    # Генерация AST-дерева.
    path = "#{outputDir}/#{baseName}.rb"
    writer = File.open(path, "w")

    writer << "class #{baseName}\n"

    defineVisitor(writer, baseName, types)

    # Добавление дочерних классов.
    types.each do |type|    
        className = type.split(":")[0].strip()  # имя дочернего типа
        fields = type.split(":")[1].strip()     # поля дочернего типа
        defineType(writer, baseName, className, fields)
    end

    writer << "end\n"
end
private :defineAst

def defineType(writer, baseName, className, fieldList)
    """ Создает определение класса для типа в абстрактном синтаксическом дереве (AST) """
    writer << "  class #{className} < #{baseName}\n"

    fields = fieldList.split(", ")  # список полей
    i = 0   # вспомогательный счётчик

    # Атрибуты только для чтения
    writer << "     attr_reader "
    fields.each do |field|
        writer << ":#{field.split(" ")[1]}"
        if i < (fields.length()) - 1 then
            writer << ", "
            i += 1
        else
            i = 0
        end
    end
    
    writer << "\n\n"
    

    # Инициализатор
    writer << "    def initialize("
    fields.each do |field| 
        writer << "#{field.split(" ")[1]}"
        if i < (fields.length()) - 1 then
            writer << ", "
            i += 1
        else
            i = 0
        end
    end
    writer << ")\n"

    # Передаваемые параметры
    fields.each do |field|
        name = field.split(" ")[1]
        writer << "      @#{name} = #{name}\n"
    end
    writer << "    end\n"

    # Шаблон посетителя
    writer << "\n"

    # Базовый метод accept().
    writer << "    def accept(visitor)\n"
    writer << "      visitor.visit#{className}#{baseName}(self)\n"
    writer << "    end\n"

    writer << "  end\n"
end
private :defineType

def defineVisitor(writer, baseName, types)
    """ Создает определение визитора для базового типа в абстрактном синтаксическом дереве (AST) """
    writer << "    class Visitor\n"

    # перебираем все подклассы и объявляем метод посещения для каждого из них
    types.each do |type|
        typeName = type.split(":")[0].strip()
        writer << "        def visit#{typeName}#{baseName}(#{baseName.downcase()}) end\n"
    end
    writer << "    end\n"
end
private :defineVisitor

main("rlox")
