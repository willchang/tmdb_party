module TMDBParty
  module Attributes
    # based on http://github.com/nullstyle/ruby-satisfaction
    
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        include InstanceMethods
        attr_reader :attributes
      end
    end

    module ClassMethods
      def attributes(*names)
        options = names.extract_options!

        names.each do |name|
          attribute name, options unless name.blank?
        end
      end

      def attribute(name, options)
        options = {:type => 'nil', :lazy => false}.merge(options)
        raise ArgumentError, "Name can't be empty" if name.blank?
        
        class_eval <<-EVAL
          def #{name}
            get_or_load_attribute('#{name}', #{options[:type]}, #{options[:lazy].inspect})
          end
        EVAL
      end

    end

    module InstanceMethods
      def attributes=(value)
        @attributes = value
      end
      
      def loaded?
        @loaded
      end

      private
        def get_or_load_attribute(name, type, lazy_method)
          if lazy_method.is_a?(Symbol) and raw_attribute_missing?(name) and not loaded?
            self.send(lazy_method)
          end
          @attributes_cache ||= {}
          @attributes_cache[name] ||= decode_raw_attribute(@attributes[name], type) if @attributes
        end
        
        def raw_attribute_missing?(name)
          not @attributes.has_key?(name.to_s)
        end
        
        def decode_raw_attribute(value, type)
          return nil unless value
          type.respond_to?(:parse) ? type.parse(value) : value
        end
        
    end
  end
end