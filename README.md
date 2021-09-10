# Jekyll::Graph

Jekyll-Graph generates graph data and renders a graph that allows visitors to navigate the jekyll site by clicking nodes in the graph. Nodes are generated from the site's markdown files. Links for the tree graph are generated from `jekyll-namespaces` and links for the net-web graph from `jekyll-wikilinks`.

## Installation

1. Add this line to your application's Gemfile:

```
$ gem 'jekyll-graph'
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install jekyll-graph
```

## Usage

1. Add `{% force_graph %}` to the site head:

```html
<head>

  ...

  {% force_graph %}

</head>
```

2. Add a graph div in your html where you want the graph to be rendered:

```html
<div id="jekyll-graph"></div>
```

3. Hook up scripts to draw graph via the `JekyllGraph` class like so:

```javascript
import JekyllGraph from './jekyll-graph.js';

export default class GraphNav {
  ...
}

// subclass
// Hook up the instance properties
Object.setPrototypeOf(GraphNav.prototype, JekyllGraph.prototype);

// Hook up the static properties
Object.setPrototypeOf(GraphNav, JekyllGraph);

```

Call `drawNetWeb()` and `drawTree()` to actually draw the graph.

## Configurables

Default configs look like this:

```yml
d3:
  enabled: true
  assets_path: "/assets"
  scripts_path: "/assets/js"
  type:
    net_web: true
    tree: true
  node:
    exclude: []
  link:
    exclude: []
```

`enabled`: turn off the plugin by setting to `false`.
`exclude`: exclude specific jekyll document types (`posts`, `pages`, `collection_items`).
`assets_path`: custom graph file location from the root of the generated `_site/` directory.
`scripts_path`: custom graph scripts location from the assets location of the generated `_site/` directory (if `assets_path` is set, but `scripts_path` is not, the location will default to `_site/<assets_path>/js/`).
`type` toggles the `net_web` and `tree` type graphs.
`node`: corresponds to jekyll document types (`posts`, `pages`, `collection_items`) which may be excluded under `exclude`.
`link`: corresponds to [wikilink](https://github.com/manunamz/jekyll-wikilinks/) types (`attributes`, `typed`, `untyped`) which may be excluded under `exclude`.

## Colors

Graph colors are determined by css vars which may be defined like so -- any valid css color works (hex, rgba, etc.):

```CSS
  /* nodes */
  /* glow */
  --graph-node-current-glow: yellow;
  --graph-node-tagged-glow: green;
  --graph-node-visited-glow: blue;
  /* color */
  --graph-node-stroke-color: grey;
  --graph-node-missing-color: transparent;
  --graph-node-unvisited-color: brown;
  --graph-node-visited-color: green;
  /* links */
  --graph-link-color: brown;
  --graph-particles-color: grey;
  /* label text */
  --graph-text-color: black;
  /*  */
```

## Data
Graph data is generated and output to `.json` files in your `/assets` directory in the following format:

```
// graph-net-web.json
{
  "nodes": [
    {
      "id": "<some-id>",
      "url": "<relative-url>", // site.baseurl is handled for you here via "relative_url" usage
      "label": "<note's-title>",
      "neighbors": {
          "nodes": [<neighbor-node>, ...],
          "links": [<neighbor-link>, ...],
      }
    },
    ...
  ],
  "links": [
    {
      "source": "<a-node-id>",
      "target": "<another-node-id>",
    },
    ...
  ]
}
```

`links` are built from `backlinks` and `attributed` from `jekyll-wikilinks`.


```
// graph-tree.json
{
  "nodes": [
    {
      "id": "<some-id>",
      "url": "<relative-url>", // site.baseurl is handled for you here via "relative_url" usage
      "label": "<note's-title>",
      "relatives": {
          "nodes": [<relative-node>, ...],
          "links": [<relative-link>, ...],
      }
    },
    ...
  ],
  "links": [
    {
      "source": "<a-node-id>",
      "target": "<another-node-id>",
    },
    ...
  ]
}
```

`links` are built from file namespacing from `jekyll-namespaces`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/manunamz/jekyll-graph.
