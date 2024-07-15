class RunTimeError < StandardError
    attr_reader :token

    def initialize(token, message)
        @token = token
        super(message)
    end
end
