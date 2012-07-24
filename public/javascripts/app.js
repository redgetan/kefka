//var r = Raphael(0, 0, 1000, 1200);
var METHOD_SOURCE = 4;

var createCodeBubble = function(x,y,content) {

  var width = 100;
  var height = 100;

  //var bubble = r.rect(x, y, width, height);
  //bubble.attr("fill", "#f00");

  $("#method_graph").append(content);
  $elem = $("#method_graph table.CodeRay").last();

  $elem.css("position", "absolute")
       .css("left", x)
       .css("top", y);

  // calculate length of longest line in method source,
  // use that line as width of code bubble
  //
  //r.text(x + 10,y + 10, text)
   //.attr("font-size", 14)
   //.attr("text-anchor","start");

};

var createAllCodeBubbles = function(data) {
  var x = 10;
  var y = 10;
  for (var key in data)
  {
    var content = data[key][METHOD_SOURCE];
    createCodeBubble(x,y,content);
    x += 100;
    y += 100;
  }
};

$(document).ready(function(){

  $.ajax({
    url: "/trace",
    dataType: "json",
    success: createAllCodeBubbles;
  });

});

