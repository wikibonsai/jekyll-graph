# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Jekyll::Graph::Generator) do
  let(:config) do
    Jekyll.configuration(
      config_overrides.merge(
        "collections"          => { "docs_net_web" => { "output" => true } },
        "permalink"            => "pretty",
        "skip_config_files"    => false,
        "source"               => fixtures_dir,
        "destination"          => site_dir,
        "url"                  => "garden.testsite.com",
        "testing"              => true,
        # "baseurl"              => "",
        "namespaces"           => { "enabled" => false },
      )
    )
  end
                                        # set configs to only test the net-web graph
  let(:config_overrides)                { {
                                           "wikilinks" => { "exclude" => [ "docs_tree" ] },
                                           "graph" => { "tree" => { "enabled" => false } },
                                        } }
  let(:site)                            { Jekyll::Site.new(config) }

  let(:untyped_link_doc)                { find_by_title(site.collections["docs_net_web"].docs, "Untyped Link") }
  let(:blank_a)                         { find_by_title(site.collections["docs_net_web"].docs, "Base Case A") }
  let(:missing_doc)                     { find_by_title(site.collections["docs_net_web"].docs, "Untyped Link Missing Doc") }

  let(:graph_data)                      { static_graph_file_content("net-web") }
  let(:graph_generated_fpath)           { find_generated_file("/assets/graph-net-web.json") }
  let(:graph_node)                      { get_graph_node("net-web") }
  let(:graph_link)                      { get_graph_link_match_source("net-web") }
  let(:missing_link_graph_node)         { get_missing_link_graph_node() }
  let(:missing_target_graph_link)       { get_missing_target_graph_link() }

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

  context "GRAPH TYPE: NET-WEB" do

    context "dependencies" do

      context "require site object has 'link_index' attribute (because jekyll-wikilinks was not enabled/installed)" do
        let(:config_overrides) { { "wikilinks" => { "enabled" => false } } }
        pending("todo: this is hard to test because i need to somehow mock the lack of plugin installation")

        # it "throw error if jekyll-wikilinks' 'link_index' is missing" do
        #   expect { Jekyll.logger.error }.to raise_error
        # end

      end

    end

    context "when target [[wikilink]] doc exists" do

      it "generates graph data" do
        expect(graph_generated_fpath).to eq(File.join(site_dir, "/assets/graph-net-web.json"))
        expect(graph_data.class).to be(Hash)
      end

      context "node" do

        it "keys include 'id' 'url' 'label'" do
          expect(graph_node.keys).to include("id")
          expect(graph_node.keys).to include("url")
          expect(graph_node.keys).to include("label")
        end

        it "'id' equals their url (since urls should be unique)" do
          expect(graph_node["id"]).to eq(graph_node["url"])
        end

        it "'label' equals their doc title" do
          expect(graph_node["label"]).to eq(untyped_link_doc.data["title"])
        end

        it "'url's equal their doc urls" do
          expect(graph_node["url"]).to eq(untyped_link_doc.url)
        end

        it "'neighbors' is an object with keys 'nodes' and 'links'" do
          expect(graph_node["neighbors"]).to be_a(Object)
          expect(graph_node["neighbors"].keys).to eq(["nodes", "links"])
        end

        it "'neighbors' 'node' is an id" do
          expect(graph_node["neighbors"]["nodes"]).to be_a(Array)
          expect(graph_node["neighbors"]["nodes"]).to eq([
            "/docs_net_web/blank.a/",
          ])
        end

        it "'neighbors' 'link' is an object with 'source' and 'target', which are node ids" do
          expect(graph_node["neighbors"]["links"]).to be_a(Array)
          expect(graph_node["neighbors"]["links"]).to eq([
            {"source"=>"/docs_net_web/link/", "target"=>"/docs_net_web/blank.a/"},
          ])
        end

      end

      context "link" do

        it "contains keys 'source' and 'target'" do
          expect(graph_link.keys).to eq(["source", "target"])
        end

        it "'source' and 'target' attributes equal some nodes' id" do
          expect(graph_link["source"]).to eq(graph_node["id"])
          expect(graph_link["target"]).to eq("/docs_net_web/blank.a/")
        end

      end

    end

    context "when target [[wikilink]] doc does not exist" do

      it "generates graph data" do
        expect(graph_generated_fpath).to eq(File.join(site_dir, "/assets/graph-net-web.json"))
        expect(graph_data.class).to be(Hash)
      end

      context "node" do

        it "keys include 'id', 'url', and 'label'" do
          expect(missing_link_graph_node.keys).to include("id")
          expect(missing_link_graph_node.keys).to include("url")
          expect(missing_link_graph_node.keys).to include("label")
        end

        it "'id's equal the original [[wikitext]]" do
          expect(missing_link_graph_node["id"]).to eq("missing.doc")
        end

        it "'label's equal the original [[wikitext]]" do
          expect(missing_link_graph_node["label"]).to eq("missing.doc")
        end

        it "'url's are empty strings" do
          expect(missing_link_graph_node["url"]).to eq("")
        end

      end

      context "link" do

        it "contains keys 'source' and 'target'" do
          expect(missing_target_graph_link.keys).to eq(["source", "target"])
        end

        it "missing 'target' equals the [[wikitext]] in brackets." do
          expect(missing_target_graph_link["target"]).to eq("missing.doc")
        end

      end

    end

  end

end
