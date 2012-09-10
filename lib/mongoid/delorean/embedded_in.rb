require "mongoid/relations/embedded/in"

module Mongoid
  module Relations
    module Macros
      module ClassMethods
        alias :embedded_in_without_history :embedded_in
        def embedded_in(*args)
          relation = embedded_in_without_history(*args)
          self.send(:include, Mongoid::Delorean::Trackable::CommonInstanceMethods)
          self.send(:include, Mongoid::Delorean::Trackable::CommonEmbeddedMethods)
          self.before_save :save_version
          return relation
        end
      end
    end
  end
end