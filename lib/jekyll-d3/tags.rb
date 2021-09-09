# frozen_string_literal: true

module Jekyll
  module D3

    class ForceGraphTag < Liquid::Tag
      def render(context)
        [
          "<script src=\"//unpkg.com/element-resize-detector/dist/element-resize-detector.min.js\"></script>",
          "<script src=\"//unpkg.com/force-graph\"></script>",
          "<script src=\"https://d3js.org/d3.v6.min.js\"></script>",
        ].join("\n").gsub!("\n", "") # for long-string legibility
      end
    end

    # from: https://github.com/jekyll/jekyll-feed/blob/6d4913fe5017c685d2437f328ab4a9138cea07a8/lib/jekyll-feed/meta-tag.rb
    class GraphScriptTag < Liquid::Tag

      # Use Jekyll's native relative_url filter
      include Jekyll::Filters::URLFilters

      def render(context)
        @context = context
        "<script type=\"module\" src=\"/jekyll-bonsai/assets/js/jekyll-graph.js\" /></script>"
        # "<script type=\"module\" src=\"#{config.base_url}/#{config.scripts_path}/jekyll-graph.js\" /></script>"
      end

      private

      def config
        @config ||= @context.registers[:site].config
      end
    end

  end
end
