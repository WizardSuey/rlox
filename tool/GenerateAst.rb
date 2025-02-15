""" Генерация AST-дерева. """

def main(*args)
    if args.length != 1 then
        $stderr << "Usage: generate_ast <output directory>"
        exit(64)
    end
    outputDir = args[0]

    # Генерация выражения.
    defineAst(outputDir, "Expr", [
        "Assign   : Token name, Expr value",
        "Binary   : Expr left, Token operator, Expr right",
        "Call     : Expr callee, Token paren, Array(Expr) arguments",
        "Get      : Expr object, Token name",
        "Grouping : Expr expression",
        "Literal  : Object value",  
        "Logical  : Expr left, Token operator, Expr right",
        "Set      : Expr object, Token name, Expr value",
        "Super    : Token keyword, Token method",
        "This     : Token keyword",
        "Unary    : Token operator, Expr right",
        "Variable : Token name"
    ])
    defineAst(outputDir, "Stmt", [
        "Block      : Array(Stmt) statements",
        "Class_def  : Token name, ExprVariable superclass, Array(StmtFunction) methods",
        "Expression : Expr expression",
        "Function   : Token name, Array(Token) params, Array(Stmt) body",
        "If         : Expr condition, Stmt thenBranch, Stmt elseBranch",
        "Print      : Expr expression",
        "Return     : Token keyword, Expr value",
        "Var        : Token name, Expr initializer",
        "For        : Expr initializer, Expr condition, Expr increment, Stmt body",
        "While      : Expr condition, Stmt body"
    ])
end


def defineAst(outputDir, baseName, types) 
    """ Создает определение базового типа в абстрактном синтаксическом дереве (AST) """
    # Генерация AST-дерева.
    path = "#{outputDir}/#{baseName}.rb"
    writer = File.open(path, "w")

    writer << "module #{baseName}\n"

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
    writer << "  class #{className}\n"
    writer << "     include #{baseName}\n\n"

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

