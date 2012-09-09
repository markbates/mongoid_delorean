module Mongoid
  module Delorean
    class History

      include Mongoid::Document
      include Mongoid::Timestamps

      field :original_class, type: String
      field :original_class_id, type: String
      field :version, type: Integer, default: 0
      field :altered_attributes, type: Hash, default: {}
      field :full_attributes, type: Hash, default: {}

    end
  end
end