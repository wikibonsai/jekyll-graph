# frozen_string_literal: true
require "jekyll"

require_relative "jekyll-d3/context"
require_relative "jekyll-d3/tree"
require_relative "jekyll-d3/version"

module Jekyll
  module D3

    class Generator < Jekyll::Generator
      priority :lowest

      attr_accessor :site, :config

      # Use Jekyll's native relative_url filter
      include Jekyll::Filters::URLFilters

      CONVERTER_CLASS = Jekyll::Converters::Markdown
      # config
      GRAPH_DATA_KEY = "d3_graph_data"
      ENABLED_GRAPH_DATA_KEY = "enabled"
      EXCLUDE_GRAPH_KEY = "exclude"
      GRAPH_ASSETS_LOCATION_KEY = "path"

      def initialize(config)
        @config ||= config
        @testing ||= config['testing'] if config.keys.include?('testing')
      end

      def generate(site)
        return if disabled_graph_data?

        # setup site
        @site = site
        @context ||= Context.new(site)

        # setup markdown docs
        docs = []
        docs += @site.pages if !excluded_in_graph?(:pages)
        docs += @site.docs_to_write.filter { |d| !excluded_in_graph?(d.type) }
        @md_docs = docs.filter { |doc| markdown_extension?(doc.extname) }

        # tree setup
        @root_doc = @md_docs.detect { |doc| doc.basename == 'root.md' }
        @tree = Tree.new(@root_doc, @md_docs)

        # graph
        ## tree
        # @tree = Jekyll::Namespaces::Tree
        self.write_graph_tree()
      end

      # config helpers

      def disabled_graph_data?
        option_graph(ENABLED_GRAPH_DATA_KEY) == false
      end

      def excluded_in_graph?(type)
        return false unless option_graph(EXCLUDE_GRAPH_KEY)
        return option_graph(EXCLUDE_GRAPH_KEY).include?(type.to_s)
      end

      def has_custom_assets_path?
        return !!option_graph(GRAPH_ASSETS_LOCATION_KEY)
      end

      def markdown_extension?(extension)
        markdown_converter.matches(extension)
      end

      def markdown_converter
        @markdown_converter ||= @site.find_converter_instance(CONVERTER_CLASS)
      end

      def option_graph(key)
        @config[GRAPH_DATA_KEY] && @config[GRAPH_DATA_KEY][key]
      end

      def generate_json_tree(node)
        json_node = {}
        if !node.doc.is_a?(Jekyll::Document)
          Jekyll.logger.warn("Document for tree node missing: ", node.namespace)
          label = node.namespace.match('([^.]*$)')[0].gsub('-', ' ')
          doc_url = ''
        else
          label = node.title
          doc_url = relative_url(node.url)
        end
        json_children = []
        node.children.each do |child|
          children = self.generate_json_tree(child)
          json_children.append(children)
        end
        json_node = {
          # "id": doc.id,
          "id": doc_url,
          "namespace": node.namespace,
          "label": label,
          "children": json_children,
          "url": doc_url,
        }
        return json_node
      end

      def write_graph_tree()
        assets_path = has_custom_assets_path? ? option_graph(GRAPH_ASSETS_LOCATION_KEY) : "/assets"
        if !File.directory?(File.join(site.source, assets_path))
          Jekyll.logger.error "Assets location does not exist, please create required directories for path: ", assets_path
        end
        # from: https://github.com/jekyll/jekyll/issues/7195#issuecomment-415696200
        static_file = Jekyll::StaticFile.new(site, site.source, assets_path, "graph-tree.json")
        json_tree = self.generate_json_tree(@tree.root)
        File.write(@site.source + static_file.relative_path, JSON.dump(
          json_tree
        ))
        # tests fail without manually adding the static file, but actual site builds seem to do ok
        # ...although there does seem to be a race condition which causes a rebuild to be necessary in order to detect the graph data file
        if @testing
          @site.static_files << static_file if !@site.static_files.include?(static_file)
        end
      end
    end

  end
end
