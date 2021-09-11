// don't need frontmatter because liquid is handled internally...somehow...
export default class JekyllGraph {

  constructor() {
    this.graphDiv = document.getElementById('jekyll-graph');
  }

  // d3
  drawNetWeb () {
    fetch('{{ site.baseurl }}{{ site.graph.assets_path }}/graph-net-web.json').then(res => res.json()).then(data => {

      // neighbors: replace ids with full object
      data.nodes.forEach(node => {
        let neighborNodes = [];
        node.neighbors.nodes.forEach(nNodeId => {
          neighborNodes.push(data.nodes.find(node => node.id === nNodeId));
        });
        let neighborLinks = [];
        node.neighbors.links.forEach(nLink => {
          neighborLinks.push(data.links.find(link => link.source === nLink.source && link.target === nLink.target));
        });
        node.neighbors.nodes = neighborNodes;
        node.neighbors.links = neighborLinks;
      });

      const highlightNodes = new Set();
      const highlightLinks = new Set();
      let hoverNode = null;
      let hoverLink = null;

      const Graph = ForceGraph()

      (this.graphDiv)
        // container
        .height(this.graphDiv.parentElement.clientHeight)
        .width(this.graphDiv.parentElement.clientWidth)
        // node
        .nodeCanvasObject((node, ctx) => this.nodePaint(node, ctx, hoverNode, hoverLink, "net-web"))
        // .nodePointerAreaPaint((node, color, ctx, scale) => nodePaint(node, nodeTypeInNetWeb(node), ctx))
        .nodeId('id')
        .nodeLabel('label')
        .onNodeClick((node, event) => this.goToPage(node, event))
        // link
        .linkSource('source')
        .linkTarget('target')
        .linkColor(() => getComputedStyle(document.documentElement).getPropertyValue('--graph-link-color'))
        // forces
        // .d3Force('link',    d3.forceLink()
        //                       .id(function(d) {return d.id;})
        //                       .distance(30)
        //                       .iterations(1))
        //                       .links(data.links))

         .d3Force('charge',  d3.forceManyBody()
                               .strength(Number('{{ site.graph.net_web.force.charge }}')))
         // .d3Force('collide', d3.forceCollide())
         // .d3Force('center',  d3.forceCenter())
         .d3Force('forceX',  d3.forceX()
                               .strength(Number('{{ site.graph.net_web.force.strength_x }}'))
                               .x(Number('{{ site.graph.net_web.force.x_val }}')))
         .d3Force('forceY', d3.forceY()
                              .strength(Number('{{ site.graph.net_web.force.strength_y }}'))
                              .y(Number('{{ site.graph.net_web.force.y_val }}')))

        // hover
        .autoPauseRedraw(false) // keep redrawing after engine has stopped
        .onNodeHover(node => {
          highlightNodes.clear();
          highlightLinks.clear();
          if (node) {
            highlightNodes.add(node);
            node.neighbors.nodes.forEach(node => highlightNodes.add(node));
            node.neighbors.links.forEach(link => highlightLinks.add(link));
          }
          hoverNode = node || null;
        })
        .onLinkHover(link => {
          highlightNodes.clear();
          highlightLinks.clear();
          if (link) {
            highlightLinks.add(link);
            highlightNodes.add(link.source);
            highlightNodes.add(link.target);
          }
          hoverLink = link || null;
        })
        .linkDirectionalParticles(4)
        .linkDirectionalParticleWidth(link => highlightLinks.has(link) ? 2 : 0)
        .linkDirectionalParticleColor(() => getComputedStyle(document.documentElement).getPropertyValue('--graph-particles-color'))
        // zoom
        // (fit to canvas when engine stops)
        // .onEngineStop(() => Graph.zoomToFit(400))
        // data
        .graphData(data);

        elementResizeDetectorMaker().listenTo(
          this.graphDiv,
          function(el) {
            Graph.width(el.offsetWidth);
            Graph.height(el.offsetHeight);
          }
        );
      });
  }

  drawTree () {
    fetch('{{ site.baseurl }}{{ site.graph.assets_path }}/graph-tree.json').then(res => res.json()).then(data => {

      // relatives: replace ids with full object
      data.nodes.forEach(node => {
        let relativeNodes = [];
        node.relatives.nodes.forEach(nNodeId => {
          relativeNodes.push(data.nodes.find(node => node.id === nNodeId));
        });
        let relativeLinks = [];
        node.relatives.links.forEach(nLink => {
          relativeLinks.push(data.links.find(link => link.source === nLink.source && link.target === nLink.target));
        });
        node.relatives.nodes = relativeNodes;
        node.relatives.links = relativeLinks;
      });

      const highlightNodes = new Set();
      const highlightLinks = new Set();
      let hoverNode = null;
      let hoverLink = null;

      const Graph = ForceGraph()

      (this.graphDiv)
        // dag-mode (tree)
        .dagMode('td')
        .dagLevelDistance(Number('{{ site.graph.tree.dag_lvl_dist }}'))
        // container
        .height(this.graphDiv.parentElement.clientHeight)
        .width(this.graphDiv.parentElement.clientWidth)
        // node
        .nodeCanvasObject((node, ctx) => this.nodePaint(node, ctx, hoverNode, hoverLink, "tree"))
        // .nodePointerAreaPaint((node, color, ctx, scale) => nodePaint(node, nodeTypeInNetWeb(node), ctx))
        .nodeId('id')
        .nodeLabel('label')
        .onNodeClick((node, event) => this.goToPage(node, event))
        // link
        .linkSource('source')
        .linkTarget('target')
        .linkColor(() => getComputedStyle(document.documentElement).getPropertyValue('--graph-link-color'))
        // forces
        // .d3Force('link',    d3.forceLink()
        //                       .id(function(d) {return d.id;})
        //                       .distance(30)
        //                       .iterations(1))
        //                       .links(data.links))

        .d3Force('charge',  d3.forceManyBody()
                              .strength(Number('{{ site.graph.tree.force.charge }}')))
        // .d3Force('collide', d3.forceCollide())
        // .d3Force('center',  d3.forceCenter())
        .d3Force('forceX',  d3.forceX()
                              .strength(Number('{{ site.graph.tree.force.strength_x }}'))
                              .x(Number('{{ site.graph.tree.force.x_val }}')))
        .d3Force('forceY', d3.forceY()
                             .strength(Number('{{ site.graph.tree.force.strength_y }}'))
                             .y(Number('{{ site.graph.tree.force.y_val }}')))

        // hover
        .autoPauseRedraw(false) // keep redrawing after engine has stopped
        .onNodeHover(node => {
          highlightNodes.clear();
          highlightLinks.clear();
          if (node) {
            highlightNodes.add(node);
            node.relatives.nodes.forEach(node => highlightNodes.add(node));
            node.relatives.links.forEach(link => highlightLinks.add(link));
          }
          hoverNode = node || null;
        })
        .onLinkHover(link => {
          highlightNodes.clear();
          highlightLinks.clear();
          if (link) {
            highlightLinks.add(link);
            highlightNodes.add(link.source);
            highlightNodes.add(link.target);
          }
          hoverLink = link || null;
        })
        .linkDirectionalParticles(4)
        .linkDirectionalParticleWidth(link => highlightLinks.has(link) ? 2 : 0)
        .linkDirectionalParticleColor(() => getComputedStyle(document.documentElement).getPropertyValue('--graph-particles-color'))
        // zoom
        // (fit to canvas when engine stops)
        // .onEngineStop(() => Graph.zoomToFit(400))
        // data
        .graphData(data);

        elementResizeDetectorMaker().listenTo(
          this.graphDiv,
          function(el) {
            Graph.width(el.offsetWidth);
            Graph.height(el.offsetHeight);
          }
        );
      });
  }

  // draw helpers

  nodePaint(node, ctx, hoverNode, hoverLink, gType) {
    let fillText = true;
    let radius = 6;
    //
    // nodes color
    //
    if (this.isVisitedPage(node)) {
      ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue('--graph-node-visited-color');
    } else if (this.isMissingPage(node)) {
      ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue('--graph-node-missing-color')
    } else if (!this.isVisitedPage(node) && !this.isMissingPage(node)) {
      ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue('--graph-node-unvisited-color');
    } else {
      console.log("WARN: Not a valid base node type.");
    }
    ctx.beginPath();
    //
    // hover behavior
    //
    if (node === hoverNode) {
      // hoverNode
      radius *= 2;
      fillText = false; // node label should be active
    } else if (hoverNode !== null && gType === "net-web" && hoverNode.neighbors.nodes.includes(node)) {
      // neighbor to hoverNode
    } else if (hoverNode !== null && gType === "net-web" && !hoverNode.neighbors.nodes.includes(node)) {
      // non-neighbor to hoverNode
      fillText = false;
    } else if (hoverNode !== null && gType === "tree" && hoverNode.relatives.nodes.includes(node)) {
      // neighbor to hoverNode
    } else if (hoverNode !== null && gType === "tree" && !hoverNode.relatives.nodes.includes(node)) {
      // non-neighbor to hoverNode
      fillText = false;
    } else if ((hoverNode === null && hoverLink !== null) && (hoverLink.source === node || hoverLink.target === node)) {
      // neighbor to hoverLink
      fillText = true;
    } else if ((hoverNode === null && hoverLink !== null) && (hoverLink.source !== node && hoverLink.target !== node)) {
      // non-neighbor to hoverLink
      fillText = false;
    } else {
      // no hover (default)
    }
    ctx.arc(node.x, node.y, radius, 0, 2 * Math.PI, false);
    //
    // glow behavior
    //
    if (this.isCurrentPage(node)) {
      // turn glow on
      ctx.shadowBlur = 30;
      ctx.shadowColor = getComputedStyle(document.documentElement).getPropertyValue('--graph-node-current-glow');
    } else if (this.isTag(node)) {
      // turn glow on
      ctx.shadowBlur = 30;
      ctx.shadowColor = getComputedStyle(document.documentElement).getPropertyValue('--graph-node-tagged-glow');
    } else if (this.isVisitedPage(node)) {
      // turn glow on
      ctx.shadowBlur = 20;
      ctx.shadowColor = getComputedStyle(document.documentElement).getPropertyValue('--graph-node-visited-glow');
    } else {
      // no glow
    }
    ctx.fill();
    // turn glow off
    ctx.shadowBlur = 0;
    ctx.shadowColor = "";
    //
    // draw node borders
    //
    ctx.lineWidth = radius * (2 / 5);
    ctx.strokeStyle = getComputedStyle(document.documentElement).getPropertyValue('--graph-node-stroke-color');
    ctx.stroke();
    //
    // node labels
    //
    if (fillText) {
      // add peripheral node text
      ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue('--graph-text-color');
      ctx.fillText(node.label, node.x + radius + 1, node.y + radius + 1);
    }
  }

  isCurrentPage(node) {
    return !this.isMissingPage(node) && window.location.pathname.includes(node.url);
  }

  isTag(node) {
    // if (!isPostPage) return false;
    const semTags = Array.from(document.getElementsByClassName("sem-tag"));
    const tagged = semTags.filter((semTag) =>
      !this.isMissingPage(node) && semTag.hasAttribute("href") && semTag.href.includes(node.url)
    );
    return tagged.length !== 0;
  }

  isVisitedPage(node) {
    if (!this.isMissingPage(node)) {
      var visited = JSON.parse(localStorage.getItem('visited'));
      for (let i = 0; i < visited.length; i++) {
        if (visited[i]['url'] === node.url) return true;
      }
    }
    return false;
  }

  isMissingPage(node) {
    return node.url === '';
  }

  // user-actions

  // from: https://stackoverflow.com/questions/63693132/unable-to-get-node-datum-on-mouseover-in-d3-v6
  // d3v6 now passes events in vanilla javascript fashion
  goToPage(node, e) {
    if (!this.isMissingPage(node)) {
      window.location.href = node.url;
      return true;
    } else {
      return false;
    }
  }
}