module Autoscaler
  # A minimal scaler to use as stub for local testing
  class StubScaler
    # @param [String] type used to distinguish messages from multiple stubs
    def initialize(type = 'worker')
      @type = type
      @workers = 0
    end

    attr_reader :type

    # Read the current worker count
    # @return [Numeric] number of workers
    attr_reader :workers

    # Set the number of workers
    # @param [Numeric] n number of workers
    def workers=(n)
      p "Scaling #{type} to #{n}"
      @workers = n
    end
  end
end
