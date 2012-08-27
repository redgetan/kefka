var jqSelectorEscape = function(text) {
  return text.replace(/([!"#$%&'()*+,./:;<=>?@[\]^`{|}~])/g, "\\$&");
};

var outputTrace = function(data) {
  //displayInput(data.input);
  //displayGraphiz(data.is_graphviz_installed);
  createCodeBubbles(data.vertices,data.edges);
  displayLocals(data.locals);
}

var displayInput = function(input) {
  $("div#input").last().append(input);
};

var displayGraphiz = function(is_graphviz_installed) {
  if (is_graphviz_installed) {
    $("div#callGraph").last().append("<img src='graph.png'/>");
  } else {
    $("div#callGraph").last().append("Graphviz visualization not Available. Install Graphviz to enable it.");
  }
};

var createCodeBubbles = function(vertices,edges) {
  console.log(vertices);
  console.log(edges);

  var xPos = 0;
  var bubbleDiv,
      $bubble, $code, $expand,
      key, keyTokens, methodName, file, line,
      header,
      lineCount, column;

  var methods = vertices;

  _.each(methods, function(method){
    bubbleDiv = "<div class='bubble'></div>";
    $(bubbleDiv).appendTo("#codeGraph");

    $bubble = $("#codeGraph .bubble").last();
    $bubble.append(method.source);

    // set id for bubble table
    key = method.id + ":" + method.file + ":" + method.line;
    $bubble.attr("id",key);

    // set header of bubble div
    header = method.file + ":" + method.line;
    $bubble.prepend("<pre><span class='methodHeader'>" + header + "</span></pre>");

    // set column position
    xPos = method.depth * 200;

    // position bubble table
    $bubble.css("position", "relative")
           .css("left", xPos);

    // hide bubbles in deeper levels

    if (method.depth != 0) {
      $bubble.hide();
    }

    lineCount = $bubble.find("td.line-numbers a").length;

    // add column for displaying expand buttons
    column = "<td class='expand'>";
    column += "<pre>";

    for (var j = method.line; j < method.line + lineCount; j++)
    {
      column += "<span id='line" + j + "'></span>\n";
    }

    column += "</pre>";
    column += "</td>";

    $code = $bubble.find("td.code");
    $code.after(column);

    // add column for displaying local values

    column = "<td class='locals'>";
    column += "<pre>";

    for (var j = method.line; j < method.line + lineCount; j++)
    {
      column += "<span id='line" + j + "'></span>\n";
    }

    column += "</pre>";
    column += "</td>";

    $expand = $bubble.find("td.expand");
    $expand.after(column);

  });

  var calls = _.map(edges, function(edge) { return edge.source });

  // for each call, get the source (key -> method:line)
  // add an 'expand' button on the source
  // on button, add click handler that will

  _.each(calls, function(call){
    keyTokens = call.split(":");
    methodName = keyTokens[0];
    file       = keyTokens[1];
    line       = keyTokens[2];

    $bubbles = $("div.bubble").filter(function(){
      return this.id.match(methodName) && this.id.match(file);
    });

    $line = $bubbles.find("td.expand span#line" + line).first();
    $line.data("key",call);

    $line.html("<div class='expand'>+</div>");
    $line.find("div.expand").first().click(function() {
      return function(that){
        _.chain(edges)
          .filter( function(edge){ return edge.source == $(that).parent().data("key"); })
          .map(    function(edge){ console.log(edge);return edge.target })
          .each(   function(target){
            $("#codeGraph .bubble#" + jqSelectorEscape(target))
              .first()
              .toggle();
        });
      }(this);
    });

  });


};

var displayLocals = function(locals) {
  console.log(locals);

  var values, keys, file, line, $bubbles, $line;

  for (var key in locals)
  {
    values = "";

    for (var local in locals[key])
    {
      values += "\t";
      values += local;
      values += ": ";
      values += locals[key][local];
    }

    keys = key.split(":");
    methodName = keys[0];
    file = keys[1];
    line = keys[2];

    $bubbles = $("div.bubble").filter(function(){
      return this.id.match(methodName) && this.id.match(file);
    });

    $line = $bubbles.find("td.locals span#line" + line).first();
    $line.text(values.replace(/\n/g,""));
  }
};

$(document).ready(function(){

  $.ajax({
    url: "/callgraph",
    dataType: "json",
    success: outputTrace
  });

});

