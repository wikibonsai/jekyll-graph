# frozen_string_literal: true
require "jekyll"

require_relative "jekyll-d3/context"
require_relative "jekyll-d3/version"

module Jekyll
  module D3

    class Generator < Jekyll::Generator
      priority :lowest

      # Use Jekyll's native relative_url filter
      include Jekyll::Filters::URLFilters

      CONVERTER_CLASS = Jekyll::Converters::Markdown
      # config
      CONFIG_KEY = "d3"
      ENABLED_KEY = "enabled"
      EXCLUDE_KEY = "exclude"
      TYPE_KEY = "type"
      TYPE_NET_WEB = "net_web"
      TYPE_TREE = "tree"
      WRITE_PATH_KEY = "path"

      def initialize(config)
        @config ||= config
        @testing ||= config['testing'] if config.keys.include?('testing')
      end

      def generate(site)
        return if disabled?
        if !disabled_type_net_web? && site.link_index.nil?
          Jekyll.logger.error("To generate the net-web graph, please add and enable the 'jekyll-wikilinks' plugin")
          return
        end
        if !disabled_type_tree? && site.tree.nil?
          Jekyll.logger.error("To generate the tree graph, please add and enable the 'jekyll-namespaces' plugin")
          return
        end
        Jekyll.logger.debug("Excluded jekyll types in graph: ", option(EXCLUDE_KEY))

        # setup site
        @site = site
        @context ||= Context.new(site)

        # setup markdown docs
        docs = []
        docs += @site.pages if !excluded?(:pages)
        docs += @site.docs_to_write.filter { |d| !excluded?(d.type) }
        @md_docs = docs.filter { |doc| markdown_extension?(doc.extname) }
        if @md_docs.empty?
          Jekyll.logger.debug("No documents to process.")
        end

        # setup assets location
        assets_path = has_custom_write_path? ? option(WRITE_PATH_KEY) : "/assets"
        if !File.directory?(File.join(@site.source, assets_path))
          Jekyll.logger.error "Assets location does not exist, please create required directories for path: ", assets_path
        end

        # write graph
        if !disabled_type_net_web?
          # from: https://github.com/jekyll/jekyll/issues/7195#issuecomment-415696200
          # (also this: https://stackoverflow.com/questions/19835729/copying-generated-files-from-a-jekyll-plugin-to-a-site-resource-folder)
          static_file = Jekyll::StaticFile.new(@site, @site.source, assets_path, "graph-net-web.json")
          json_net_web_nodes, json_net_web_links = self.generate_json_net_web()
          self.set_neighbors(json_net_web_nodes, json_net_web_links)
          # TODO: make write file location more flexible -- requiring a write location configuration feels messy...
          File.write(@site.source + static_file.relative_path, JSON.dump({
            nodes: json_net_web_nodes,
            links: json_net_web_links,
          }))
          self.add_static_file(static_file)
        end
        if !disabled_type_tree?
          # from: https://github.com/jekyll/jekyll/issues/7195#issuecomment-415696200
          # (also this: https://stackoverflow.com/questions/19835729/copying-generated-files-from-a-jekyll-plugin-to-a-site-resource-folder)
          static_file = Jekyll::StaticFile.new(@site, @site.source, assets_path, "graph-tree.json")
          json_tree_nodes, json_tree_links = self.generate_json_tree(@site.tree.root)
          self.set_relatives(json_tree_nodes, json_tree_links)
          File.write(@site.source + static_file.relative_path, JSON.dump(
            nodes: json_tree_nodes,
            links: json_tree_links,
          ))
          self.add_static_file(static_file)
        end
      end

      # config helpers

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
        return !!option(WRITE_PATH_KEY)
      end

      def markdown_extension?(extension)
        markdown_converter.matches(extension)
      end

      def markdown_converter
        @markdown_converter ||= @site.find_converter_instance(CONVERTER_CLASS)
      end

      def option(key)
        @config[CONFIG_KEY] && @config[CONFIG_KEY][key]
      end

      def option_type(type)
        @config[CONFIG_KEY] && @config[CONFIG_KEY][TYPE_KEY] && @config[CONFIG_KEY][TYPE_KEY][type]
      end

      # generator helpers

      def add_static_file(static_file)
        # tests fail without manually adding the static file, but actual site builds seem to do ok
        # ...although there does seem to be a race condition which causes a rebuild to be necessary in order to detect the graph data file
        if @testing
          @site.static_files << static_file if !@site.static_files.include?(static_file)
        end
      end

      # json population helpers

      def set_neighbors(json_nodes, json_links)
        json_links.each do |json_link|
          source_node = json_nodes.detect { |n| n[:id] == json_link[:source] }
          target_node = json_nodes.detect { |n| n[:id] == json_link[:target] }

          source_node[:neighbors][:nodes] << target_node[:id]
          target_node[:neighbors][:nodes] << source_node[:id]

          source_node[:neighbors][:links] << json_link
          target_node[:neighbors][:links] << json_link
        end
      end

      def set_relatives(json_nodes, json_links)
        # TODO: json nodes have relative_url, but node.id's/urls are doc urls.
        json_nodes.each do |json_node|
          ancestor_node_ids, descendent_node_ids = @site.tree.get_all_relative_ids(json_node[:id])
          relative_node_ids = ancestor_node_ids.concat(descendent_node_ids)
          json_node[:relatives][:nodes] = relative_node_ids if !relative_node_ids.nil?

          # include current node when filtering for links along entire relative lineage
          lineage_ids = relative_node_ids.concat([json_node[:id]])

          json_relative_links = json_links.select { |l| lineage_ids.include?(l[:source]) && lineage_ids.include?(l[:target]) }
          json_node[:relatives][:links] = json_relative_links if !json_relative_links.nil?
        end
      end

      # json generation helpers

      def generate_json_net_web()
        net_web_nodes, net_web_links = [], []

        @md_docs.each do |doc|
          if !self.excluded?(doc.type)

            Jekyll.logger.debug "Processing graph nodes for doc: ", doc.data['title']
            #
            # missing nodes
            #
            @site.link_index.index[doc.url].missing.each do |missing_link_name|
              if net_web_nodes.none? { |node| node[:id] == missing_link_name }
                Jekyll.logger.warn "Net-Web node missing: ", missing_link_name
                Jekyll.logger.warn " in: ", doc.data['title']
                net_web_nodes << {
                  id: missing_link_name, # an id is necessary for link targets
                  url: '',
                  label: missing_link_name,
                  neighbors: {
                    nodes: [],
                    links: [],
                  },
                }
                net_web_links << {
                  source: doc.url,
                  target: missing_link_name,
                }
              end
            end
            #
            # existing nodes
            #
            net_web_nodes << {
              # TODO: when using real ids, be sure to convert id to string (to_s)
              id: doc.url,
              url: relative_url(doc.url),
              label: doc.data['title'],
              neighbors: {
                nodes: [],
                links: [],
              },
            }
            # TODO: this link calculation ends up with duplicates -- re-visit this later.
            @site.link_index.index[doc.url].attributes.each do |link| # link = { 'type' => str, 'urls' => [str, str, ...] }
              # TODO: Header + Block-level wikilinks
              link['urls'].each do |lu|
                link_no_anchor = lu.match(/([^#]+)/i)[0]
                link_no_baseurl = @site.baseurl.nil? ? link_no_anchor : link_no_anchor.gsub(@site.baseurl, "")
                linked_doc = @md_docs.select{ |d| d.url == link_no_baseurl }
                if !linked_doc.nil? && linked_doc.size == 1 && !excluded?(linked_doc.first.type)
                  # TODO: add link['type'] to d3 graph
                  net_web_links << {
                    source: doc.url,
                    target: linked_doc.first.url,
                  }
                end
              end
            end
            @site.link_index.index[doc.url].forelinks.each do |link| # link = { 'type' => str, 'url' => str }
              # TODO: Header + Block-level wikilinks
              link_no_anchor = link['url'].match(/([^#]+)/i)[0]
              link_no_baseurl = @site.baseurl.nil? ? link_no_anchor : link_no_anchor.gsub(@site.baseurl, "")
              linked_doc = @md_docs.select{ |d| d.url == link_no_baseurl }
              if !linked_doc.nil? && linked_doc.size == 1 && !excluded?(linked_doc.first.type)
                # TODO: add link['type'] to d3 graph
                net_web_links << {
                  source: doc.url,
                  target: linked_doc.first.url,
                }
              end
            end

          end
        end

        return net_web_nodes, net_web_links
      end

      def generate_json_tree(node, json_parent="", tree_nodes=[], tree_links=[])
        #
        # missing nodes
        #
        if !node.doc.is_a?(Jekyll::Document)
          Jekyll.logger.warn("Document for tree node missing: ", node.namespace)

          leaf = node.namespace.split('.').pop()
          missing_node = {
            id: node.namespace,
            label: leaf.gsub('-', ' '),
            namespace: node.namespace,
            url: "",
            relatives: {
              nodes: [],
              links: [],
            },
          }
          tree_nodes << missing_node
          if !json_parent.empty?
            tree_links << {
              source: json_parent[:id],
              target: node.namespace,
            }
          end
          json_parent = missing_node
        #
        # existing nodes
        #
        else
          existing_node = {
            id: node.url,
            label: node.title,
            namespace: node.namespace,
            url: relative_url(node.url),
            relatives: {
              nodes: [],
              links: [],
            },
          }
          tree_nodes << existing_node
          if !json_parent.empty?
            tree_links << {
              source: json_parent[:id],
              target: node.url,
            }
          end
          json_parent = existing_node
        end
        node.children.each do |child|
          self.generate_json_tree(child, json_parent, tree_nodes, tree_links)
        end
        return tree_nodes, tree_links
      end
    end

  end
end
