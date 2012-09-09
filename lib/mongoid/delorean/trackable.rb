module Mongoid
  module Delorean
    module Trackable

      def self.included(klass)
        super
        klass.field :version, type: Integer, default: 0
        klass.before_save :save_version
      end

      def versions
        Mongoid::Delorean::History.where(original_class: self.class.name, original_class_id: self.id)
      end

      def save_version
        if self.track_history?
          unless self.kind_of?(Mongoid::Delorean::Trackable::CommonInstanceMethods)
            extend Mongoid::Delorean::Trackable::CommonInstanceMethods
          end
          last_version = self.versions.last
          _version = last_version ? last_version.version + 1 : 1

          _attributes = self.attributes_with_relations
          _attributes.merge!("version" => _version)
          _changes = self.changes_with_relations.dup
          _changes.merge!("version" => [self.version_was, _version])

          Mongoid::Delorean::History.create(original_class: self.class.name, original_class_id: self.id, version: _version, altered_attributes: _changes, full_attributes: _attributes).inspect
          self.without_history_tracking do
            self.update_attributes(version: _version)
          end
        end
      end

      def track_history?
        @__track_changes.nil? ? true : @__track_changes
      end

      def without_history_tracking
        @__track_changes = false
        yield
        @__track_changes = true
      end

      def revert!(version = (self.version - 1))
        old_version = self.versions.where(version: version).first
        if old_version
          old_version.full_attributes.each do |key, value|
            self.send("#{key}=", value)
          end
          self.save!
        end
      end

      module CommonInstanceMethods

        def self.extended(klass)
          super
          included(klass)
        end

        def self.included(klass)
          super
          klass.embedded_relations.each do |name, details|
            _klass = Kernel.const_get(details.class_name)
            _klass.send(:include, Mongoid::Delorean::Trackable::CommonInstanceMethods)
            _klass.after_save :save_parent_version
          end
        end

        def save_parent_version
          if self.embedded?
            self._parent.save_parent_version
          else
            self.save_version
          end
        end
        
        def changes_with_relations
          _changes = self.changes.dup

          _changes.delete(:version)
          _changes.delete(:updated_at)
          _changes.delete(:created_at)

          relation_changes = {}
          self.embedded_relations.each do |name, details|
            relation = self.send(name)
            relation_changes[name] = []
            r_changes = relation.map {|o| o.changes_with_relations}
            relation_changes[name] << r_changes unless r_changes.empty?
            relation_changes[name].flatten!
            relation_changes.delete(name) if relation_changes[name].empty?
          end

          _changes.merge!(relation_changes)
          return _changes
        end

        def attributes_with_relations
          _attributes = self.attributes.dup
          
          relation_attrs = {}
          self.embedded_relations.each do |name, details|
            relation = self.send(name)
            relation_attrs[name] = []
            r_attrs = relation.map {|o| o.attributes_with_relations}
            relation_attrs[name] << r_attrs unless r_attrs.empty?
            r_changes = relation.map {|o| o.changes}
            relation_attrs[name].flatten!
          end
          _attributes.merge!(relation_attrs)
          return _attributes
        end

      end

    end
  end
end