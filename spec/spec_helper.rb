# frozen_string_literal: true

require "jekyll-graph"
require "jekyll-namespaces"
require "jekyll-wikilinks"

Jekyll.logger.log_level = :error

RSpec.configure do |config|
  FIXTURES_DIR = File.expand_path("fixtures", __dir__)
  SITE_DIR = File.expand_path("_site", __dir__)

  def fixtures_dir(*files)
    File.join(FIXTURES_DIR, *files)
  end

  def site_dir(*files)
    File.join(SITE_DIR, *files)
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # expected retrieval helpers

  def find_by_title(docs, title)
    docs.find { |d| d.data["title"] == title }
  end

  def find_generated_file(relative_path)
    fixtures_dir(relative_path)
  end

  def find_static_file(relative_path)
    site.static_files.find { |sf| sf.relative_path == relative_path }
  end

  ## graph retrieval helpers

  def static_graph_file_content(type)
    if type == "net-web"
      graph_file = File.read(site_dir("/assets/graph-net-web.json"))
    elsif type == "tree"
      graph_file = File.read(site_dir("/assets/graph-tree.json"))
    else
      Jekyll.logger.error("Invalid graph type #{type}")
    end
    JSON.parse(graph_file)
  end

  # TODO: write better graph data getters

  def get_graph_node(type)
    if type == "net-web"
      graph_file = File.read(site_dir("/assets/graph-net-web.json"))
      JSON.parse(graph_file)["nodes"].find { |n| n["id"] == "/docs_net_web/link/" }
    elsif type == "tree"
      graph_file = File.read(site_dir("/assets/graph-tree.json"))
      JSON.parse(graph_file)["nodes"].find { |n| n["namespace"] == "root.second-level" }
    else
      Jekyll.logger.error("Invalid graph type #{type}")
    end
  end

  def get_graph_link_match_source(type)
    if type == "net-web"
      graph_file = File.read(site_dir("/assets/graph-net-web.json"))
      all_links = JSON.parse(graph_file)["links"]
      target_link = all_links.find_all { |l| l["source"] == "/docs_net_web/link/" && l["target"] == "/docs_net_web/blank.a/" } # link "Untyped Link" -> "Blank A"
      if target_link.size > 1
        raise "Expected only one link with 'source' as \"Base Case A\" note to exist."
      else
        return target_link[0]
      end
    elsif type == "tree"
      graph_file = File.read(site_dir("/assets/graph-tree.json"))
      all_links = JSON.parse(graph_file)["links"]
      target_link = all_links.find_all { |l| l["source"] == "/docs_tree/root/" && l["target"] == "/docs_tree/second-level/" } # link "Root" -> "Second Level"
      if target_link.size > 1
        raise "Expected only one link with 'source' as \"Base Case A\" note to exist."
      else
        return target_link[0]
      end
    else
      Jekyll.logger.error("Invalid graph type #{type}")
    end
  end

  # net-web

  def get_missing_link_graph_node()
    graph_file = File.read(site_dir("/assets/graph-net-web.json"))
    JSON.parse(graph_file)["nodes"].find { |n| n["id"] == "missing.doc" } # "Missing Doc"
  end

  def get_missing_target_graph_link()
    graph_file = File.read(site_dir("/assets/graph-net-web.json"))
    all_links = JSON.parse(graph_file)["links"]
    target_link = all_links.find_all { |l| l["source"] == "/docs_net_web/link.missing-doc/" } # "Missing Doc" link as source
    if target_link.size > 1
      raise "Expected only one link with 'source' as \"Missing Doc\" note to exist."
    else
      return target_link[0]
    end
  end

  # tree

  def get_graph_root()
    graph_file = File.read(site_dir("/assets/graph-tree.json"))
    JSON.parse(graph_file)["nodes"].find { |n| n["namespace"] == "root" } # "Root Level"
  end

  def get_missing_graph_node()
    graph_file = File.read(site_dir("/assets/graph-tree.json"))
    JSON.parse(graph_file)["nodes"].find { |n| n["namespace"] == "root.blank" } # "Blank"
  end


  # comments from: https://github.com/jekyll/jekyll-mentions/blob/master/spec/spec_helper.rb

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # comments from: https://github.com/jekyll/jekyll-mentions/blob/master/spec/spec_helper.rb

  # These two settings work together to allow you to limit a spec run
  # to individual examples or groups you care about by tagging them with
  # `:focus` metadata. When nothing is tagged with `:focus`, all examples
  # get run.
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  # Limits the available syntax to the non-monkey patched syntax that is recommended.
  # For more details, see:
  #   - http://myronmars.to/n/dev-blog/2012/06/rspecs-new-expectation-syntax
  #   - http://teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   - http://myronmars.to/n/dev-blog/2014/05/notable-changes-in-rspec-3#new__config_option_to_disable_rspeccore_monkey_patching
  config.disable_monkey_patching!

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed
end
