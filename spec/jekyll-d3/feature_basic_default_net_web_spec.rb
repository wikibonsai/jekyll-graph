# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Jekyll::D3::Generator) do
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
                                           "d3" => { "type" => { "tree" => false } },
                                        } }
  let(:site)                            { Jekyll::Site.new(config) }

  let(:base_case_a)                     { find_by_title(site.collections["docs_net_web"].docs, "Base Case A") }
  let(:missing_doc)                     { find_by_title(site.collections["docs_net_web"].docs, "Missing Doc") }

  let(:graph_data)                      { static_graph_file_content("net-web") }
  let(:graph_generated_fpath)           { find_generated_file("/assets/graph-net-web.json") }
  let(:graph_static_file)               { find_static_file("/assets/graph-net-web.json") }
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
    # cleanup generated assets
    FileUtils.rm_rf(Dir["#{fixtures_dir("/assets/graph-net-web.json")}"])
    # cleanup _site/ dir
    FileUtils.rm_rf(Dir["#{site_dir()}"])
  end

  context "net-web" do

    context "dependencies" do

      context "if 'link_index' was not appended to site object (because jekyll-wikilinks was not enabled/installed)" do
        let(:config_overrides) { { "wikilinks" => { "enabled" => false } } }

        it "display a jekyll warning to notify user of jekyll-wikilinks dependency" do
          expect { Jekyll.logger.error }.to raise_error(ArgumentError)
        end

      end

    end

    context "config" do

      context "when disabled" do
        let(:config_overrides) { { "d3" => { "enabled" => false } } }

        it "does not generate graph data" do
          expect { File.read("#{fixtures_dir("/assets/graph-net-web.json")}") }.to raise_error(Errno::ENOENT)
          expect { File.read("#{site_dir("/assets/graph-net-web.json")}") }.to raise_error(Errno::ENOENT)
        end

      end

      context "when certain jekyll types are excluded" do
        let(:config_overrides) { {
                                  "wikilinks" => { "exclude" => [ "docs_tree" ] },
                                  "d3" => { "type" => { "tree" => false }, "exclude" => [ "pages", "posts" ] }
                               } }

        it "does not generate graph data for those jekyll types" do
          expect(graph_data["nodes"].find { |n| n["title"] == "One Page" }).to eql(nil)
          expect(graph_data["nodes"].find { |n| n["title"] == "One Post" }).to eql(nil)

          expect(graph_data["links"].find { |n| n["source"] == "One Page" }).to eql(nil)
          expect(graph_data["links"].find { |n| n["source"] == "One Post" }).to eql(nil)
        end

      end

      context "when assets location is set" do
        let(:config_overrides) { {
                                  "wikilinks" => { "exclude" => [ "docs_tree" ] },
                                  "d3" => { "type" => { "tree" => false }, "path" => "/custom_assets_path" }
                               } }

        before(:context) do
          assets_path = File.join(fixtures_dir, "custom_assets_path")
          Dir.mkdir(assets_path)
        end

        after(:context) do
          # cleanup generated assets
          FileUtils.rm_rf(Dir["#{fixtures_dir("/custom_assets_path/graph-net-web.json")}"])
          FileUtils.rm_rf(Dir["#{fixtures_dir("/custom_assets_path")}"])
        end

        it "writes graph file to custom location" do
          expect(find_generated_file("/custom_assets_path/graph-net-web.json")).to eq(File.join(fixtures_dir, "/custom_assets_path/graph-net-web.json"))
          expect(find_static_file("/custom_assets_path/graph-net-web.json")).to be_a(Jekyll::StaticFile)
          expect(find_static_file("/custom_assets_path/graph-net-web.json").relative_path).to eq"/custom_assets_path/graph-net-web.json"
        end
      end

    end

    context "default behavior" do

      it "generates graph data" do
        expect(graph_generated_fpath).to eq(File.join(fixtures_dir, "/assets/graph-net-web.json"))
        expect(graph_static_file).to be_a(Jekyll::StaticFile)
        expect(graph_static_file.relative_path).not_to be(nil)
        expect(graph_data.class).to be(Hash)
      end

      context "when target [[wikilink]] doc exists" do

        context "node" do

          it "keys include 'id' 'url' 'label'" do
            expect(graph_node.keys).to include("id")
            expect(graph_node.keys).to include("url")
            expect(graph_node.keys).to include("label")
          end

          it "'id' equals their url (since urls should be unique)" do
            expect(graph_node["id"]).to eq(graph_node["url"])
          end

          it "'label' equal their doc title" do
            expect(graph_node["label"]).to eq(base_case_a.data["title"])
          end

          it "'url's equal their doc urls" do
            expect(graph_node["url"]).to eq(base_case_a.url)
          end
        end

        context "link" do

          it "contains keys 'source' and 'target'" do
            expect(graph_link.keys).to eq(["source", "target"])
          end

          it "'source' and 'target' attributes equal some nodes' id" do
            expect(graph_link["source"]).to eq(graph_node["id"])
            expect(graph_link["target"]).to eq("/doc/e0c824b6-0b8c-4595-8032-b6889edd815f/")
          end

        end

      end

      context "when target [[wikilink]] doc does not exist" do

        context "node" do

          it "keys include 'id', 'url', and 'label'" do
            expect(missing_link_graph_node.keys).to include("id")
            expect(missing_link_graph_node.keys).to include("url")
            expect(missing_link_graph_node.keys).to include("label")
          end

          it "'id's equal their url (since urls should be unique)" do
            expect(missing_link_graph_node["id"]).to eq(missing_link_graph_node["url"])
          end

          it "'label's equal their doc title" do
            expect(missing_link_graph_node["label"]).to eq(missing_doc.data["title"])
          end

          it "'url's equal their doc urls" do
            expect(missing_link_graph_node["url"]).to eq(missing_doc.url)
          end

        end

        context "link" do

          it "contains keys 'source' and 'target'" do
            expect(missing_target_graph_link.keys).to eq(["source", "target"])
          end

          it "missing 'target' equals the [[wikitext]] in brackets." do
            expect(missing_target_graph_link["target"]).to eq("no.doc")
          end

        end

      end

    end

  end

end
