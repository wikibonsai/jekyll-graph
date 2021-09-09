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
    # TODO: this tag is actually not being used right now --
    #       but it's still here in case it is desirable to
    #       allow users to access each graph via their own
    #       div and skip scripting entirely

      # Use Jekyll's native relative_url filter
      include Jekyll::Filters::URLFilters

      def render(context)
        @context = context
        "<script type=\"module\" src=\"#{$graph_conf.baseurl}#{$graph_conf.path_scripts}/jekyll-graph.js\" /></script>"
      end
    end

  end
end
