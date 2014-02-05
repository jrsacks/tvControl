var rows = [
  [{label : "Vol Down" , action : "tv/volume/down"}, {}, {label : "Vol Up", action :"tv/volume/up"}],
  [{label : "CBS" , action : "tivo/ch/602"}, {label : "NBC" , action : "tivo/ch/605"}, {label : "ABC" , action : "tivo/ch/607"}],
  [{label : "WGN" , action : "tivo/ch/609"}, {}, {label : "FOX" , action : "tivo/ch/612"}],
  [{label : "ESPN" , action : "tivo/ch/681"}, {label : "ESPN2" , action : "tivo/ch/682"}, {label : "CSN" , action : "tivo/ch/685"}],
  [{label : "BTN" , action : "tivo/ch/686"}, {label : "TENNIS" , action : "tivo/ch/692"}, {}],
  [{}, {}, {label : "TV Off", action :"tv/power/off", displayClass : 'btn-danger'}]
];

function buildPage(){
  _.each(rows, function(rowData){
    var row = $("<div class='row-fluid'>")
    _.each(rowData, function(data){
      var elem = $("<div class='span4'>");
      if(data.label){
        var button = $('<button class="btn btn-large input-block-level" type="button">');
        button.addClass(data.displayClass);
        button.text(data.label);
        button.click(function(){
          $.get(data.action);
        });
        elem.append(button);
      }
      row.append(elem);
    });
    $(".container").append(row);
  });
}
