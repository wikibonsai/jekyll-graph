# frozen_string_literal: true
require "jekyll"

module Jekyll
  module Graph

    class PluginConfig
      CONFIG_KEY = "graph"
      ENABLED_KEY = "enabled"
      EXCLUDE_KEY = "exclude"
      PATH_ASSETS_KEY = "assets_path"
      PATH_SCRIPTS_KEY = "scripts_path"
      TYPE_KEY = "type"
      TYPE_NET_WEB = "net_web"
      TYPE_TREE = "tree"

      def initialize(config)
        @config ||= config
        @testing ||= config['testing'] if config.keys.include?('testing')
        Jekyll.logger.debug("Excluded jekyll types in graph: ", option(EXCLUDE_KEY)) unless disabled?
      end

      # options

      def disabled?
        return option(ENABLED_KEY) == false
      end

      def disabled_type_net_web?
        return option_type(TYPE_NET_WEB) == false
      end

      def disabled_type_tree?
        return option_type(TYPE_TREE) == false
      end

      def excluded?(type)
        return false unless option(EXCLUDE_KEY)
        return option(EXCLUDE_KEY).include?(type.to_s)
      end

      def has_custom_write_path?
        return !!option(PATH_ASSETS_KEY)
      end

      def has_custom_scripts_path?
        return !!option(PATH_SCRIPTS_KEY)
      end

      def option(key)
        @config[CONFIG_KEY] && @config[CONFIG_KEY][key]
      end

      def option_type(type)
        @config[CONFIG_KEY] && @config[CONFIG_KEY][TYPE_KEY] && @config[CONFIG_KEY][TYPE_KEY][type]
      end

      # attrs

      def baseurl
        return @config['baseurl']
      end

      def path_assets
        return has_custom_write_path? ? option(PATH_ASSETS_KEY) : "/assets"
      end

      def path_scripts
        return has_custom_scripts_path? ? option(PATH_SCRIPTS_KEY) : File.join(path_assets, "js")
      end

      def testing
        return @testing
      end
    end

  end
end
