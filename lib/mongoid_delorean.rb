require 'mongoid'

require "mongoid/delorean/version"
require "mongoid/delorean/configuration"
require "mongoid/delorean/history"
require "mongoid/delorean/trackable"

module Mongoid
  module Delorean

    def self.config(&block)
      @config ||= Configuration.new
      yield @config if block_given?
      return @config
    end
    
  end
end
