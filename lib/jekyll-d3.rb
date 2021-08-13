# frozen_string_literal: true
require "jekyll"

require_relative "jekyll-d3/context"
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
      TYPE_KEY = "type"
      TYPE_NET_WEB = "net_web"
      TYPE_TREE = "tree"
      WRITE_GRAPH_PATH_KEY = "path"

      def initialize(config)
        @config ||= config
        @testing ||= config['testing'] if config.keys.include?('testing')
      end

      def generate(site)
        return if disabled_graph_data?
        Jekyll.logger.debug "Excluded jekyll types in graph: ", option_graph(EXCLUDE_GRAPH_KEY)

        # setup site
        @site = site
        @context ||= Context.new(site)

        # setup markdown docs
        docs = []
        docs += @site.pages if !excluded_in_graph?(:pages)
        docs += @site.docs_to_write.filter { |d| !excluded_in_graph?(d.type) }
        @md_docs = docs.filter { |doc| markdown_extension?(doc.extname) }

        # graph

        # setup net-web
        if !disabled_net_web?
          @graph_nodes, @graph_links = [], []
          @md_docs.each do |doc|
            if !self.excluded_in_graph?(doc.type)
              self.generate_json_net_web(doc)
            end
          end
        end

        self.write_graph_data()
      end

      # config helpers

      def disabled_graph_data?
        return option_graph(ENABLED_GRAPH_DATA_KEY) == false
      end

      def disabled_net_web?
        return option_type(TYPE_NET_WEB) == false
      end

      def disabled_tree?
        return option_type(TYPE_TREE) == false
      end

      def excluded_in_graph?(type)
        return false unless option_graph(EXCLUDE_GRAPH_KEY)
        return option_graph(EXCLUDE_GRAPH_KEY).include?(type.to_s)
      end

      def has_custom_assets_path?
        return !!option_graph(WRITE_GRAPH_PATH_KEY)
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

      def option_type(type)
        @config[GRAPH_DATA_KEY] && @config[GRAPH_DATA_KEY][TYPE_KEY] && @config[GRAPH_DATA_KEY][TYPE_KEY][type]
      end

      # helpers

      def generate_json_net_web(doc)
        Jekyll.logger.debug "Processing graph nodes for doc: ", doc.data['title']
        #
        # missing nodes
        #
        @site.link_index.index[doc.url].missing.each do |missing_link_name|
          if @graph_nodes.none? { |node| node[:id] == missing_link_name }
            Jekyll.logger.warn "Net-Web node missing: ", missing_link_name
            Jekyll.logger.warn " in: ", doc.data['slug']
            @graph_nodes << {
              id: missing_link_name, # an id is necessary for link targets
              url: '',
              label: missing_link_name,
            }
            @graph_links << {
              source: relative_url(doc.url),
              target: missing_link_name,
            }
          end
        end
        #
        # existing nodes
        #
        @graph_nodes << {
          # TODO: when using real ids, be sure to convert id to string (to_s)
          id: relative_url(doc.url),
          url: relative_url(doc.url),
          label: doc.data['title'],
        }
        # TODO: this link calculation ends up with duplicates -- re-visit this later.
        all_links = @site.link_index.index[doc.url].attributes + @site.link_index.index[doc.url].forelinks
        if !all_links.nil?
          all_links.each do |link| # link = { 'type' => str, 'doc_url' => str }
            # TODO: Header + Block-level wikilinks
                                                       # remove baseurl and any anchors
            linked_doc = @md_docs.select{ |d| d.url == link['doc_url'].gsub(@site.baseurl, "").match(/([^#]+)/i)[0] }
            if !linked_doc.nil? && linked_doc.size == 1 && !excluded_in_graph?(linked_doc.first.type)
              @graph_links << {
                source: relative_url(doc.url),
                target: relative_url(linked_doc.first.url),
              }
            end
          end
        end
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

      def write_graph_data()
        assets_path = has_custom_assets_path? ? option_graph(WRITE_GRAPH_PATH_KEY) : "/assets"
        if !File.directory?(File.join(@site.source, assets_path))
          Jekyll.logger.error "Assets location does not exist, please create required directories for path: ", assets_path
        end

        if !disabled_net_web?
          # from: https://github.com/jekyll/jekyll/issues/7195#issuecomment-415696200
          # (also this: https://stackoverflow.com/questions/19835729/copying-generated-files-from-a-jekyll-plugin-to-a-site-resource-folder)
          static_file = Jekyll::StaticFile.new(site, @site.source, assets_path, "graph-net-web.json")
          # TODO: make write file location more flexible -- requiring a write location configuration feels messy...
          File.write(@site.source + static_file.relative_path, JSON.dump({
            links: @graph_links,
            nodes: @graph_nodes,
          }))
        end
        if !disabled_tree?
          # from: https://github.com/jekyll/jekyll/issues/7195#issuecomment-415696200
          # (also this: https://stackoverflow.com/questions/19835729/copying-generated-files-from-a-jekyll-plugin-to-a-site-resource-folder)
          static_file = Jekyll::StaticFile.new(site, @site.source, assets_path, "graph-tree.json")
          json_tree = self.generate_json_tree(@site.tree.root)
          File.write(@site.source + static_file.relative_path, JSON.dump(
            json_tree
          ))
        end

        # tests fail without manually adding the static file, but actual site builds seem to do ok
        # ...although there does seem to be a race condition which causes a rebuild to be necessary in order to detect the graph data file
        if @testing
          @site.static_files << static_file if !@site.static_files.include?(static_file)
        end
      end
    end

  end
end
