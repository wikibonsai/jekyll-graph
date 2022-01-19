# frozen_string_literal: true
require "jekyll"

module Jekyll
  module Graph

    class PageWithoutAFile < Page
      # rubocop:disable Naming/MemoizedInstanceVariableName
      def read_yaml(*)
        @data ||= {}
      end
      # rubocop:enable Naming/MemoizedInstanceVariableName
    end

  end
end
