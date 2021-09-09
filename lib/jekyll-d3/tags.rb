# frozen_string_literal: true

module Jekyll
  module D3

    # from: https://github.com/jekyll/jekyll-feed/blob/6d4913fe5017c685d2437f328ab4a9138cea07a8/lib/jekyll-feed/meta-tag.rb
    class GraphScriptTag < Liquid::Tag
      # Use Jekyll's native relative_url filter
      include Jekyll::Filters::URLFilters

      def render(context)
        @context = context
        attrs    = attributes.map do |k, v|
          v = v.to_s unless v.respond_to?(:encode)
          %(#{k}=#{v.encode(:xml => :attr)})
        end
        "<script #{attrs.join(" ")} /><script src=\"//unpkg.com/element-resize-detector/dist/element-resize-detector.min.js\"></script><script src=\"//unpkg.com/force-graph\"></script>"
      end

      private

      def config
        @config ||= @context.registers[:site].config
      end

      def attributes
        {
          :src  => absolute_url(path),
        }.keep_if { |_, v| v }
      end

      def path
        "jekyll-graph.js"
      end
    end

  end
end
