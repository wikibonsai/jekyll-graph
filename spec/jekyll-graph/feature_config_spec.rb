# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Jekyll::Graph::Generator) do
  let(:config) do
    Jekyll.configuration(
      config_overrides.merge(
        "collections"          => { 
          "docs_net_web" => { "output" => true }, 
          "docs_tree"    => { "output" => true },
        },
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

  # let(:config_overrides)                { { } }
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
    # cleanup _site/ dir
    FileUtils.rm_rf(Dir["#{site_dir()}"])
  end

  context "CONFIG" do

    context "when disabled" do
      let(:config_overrides) { { "graph" => { "enabled" => false } } }

      it "does not generate graph data" do
        # net-web
        expect { File.read("#{site_dir("/assets/graph-net-web.json")}") }.to raise_error(Errno::ENOENT)
        expect { File.read("#{site_dir("/assets/graph-net-web.json")}") }.to raise_error(Errno::ENOENT)
        # tree
        expect { File.read("#{site_dir("/assets/graph-tree.json")}") }.to raise_error(Errno::ENOENT)
        expect { File.read("#{site_dir("/assets/graph-tree.json")}") }.to raise_error(Errno::ENOENT)
      end

    end

    context "when certain jekyll types are excluded" do
      let(:config_overrides) { {
                                "graph" => { "exclude" => [ "pages", "posts" ] }
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
                                "graph" => { 
                                  "path" => {
                                    "assets" => "/custom_assets_path"
                                  }
                                }
                             } }

      it "writes graph file to custom location" do
        # net-web
        expect(file_generated?("/custom_assets_path/graph-net-web.json")).to eq(true)
        # tree
        expect(file_generated?("/custom_assets_path/graph-tree.json")).to eq(true)
        # scripts
        expect(file_generated?("/custom_assets_path/js/jekyll-graph.js")).to eq(true)
      end

    end

    context "when scripts location is set" do
      let(:config_overrides) { {
                                "graph" => { 
                                  "path" => { 
                                    "scripts" => "/custom_scripts_path" 
                                  }
                                }
                             } }

      it "writes graph file to custom location" do
        # net-web
        expect(file_generated?("/assets/graph-net-web.json")).to eq(true)
        # tree
        expect(file_generated?("/assets/graph-tree.json")).to eq(true)
        # scripts
        expect(file_generated?("/assets/custom_scripts_path/jekyll-graph.js")).to eq(true)
      end

    end


  end

end
