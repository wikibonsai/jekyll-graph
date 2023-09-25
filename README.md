# Jekyll-Graph

[![A WikiBonsai Project](https://img.shields.io/badge/%F0%9F%8E%8B-A%20WikiBonsai%20Project-brightgreen)](https://github.com/wikibonsai/wikibonsai)
[![Ruby Gem](https://img.shields.io/gem/v/jekyll-graph)](https://rubygems.org/gems/jekyll-graph)

⚠️ This is gem is under active development! ⚠️

⚠️ Expect breaking changes and surprises until otherwise noted (likely by v0.1.0 or v1.0.0). ⚠️

Jekyll-Graph generates data and renders a graph that allows visitors to navigate a jekyll site by clicking nodes in the graph. Nodes are generated from the site's markdown files. Links for the tree graph are generated from [`jekyll-namespaces`](https://github.com/manunamz/jekyll-namespaces) and links for the net-web graph from [`jekyll-wikilinks`](https://github.com/manunamz/jekyll-wikilinks).

This gem is part of the [jekyll-bonsai](https://jekyll-bonsai.netlify.app/) project. 🎋

## Installation

Follow the instructions for installing a [jekyll plugin](https://jekyllrb.com/docs/plugins/installation/) for `jekyll-graph`.

## Usage

1. Add `{% jekyll_graph %}` to the site head:

```html
<head>

  ...

  {% jekyll_graph %}

</head>
```

2. Add a graph div in your html where you want the graph to be rendered:

```html
<div id="jekyll-graph"></div>
```

3. Subclass `JekyllGraph` class in javascript like so:

```javascript
import JekyllGraph from './jekyll-graph.js';

class JekyllGraphSubClass extends JekyllGraph {

  constructor() {
    super();
    // access graph with 'this.graph'
    // access graph div with 'this.graphDiv'
  }
  
  // ...
}
```

The import should point to the `jekyll-graph.js` javascript file generated by the plugin. Unless otherwise configured (see `path` vars below), the `jekyll-graph.js` file will be generated into `_site/assets/js/`. The sample javascript snippet above is presumed to be generated into `_site/assets/js/` as well.

4. Create a class instance:

```javascript
var graph = new JekyllGraphSubClass();
```

5. Call `drawNetWeb()` and/or `drawTree()` to actually draw the graph. You could do this simply on initialization or on a button click, etc.

```javascript
// on page load
(() => {
  graph.drawNetWeb();
});

// on button click
this.graphBtn.addEventListener('click', () => {
  graph.drawTree();
});
```
## Configuration

Default configs look like this:

```yaml
graph:
  enabled: true
  exclude: []
  path:
    assets: "/assets"
    scripts: "/assets/js"
  net_web:
    enabled: true
    exclude:
      attrs: false
      links: false
    force:
      charge:
      strength_x:
      x_val:
      strength_y:
      y_val:
  tree:
    enabled: true
    force:
      charge:
      strength_x:
      x_val:
      strength_y:
      y_val:
```

`enabled`: Turn off the plugin by setting to `false`.

`exclude`: Exclude specific jekyll document types (`posts`, `pages`, `collection_items`).

`path.assets`: An optional custom assets location for graph assets to generate into. Location is relative to the root of the generated `_site/` directory.

`path.scripts`: An optional custom scripts location for the graph scripts to generate into. Location is relative to the assets location in the `_site/` directory (If `assets_path` is set, but `scripts_path` is not, the location will default to `_site/<assets_path>/js/`).

`net_web.exclude.attrs` and `net_web.exclude.links`: Determines whether wikilink attributes and/or links are added to the net-web graph from the link index.

`tree.enabled` and `net_web.enabled`: Toggles on/off the `tree` and `net_web` graphs, respectively. Be sure to disable graphs that are not in use.

`tree.force` and `net_web.force`: These are force variables from d3's simulation forces. You can check out the [docs for details](https://github.com/d3/d3-force#simulation_force).

Force values will likely need to be played with depending on the div size and number of nodes. [jekyll-bonsai](https://manunamz.github.io/jekyll-bonsai/) currently uses these values:

```yaml
graph:
  tree:
    dag_lvl_dist: 100
    force:
      charge: -100
      strength_x: 0.3
      x_val: 0.9
      strength_y: 0.1
      y_val: 0.9
  net_web:
    force:
      charge: -300
      strength_x: 0.3
      x_val: 0.75
      strength_y: 0.1
      y_val: 0.9
```

No configurations are strictly necessary for plugin defaults to work.

## Colors

Graph colors are determined by css variables which may be defined like so -- any valid css color works (hex, rgba, etc.):

```CSS
/* make sure color vars are attached to the root of the html document */
html {
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
}
```

## Data
Graph data is generated in the following format:

For the net-web graph, `graph-net-web.json`,`links` are built from `backlinks` and `attributed` metadata generated in `jekyll-wikilinks`:

```json
// graph-net-web.json
{
  "nodes": [
    {
      "id": "<some-id>",
      "url": "<relative-url>", // site.baseurl is handled for you here
      "label": "<note's-title>",
      "neighbors": {
          "nodes": [<neighbor-node-id>, ...],
          "links": [<neighbor-link-id>, ...],
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

For the tree graph, `graph-tree.json`, `links` are built from a tree data structure constructed in `jekyll-namespaces`:

```json
// graph-tree.json
{
  "nodes": [
    {
      "id": "<some-id>",
      "url": "<lineage-url>", // site.baseurl wil be handled for you here
      "label": "<note's-title>",
      "lineage": {
          "nodes": [<lineage-node-id>, ...],
          "links": [<lineage-link-id>, ...],
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

Unless otherwise defined, both json files are generated into `_site/assets/`.
