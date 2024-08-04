module ReturnModule
    class Return < RuntimeError
        attr_reader :value

        def initialize(value)
            super
            @value = value
        end
    end
end