var jqSelectorEscape = function(text) {
  return text.replace(/([!"#$%&'()*+,./:;<=>?@[\]^`{|}~])/g, "\\$&");
};

var outputTrace = function(data) {
  displayInput(data.input);
  displayGraphiz(data.is_graphviz_installed);
  createCodeBubbles(data.graph);
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

var createCodeBubbles = function(graph) {
  console.log(graph);

  var xPos = 0;
  var bubbleDiv, $bubble, $code,
      key, header,
      lineCount, column;

  var methods = graph.vertices;

  for (var i = 0; i < methods.length; i++ )
  {
    bubbleDiv = "<div class='bubble'></div>";
    $(bubbleDiv).appendTo("#codeGraph");

    $bubble = $("#codeGraph .bubble").last();
    $bubble.append(methods[i].source);

    // set id for bubble table
    key = methods[i].file + ":" + methods[i].line;
    $bubble.attr("id",key);

    // set header of bubble div
    header = methods[i].file + ":" + methods[i].line;
    $bubble.prepend("<pre><span class='methodHeader'>" + header + "</span></pre>");

    //callerKey = methodTable[key].caller.method.key;
    //$callerBubble = $("div.bubble#" + jqSelectorEscape(callerKey));
    //xPos = $callerBubble.position().left + 200;
    xPos = methods[i].depth * 200;

    // position bubble table
    $bubble.css("position", "relative")
           .css("left", xPos);

    // add column for displaying local values
    lineCount = $bubble.find("td.line-numbers a").length;

    column = "<td class='locals'>";
    column += "<pre>";

    for (var j = methods[i].line; j < methods[i].line + lineCount; j++)
    {
      column += "<span id='line" + j + "'></span>\n";
    }

    column += "</pre>";
    column += "</td>";

    $code = $bubble.find("td.code");
    $code.after(column);

  }
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
    file = keys[0];
    line = keys[1];

    $bubbles = $("div.bubble").filter(function(){
      return this.id.match(file);
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

