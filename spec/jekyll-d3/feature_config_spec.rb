# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Jekyll::D3::Generator) do
  let(:config) do
    Jekyll.configuration(
      config_overrides.merge(
        "collections"          => { "docs_net_web" => { "output" => true }, "docs_tree" => { "output" => true } },
        "permalink"            => "pretty",
        "skip_config_files"    => false,
        "source"               => fixtures_dir,
        "destination"          => site_dir,
        "url"                  => "garden.testsite.com",
        "testing"              => true,
        # "baseurl"              => "",
      )
    )
  end

  let(:config_overrides)                { { } }
  let(:site)                            { Jekyll::Site.new(config) }

  let(:net_web_graph_data)              { static_graph_file_content("net-web") }
  let(:tree_web_graph_data)             { static_graph_file_content("tree") }

  # makes markdown tests work
  subject { described_class.new(site.config) }

  before(:each) do
    site.reset
    site.process
  end

  after(:each) do
    # cleanup generated assets
    FileUtils.rm_rf(Dir["#{fixtures_dir("/assets/graph-net-web.json")}"])
    FileUtils.rm_rf(Dir["#{fixtures_dir("/assets/graph-tree.json")}"])
    FileUtils.rm_rf(Dir["#{fixtures_dir("/assets/js/jekyll-graph.js")}"])
    # cleanup _site/ dir
    FileUtils.rm_rf(Dir["#{site_dir()}"])
  end

  context "CONFIG" do

    context "when disabled" do
      let(:config_overrides) { { "d3" => { "enabled" => false } } }

      it "does not generate graph data" do
        # net-web
        expect { File.read("#{fixtures_dir("/assets/graph-net-web.json")}") }.to raise_error(Errno::ENOENT)
        expect { File.read("#{site_dir("/assets/graph-net-web.json")}") }.to raise_error(Errno::ENOENT)
        # tree
        expect { File.read("#{fixtures_dir("/assets/graph-tree.json")}") }.to raise_error(Errno::ENOENT)
        expect { File.read("#{site_dir("/assets/graph-tree.json")}") }.to raise_error(Errno::ENOENT)
      end

    end

    context "when certain jekyll types are excluded" do
      let(:config_overrides) { {
                                "d3" => { "exclude" => [ "pages", "posts" ] }
                             } }

      it "does not generate graph data for those jekyll types" do
        # net-web
        expect(net_web_graph_data["nodes"].find { |n| n["title"] == "One Page" }).to eql(nil)
        expect(net_web_graph_data["nodes"].find { |n| n["title"] == "One Post" }).to eql(nil)
        expect(net_web_graph_data["links"].find { |n| n["source"] == "One Page" }).to eql(nil)
        expect(net_web_graph_data["links"].find { |n| n["source"] == "One Post" }).to eql(nil)
        # tree
        expect(tree_web_graph_data["nodes"].find { |n| n["title"] == "One Page" }).to eql(nil)
        expect(tree_web_graph_data["nodes"].find { |n| n["title"] == "One Post" }).to eql(nil)
        expect(tree_web_graph_data["links"].find { |n| n["source"] == "One Page" }).to eql(nil)
        expect(tree_web_graph_data["links"].find { |n| n["source"] == "One Post" }).to eql(nil)
      end

    end

    context "when assets location is set" do
      let(:config_overrides) { {
                                "d3" => { "assets_path" => "/custom_assets_path" }
                             } }

      before(:context) do
        assets_path = File.join(fixtures_dir, "custom_assets_path")
        Dir.mkdir(assets_path)
        Dir.mkdir(File.join(assets_path, "js"))
      end

      after(:context) do
        # cleanup generated assets from custom location
        FileUtils.rm_rf(Dir["#{fixtures_dir("/custom_assets_path/graph-net-web.json")}"])
        FileUtils.rm_rf(Dir["#{fixtures_dir("/custom_assets_path/graph-tree.json")}"])
        FileUtils.rm_rf(Dir["#{fixtures_dir("/custom_assets_path/js/jekyll-graph.js")}"])
        FileUtils.rm_rf(Dir["#{fixtures_dir("/custom_assets_path")}"])
      end

      it "writes graph file to custom location" do
        # net-web
        expect(find_generated_file("/custom_assets_path/graph-net-web.json")).to eq(File.join(fixtures_dir, "/custom_assets_path/graph-net-web.json"))
        expect(find_static_file("/custom_assets_path/graph-net-web.json")).to be_a(Jekyll::StaticFile)
        expect(find_static_file("/custom_assets_path/graph-net-web.json").relative_path).to eq("/custom_assets_path/graph-net-web.json")
        # tree
        expect(find_generated_file("/custom_assets_path/graph-tree.json")).to eq(File.join(fixtures_dir, "/custom_assets_path/graph-tree.json"))
        expect(find_static_file("/custom_assets_path/graph-tree.json")).to be_a(Jekyll::StaticFile)
        expect(find_static_file("/custom_assets_path/graph-tree.json").relative_path).to eq("/custom_assets_path/graph-tree.json")
        # scripts
        expect(find_static_file("/custom_assets_path/js/jekyll-graph.js").relative_path).to eq("/custom_assets_path/js/jekyll-graph.js")
      end

    end

  end

end
