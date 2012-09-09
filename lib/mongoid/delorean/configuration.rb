module Mongoid
  module Delorean
    class Configuration
      attr_accessor :track_history

      def initialize
        self.track_history = true
      end

    end
  end
end