class RunTimeError < RuntimeError
    attr_reader :token

    def initialize(token, message)
        @token = token
        super(message)
    end
end
