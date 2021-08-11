# frozen_string_literal: true


module Jekyll

  class Tree
    attr_reader :root

    def initialize(root_doc, md_docs)
      @root = Node.new('root', root_doc.data['id'], root_doc.data['title'], root_doc.url, root_doc)

      md_docs.each do |cur_doc|
        if !cur_doc.data['slug'].nil? and cur_doc.data['slug'] != 'root'
          self.add_path(cur_doc)
        end
      end

      # print_tree(root)
    end

    # add unique path for the given doc to tree (node-class).
    def add_path(doc, node=nil, depth=1)
      node = @root if depth == 1
      Jekyll.logger.error("Incorrect node in tree.add_path") if node == nil
      chunked_namespace = doc.data['slug'].split(/\s|\./)
      # handle doc if the given node was not root and we are at depth
      if depth == chunked_namespace.length
        cur_nd_namespace = 'root' + '.' + doc.data['slug']
        cur_nd_id = doc.data['id']
        cur_nd_title = doc.data['title']
        cur_nd_url = doc.url
        # create node if one does not exist
        unless node.children.any?{ |c| c.namespace == cur_nd_namespace }
          new_node = Node.new(cur_nd_namespace, cur_nd_id, cur_nd_title, cur_nd_url, doc)
          node.children << new_node
        # fill-in node if one already exists
        else
          cur_node = node.children.detect {|c| c.namespace == cur_nd_namespace }
          cur_node.fill(cur_nd_id, cur_nd_title, cur_nd_url, doc)
        end
        return
      # create temp node and recurse
      else
        cur_namespace = 'root' + '.' + chunked_namespace[0..(depth - 1)].join('.')
        unless node.children.any?{ |c| c.namespace == cur_namespace }
          new_node = Node.new(cur_namespace)
          node.children << new_node
        else
          new_node = node.children.detect {|c| c.namespace == cur_namespace }
        end
      end
      self.add_path(doc, new_node, depth + 1)
    end

    # find the parent and children of the 'target_doc'.
    # ('node' as in the current node, which first is root.)
    def find_doc_immediate_relatives(target_doc, node=nil, ancestors=[])
      node = @root if ancestors == []
      Jekyll.logger.error("Incorrect node in tree.find_doc_immediate_relatives") if node == nil
      if target_doc == node.doc
        children = []
        node.children.each do |child|
          if !child.doc.is_a?(Jekyll::Document)
            children << child.namespace
          else
            children << child.doc.url
          end
        end
        return ancestors, children
      else
        if !node.doc.is_a?(Jekyll::Document)
          ancestors << node.namespace
        else
          ancestors << node.doc.url
        end
        results = []
        node.children.each do |child_node|
          results.concat self.find_doc_immediate_relatives(target_doc, child_node, ancestors.clone)
        end
        return results.select { |r| !r.nil? }
      end
    end

    # ...for debugging
    def print_tree(node, ancestors=[])
      Jekyll.logger.warn "Ancestors: ", ancestors.length
      Jekyll.logger.warn node
      Jekyll.logger.warn "Children: ", node.children
      ancestors.append(node.id)
      node.children.each do |child_node|
        self.print_tree(child_node, ancestors.clone)
      end
    end
  end

  class Node
    attr_accessor :namespace, :id, :title, :children, :url, :doc

    def initialize(namespace, id="", title="", url="", doc="")
      # mandatory
      @namespace = namespace
      # optional
      @id = id.to_s
      @title = title
      @url = url.nil? ? "" : url
      @doc = doc
      # auto-init
      @children = []
    end

    def fill(id, title, url, doc)
      @id = id
      @title = title
      @url = url
      @doc = doc
    end

    def type
      return @doc.type
    end

    def to_s
      "namespace: #{@namespace}"
    end
  end

end
