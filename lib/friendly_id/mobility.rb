require "friendly_id"
require "friendly_id/mobility/version"

module FriendlyId
  module Mobility
    class << self
      def setup(model_class)
        model_class.friendly_id_config.use :slugged
      end

      def included(model_class)
        advise_against_untranslated_model(model_class)

        mod = Module.new do
          def friendly
            super.i18n
          end
        end
        model_class.send :extend, mod
      end

      def advise_against_untranslated_model(model)
        field = model.friendly_id_config.query_field
        if !model.respond_to?(:translated_attribute_names) || model.translated_attribute_names.exclude?(field)
          raise "[FriendlyId] You need to translate the '#{field}' field with " \
            "Mobility (add 'translates :#{field}' in your model '#{model.name}')"
        end
      end
      private :advise_against_untranslated_model
    end

    def set_friendly_id(text, locale = nil)
      ::Mobility.with_locale(locale || ::Mobility.locale) do
        set_slug normalize_friendly_id(text)
      end
    end

    def should_generate_new_friendly_id?
      send(friendly_id_config.slug_column).nil?
    end

    include(Module.new do
      def set_slug(normalized_slug = nil)
        super
        changed.each do |change|
          if change =~ /\A#{friendly_id_config.base}_([a-z]{2}(_[a-z]{2})?)/
            locale, suffix = $1.split('_'.freeze)
            locale = "#{locale}-#{suffix.upcase}".freeze if suffix
            ::Mobility.with_locale(locale) { super }
          end
        end
      end
    end)
  end
end