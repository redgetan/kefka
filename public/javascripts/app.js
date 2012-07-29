var jqSelectorEscape = function(text) {
  return text.replace(/([!"#$%&'()*+,./:;<=>?@[\]^`{|}~])/g, "\\$&");
};

var createCodeBubbles = function(data) {
  console.log(data);

  var methodTable = data;

  var xPos = 0;
  var yPos = 0;
  var bubbleDiv, $bubble, $callerBubble, callerKey, classname, id, code, file, line, caller, header;

  for (var key in methodTable)
  {
    bubbleDiv = "<div class='bubble'></div>";
    $(bubbleDiv).appendTo("#methodGraph");

    $bubble = $("#methodGraph .bubble").last();
    $bubble.append(methodTable[key].source);

    // set id for bubble table
    $bubble.attr("id",key);

    // set header of bubble div (classname#id file:line)
    header = methodTable[key].file + ":" + methodTable[key].line;
    $bubble.prepend("<pre><span class='methodHeader'>" + header + "</span></pre>");

    // xPos = getXCoordFromCaller(methodTable[key].caller, methodTable);
    //callerKey = methodTable[key].caller.method.key;
    //$callerBubble = $("div.bubble#" + jqSelectorEscape(callerKey));
    //xPos = $callerBubble.position().left + 200;

    // position bubble table
    $bubble.css("position", "absolute")
           .css("left", xPos)
           .css("top",  yPos);

    yPos += $bubble.height();

    // add column for displaying local values
    var lineCount = $bubble.find("td.line-numbers a").length;

    var column = "<td class='locals'>";
    column += "<pre>";

    for (var i = methodTable[key].line; i < methodTable[key].line + lineCount; i++)
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

    var $bubbles = $("div.bubble").filter(function(){
      return this.id.match(file);
    });

    var $line = $bubbles.find("td.locals span#line" + line).first();
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

