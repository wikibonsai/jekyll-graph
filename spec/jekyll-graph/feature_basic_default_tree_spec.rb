# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Jekyll::Graph::Generator) do
  let(:config) do
    Jekyll.configuration(
      config_overrides.merge(
        "collections"          => { "docs_tree" => { "output" => true } },
        "permalink"            => "pretty",
        "skip_config_files"    => false,
        "source"               => fixtures_dir,
        "destination"          => site_dir,
        "url"                  => "garden.testsite.com",
        "testing"              => true,
        # "baseurl"              => "",
        "wikilinks"            => { "enabled" => false },
      )
    )
  end
                                        # set configs to only test the tree graph
  let(:config_overrides)                { {
                                          "namespaces" => { "exclude" => [ "docs_net_web" ] },
                                          "graph" => { "net_web" => { "enabled" => false } }
                                        } }
  let(:site)                            { Jekyll::Site.new(config) }

  let(:doc_root)                        { find_by_title(site.collections["docs_tree"].docs, "Root") }
  let(:doc_second_lvl)                  { find_by_title(site.collections["docs_tree"].docs, "Root Second Level") }
  let(:doc_missing_lvl)                 { find_by_title(site.collections["docs_tree"].docs, "Missing Level") }

  let(:graph_data)                      { static_graph_file_content("tree") }
  let(:graph_generated_fpath)           { find_generated_file("/assets/graph-tree.json") }
  let(:graph_root)                      { get_graph_root() }
  let(:graph_link)                      { get_graph_link_match_source("tree") }
  let(:graph_node)                      { get_graph_node("tree") }
  let(:missing_graph_node)              { get_missing_graph_node() }

  # makes markdown tests work
  subject                               { described_class.new(site.config) }

  before(:each) do
    site.reset
    site.process
  end

  after(:each) do
    # cleanup _site/ dir
    FileUtils.rm_rf(Dir["#{site_dir()}"])
  end

  context "GRAPH TYPE: TREE" do

      context "dependencies" do

        context "require site object has 'tree' attribute (because jekyll-namespaces was not enabled/installed)" do
          let(:config_overrides) { { "namespaces" => { "enabled" => false } } }

          it "throw error if jekyll-namespaces' 'tree' is missing" do
            expect { Jekyll.logger.error }.to raise_error(ArgumentError)
          end

        end

      end

    context "when doc for tree.path level exists" do

      it "generates graph data" do
        expect(graph_generated_fpath).to eq(File.join(site_dir, "/assets/graph-tree.json"))
        expect(graph_data.class).to be(Hash)
      end

      context "json node" do

        it "has format: { nodes: [ {id: '', url: '', label: ''}, ... ] }" do
          expect(graph_node.keys).to include("id")
          expect(graph_node.keys).to include("url")
          expect(graph_node.keys).to include("label")
        end

        it "'id's equal their url (since urls should be unique)" do
          expect(graph_root["id"]).to eq(graph_root["url"])
        end

        it "'label's equal their doc title" do
          expect(graph_root["label"]).to eq(doc_root.data["title"])
        end

        it "root 'namespace's equal their doc filename" do
          expect(graph_root["namespace"]).to eq(doc_root.basename_without_ext)
        end

        it "non-root 'namespace's equal their doc filename with the 'root.' prefix" do
          expect(graph_node["namespace"]).to eq("root." + doc_second_lvl.basename_without_ext)
        end

        it "'url's equal their doc urls" do
          expect(graph_root["url"]).to eq(doc_root.url)
        end

        it "'relatives' is an object with keys 'nodes' and 'links'" do
          expect(graph_root["relatives"]).to be_a(Object)
          expect(graph_root["relatives"].keys).to eq(["nodes", "links"])
        end

        it "'relatives' 'node' is an array of 'id's" do
          expect(graph_root["relatives"]["nodes"]).to be_a(Array)
          expect(graph_root["relatives"]["nodes"][0]).to be_a(String)
          expect(graph_root["relatives"]["nodes"]).to eq([
            "/one-page/",
            "/2020/12/08/one-post/",
            "root.blank",
            "/docs_tree/blank.missing-lvl/",
            "/docs_tree/second-level/",
            "/docs_tree/second-level.third-level/",
            "/docs_tree/root/"
          ])
        end

        it "'relatives' 'link' is an array of objects with 'source' and 'target' keys which are node ids" do
          expect(graph_root["relatives"]["links"]).to be_a(Array)
          expect(graph_root["relatives"]["links"][0].keys).to eq(["source", "target"])
          expect(graph_root["relatives"]["links"]).to eq([
            {"source"=>"/docs_tree/root/", "target"=>"/one-page/"},
            {"source"=>"/docs_tree/root/", "target"=>"/2020/12/08/one-post/"},
            {"source"=>"/docs_tree/root/", "target"=>"root.blank"},
            {"source"=>"root.blank", "target"=>"/docs_tree/blank.missing-lvl/"},
            {"source"=>"/docs_tree/root/", "target"=>"/docs_tree/second-level/"},
            {"source"=>"/docs_tree/second-level/", "target"=>"/docs_tree/second-level.third-level/"}
          ])
        end

      end

      context "json link" do

        it "has format: { links: [ { source: '', target: '', label: ''}, ... ] }" do
          expect(graph_link.keys).to include("source")
          expect(graph_link.keys).to include("target")
        end

        it "'source' equals the parent id" do
          expect(graph_link["source"]).to eq(graph_root["id"])
          expect(graph_root["id"]).to eq("/docs_tree/root/")
        end

        it "'target' equals the child id" do
          expect(graph_link["target"]).to eq(graph_node["id"])
          expect(graph_node["id"]).to eq("/docs_tree/second-level/")
        end

      end

    end

    context "when doc for tree.path level does not exist" do

      it "generates graph data" do
        expect(graph_generated_fpath).to eq(File.join(site_dir, "/assets/graph-tree.json"))
        expect(graph_data.class).to be(Hash)
      end

      context "parent of missing node" do

        it "has namespace of missing level in its child metadata" do
          expect(doc_root["children"]).to include("root.blank")
        end

      end

      context "missing node" do

        it "has keys: [ 'id', 'label', 'namespace', and 'url' ]" do
          expect(missing_graph_node.keys).to include("id")
          expect(missing_graph_node.keys).to include("label")
          expect(missing_graph_node.keys).to include("namespace")
          expect(missing_graph_node.keys).to include("url")
        end

        it "'id's equals its namespace" do
          expect(missing_graph_node["id"]).to eq(missing_graph_node["namespace"])
        end

        it "'label' equals the namespace of the missing level" do
          expect(missing_graph_node["label"]).to eq("blank")
        end

        it "'url' is an empty string" do
          expect(missing_graph_node["url"]).to eq("")
        end

      end

    end

  end

end
