//var r = Raphael(0, 0, 1000, 1200);
var Method = {
  FILE: 0,
  CALLER: 1,
  START_LINE: 2,
  FINISH_LINE: 3,
  SOURCE: 4
}

var METHOD_SOURCE = 4;
var FILE = 0;

// calculate position of code bubble
// given caller (examples/sample_a.rb:21:in `new')
// get file, line
// determine what method am I in given file,line
// record = method_table.select { |k,v| v[0] == file && (line > v[2] && line > v[4]) }
// key = record.keys.first
// key for code bubble
//
// get code bubble position
//
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
    if ( methodTable[key][Method.FILE]        == caller.file &&
         methodTable[key][Method.START_LINE]   < caller.line &&
         methodTable[key][Method.FINISH_LINE]  > caller.line )
    {
      var classnameIdFileLine = key;
      var $sourceBubble = $("table#" + jqSelectorEscape(classnameIdFileLine));
      return $sourceBubble.position();
    }
  }
  // didnt find a match
  alert("couldnt find which method this method orignated from ");
  return "fuck";
};

var createCodeBubbles = function(data) {
  console.log(data);

  var methodTable = data;

  var xPos;
  var yPos = 0;

  for (var key in methodTable)
  {

    var caller = methodTable[key][Method.CALLER];
    var code = methodTable[key][Method.SOURCE];
    var file = methodTable[key][Method.FILE];
    var startLine = methodTable[key][Method.START_LINE];

    //var bubble = r.rect(x, y, width, height);
    //bubble.attr("fill", "#f00");

    $("#methodGraph").append(code);

    var $bubble = $("#methodGraph table.CodeRay").last();

    // set id for bubble table
    var classnameIdFileLine = key;
    $bubble.attr("id",classnameIdFileLine);

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

    for (var i = startLine; i < startLine + lineCount; i++)
    {
      column += "<span id='line" + i + "'></span>\n";
    }

    column += "</pre>";
    column += "</td>";

    var $code = $bubble.find("td.code");
    $code.after(column);


    // calculate length of longest line in method source,
    // use that line as width of code bubble
    //
    //r.text(x + 10,y + 10, text)
     //.attr("font-size", 14)
     //.attr("text-anchor","start");

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

    var keys = key.split("_");
    var line = keys.pop();

    var classnameIdFile = keys.join("_");

    var $bubble = $("table").filter(function(){
      return this.id.match(classnameIdFile);
    });

    var $line = $bubble.find("td.locals span#line" + line).first();
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

