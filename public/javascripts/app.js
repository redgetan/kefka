var jqSelectorEscape = function(text) {
  return text.replace(/([!"#$%&'()*+,./:;<=>?@[\]^`{|}~])/g, "\\$&");
};

var getCoordFromCaller = function(caller, methodTable) {
  if (caller.method == "<main>")
  {
    return { x: 10, y: 10 };
  }

  for (var key in methodTable)
  {
    if ( methodTable[key].file        == caller.file &&
         methodTable[key].line         < caller.line &&
         methodTable[key].end_line     > caller.line )
    {
      var $sourceBubble = $("table#" + jqSelectorEscape(key));
      return $sourceBubble.position();
    }
  }
  // didnt find a match
  console.log("warning: couldnt match " + caller.method + " " +
              caller.file + ":" + caller.line + " to a method in methodTable");
  return { x: 10, y: 10 };
};

var createCodeBubbles = function(data) {
  console.log(data);

  var methodTable = data;

  var xPos;
  var yPos = 0;

  for (var key in methodTable)
  {

    var caller = methodTable[key].caller;
    var code = methodTable[key].source;
    var file = methodTable[key].file;
    var line = methodTable[key].line;

    $("#methodGraph").append(code);

    var $bubble = $("#methodGraph table.CodeRay").last();

    // set id for bubble table
    $bubble.attr("id",key);

    var pos = getCoordFromCaller(caller, methodTable);
    xPos = pos.left + 200;
    // position bubble table
    $bubble.css("position", "absolute")
           .css("left", xPos)
           .css("top",  yPos);

    yPos += $bubble.height();

    // add column for displaying local values
    var lineCount = $bubble.find("td.line-numbers a").length;

    var column = "<td class='locals'>";
    column += "<pre>";

    for (var i = line; i < line + lineCount; i++)
    {
      column += "<span id='line" + i + "'></span>\n";
    }

    column += "</pre>";
    column += "</td>";

    var $code = $bubble.find("td.code");
    $code.after(column);

  }
};

var displayLocalValues = function(data) {
  console.log(data);

  var localValues = data;

  var values;

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

    var keys = key.split(":");
    var file = keys[0];
    var line = keys[1];

    var $bubbles = $("table").filter(function(){
      return this.id.match(file);
    });

    var $line = $bubbles.find("td.locals span#line" + line).first();
    $line.html(values);
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

