var volRow = [[{label : "Vol Down" , action : "tv/volume/down"}, {}, {label : "Vol Up", action :"tv/volume/up"}]];
var power = [[{label: 'Prev', fn : 'prevView'}, {label: 'Next', fn : 'nextView'}, {label : "TV Off", action :"tv/power/off", displayClass : 'btn-danger'}]];

var channels = [
  [{label : "CBS" , action : "tivo/ch/602"}, {label : "NBC" , action : "tivo/ch/605"}, {label : "ABC" , action : "tivo/ch/607"}],
  [{label : "WGN" , action : "tivo/ch/609"}, {}, {label : "FOX" , action : "tivo/ch/612"}],
  [{label : "ESPN" , action : "tivo/ch/681"}, {label : "ESPN2" , action : "tivo/ch/682"}, {label : "CSN" , action : "tivo/ch/685"}],
  [{label : "BTN" , action : "tivo/ch/686"}, {label : "TENNIS" , action : "tivo/ch/692"}, {}]
];

var controls = [
  [{label : "TiVo" , action : "tivo/TELEPORT/TIVO"}, {label : "Live TV" , action : "tivo/TELEPORT/LIVETV"}, {label : "Guide", action : "tivo/TELEPORT/GUIDE"}],
  [{label : "CLEAR" , action : "tivo/IRCODE/CLEAR"}, {label : "INFO" , action : "tivo/IRCODE/INFO"}, {label : "ENTER", action : "tivo/IRCODE/ENTER"}],
  [{}, {label : "UP" , action : "tivo/IRCODE/UP"}, {}],
  [{label : "LEFT" , action : "tivo/IRCODE/LEFT"}, {label : "SELECT" , action : "tivo/IRCODE/SELECT"}, {label : "RIGHT", action : "tivo/IRCODE/RIGHT"}],
  [{}, {label : "DOWN" , action : "tivo/IRCODE/DOWN"}, {}]
];

var numbers = [
  [{label : "1" , action : "tivo/IRCODE/NUM1"}, {label : "2" , action : "tivo/IRCODE/NUM2"}, {label : "3" , action : "tivo/IRCODE/NUM3"}],
  [{label : "4" , action : "tivo/IRCODE/NUM4"}, {label : "5" , action : "tivo/IRCODE/NUM5"}, {label : "6" , action : "tivo/IRCODE/NUM6"}],
  [{label : "7" , action : "tivo/IRCODE/NUM7"}, {label : "8" , action : "tivo/IRCODE/NUM8"}, {label : "9" , action : "tivo/IRCODE/NUM9"}],
  [{}, {label : "0" , action : "tivo/IRCODE/NUM0"}, {}]
];

var playback = [
  [{}, {label : "PLAY" , action : "tivo/IRCODE/PLAY"}, {}],
  [{label : "REVERSE" , action : "tivo/IRCODE/REVERSE"}, {label : "PAUSE" , action : "tivo/IRCODE/PAUSE"}, {label : "FORWARD", action : "tivo/IRCODE/FORWARD"}],
  [{label : "REPLAY" , action : "tivo/IRCODE/REPLAY"}, {label : "RECORD" , action : "tivo/IRCODE/RECORD"}, {label : "ADVANCE" , action : "tivo/IRCODE/ADVANCE"}]
];

var channelView = volRow.concat(channels, power);
var guideView = volRow.concat(controls, power);
var numberView = volRow.concat(numbers, power);
var playbackView = volRow.concat(playback, power); 
var views = [channelView, guideView, numberView, playbackView];

var viewIndex = 0;
function nextView(){
  if(viewIndex + 1 < views.length){
    viewIndex += 1;
    buildView(views[viewIndex]);
  }
}

function prevView(){ 
  if(viewIndex - 1 >= 0){
    viewIndex -= 1;
    buildView(views[viewIndex]);
  }
}

function buildPage(){
  $('.ui-loader').remove();
  buildView(views[viewIndex]);
  $('body').on('swiperight', nextView);
  $('body').on('swipeleft', prevView);
}

function buildView(rows){
  $('.container').empty();
  _.each(rows, function(rowData){
    var row = $("<div class='row-fluid'>")
    _.each(rowData, function(data){
      var elem = $("<div class='span4'>");
      if(data.label){
        var button = $('<button class="btn btn-large input-block-level" type="button">');
        button.addClass(data.displayClass);
        button.text(data.label);
        button.click(function(){
          if(data.action){
            $.get(data.action);
          } else {
            window[data.fn]();
          }
        });
        elem.append(button);
      }
      row.append(elem);
    });
    $(".container").append(row);
  });
}
