var jqSelectorEscape = function(text) {
  return text.replace(/([!"#$%&'()*+,./:;<=>?@[\]^`{|}~])/g, "\\$&");
};

var createCodeBubbles = function(data) {
  console.log(data);

  var methodGraph = data;

  var xPos = 0;
  var yPos = 0;
  var bubbleDiv, $bubble, $code,
      key, header,
      lineCount, column;

  var methods = methodGraph.vertices;

  for (var i = 0; i < methods.length; i++ )
  {
    bubbleDiv = "<div class='bubble'></div>";
    $(bubbleDiv).appendTo("#methodGraph");

    $bubble = $("#methodGraph .bubble").last();
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

    // position bubble table
    $bubble.css("position", "absolute")
           .css("left", xPos)
           .css("top",  yPos);

    yPos += $bubble.height();

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

var displayLocalValues = function(data) {
  console.log(data);

  var localValues = data;

  var values, keys, file, line, $bubbles, $line;

  for (var key in localValues)
  {
    values = "";

    for (var local in localValues[key])
    {
      values += "\t";
      values += local;
      values += ": ";
      values += localValues[key][local];
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

  var getLocalValues = function() {
    $.ajax({
      url: "/locals",
      dataType: "json",
      success: displayLocalValues
    });
  };

  $.ajax({
    url: "/callgraph",
    dataType: "json",
    success: [createCodeBubbles, getLocalValues]
  });


});

