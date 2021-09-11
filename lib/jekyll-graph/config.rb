# frozen_string_literal: true
require "jekyll"

module Jekyll
  module Graph

    class PluginConfig
      CONFIG_KEY = "graph"
      ENABLED_KEY = "enabled"
      EXCLUDE_KEY = "exclude"
      NET_WEB_KEY = "net_web"
      PATH_ASSETS_KEY = "assets_path"
      PATH_SCRIPTS_KEY = "scripts_path"
      TREE_KEY = "tree"
      TYPE_KEY = "type"

      def initialize(config)
        @config ||= config
        @testing ||= config['testing'] if config.keys.include?('testing')
        Jekyll.logger.debug("Excluded jekyll types in graph: ", option(EXCLUDE_KEY)) unless disabled?
      end

      # options

      def disabled?
        return option(ENABLED_KEY) == false
      end

      def disabled_net_web?
        return option_net_web(ENABLED_KEY) == false
      end

      def disabled_tree?
        return option_tree(ENABLED_KEY) == false
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

      def option_net_web(key)
        @config[CONFIG_KEY] && @config[CONFIG_KEY][NET_WEB_KEY] && @config[CONFIG_KEY][NET_WEB_KEY][key]
      end

      def option_tree(key)
        @config[CONFIG_KEY] && @config[CONFIG_KEY][TREE_KEY] && @config[CONFIG_KEY][TREE_KEY][key]
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