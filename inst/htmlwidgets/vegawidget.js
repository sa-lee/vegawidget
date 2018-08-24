HTMLWidgets.widget({

  name: "vegawidget",

  type: "output",

  factory: function(el, width, height) {

    var view = null;
    var event_listeners = {};
    var signal_listeners = {};
    var table_insert = {};


    return {

      renderValue: function(x) {

        var chart_spec = x.chart_spec;
        var embed_options = x.embed_options;

        vegaEmbed(el, chart_spec, opt = embed_options).then(function(result) {

          // By removing the style (width and height) of the
          // enclosing element, we let the "chart" decide the space it
          // will occupy.
          //
          el.removeAttribute("style");

          view = result.view;

          console.log(event_listeners);

          console.log(table_insert);

          for (var event_name in event_listeners) {
            console.log(event_listeners[event_name]);
            result.view.addEventListener(event_name, event_listeners[event_name]);
          }

          for (var signal_name in signal_listeners) {
            result.view.addSignalListener(signal_name, signal_listeners[signal_name]);
          }

          for (var table_name in table_insert) {
            // convert to row oriented json
            update = HTMLWidgets.dataframeToD3(table_insert[table_name]);
            // one problem here is if the inserted data falls out of the
            // scales / pixel bounds of the plot, a problem for 1d plots
            // adding additional scales etc.
            result.view.insert(table_name, update).runAsync();
            console.log(result.view.data(table_name));
          }

        }).catch(console.error);

      },

      resize: function(width, height) {

      },

      getView: function() {
        return view;
      },


      callView: function(fn, params) {
        if (view !== null && view !== undefined){
          var method = view[fn];
          method.apply(view, params);
          view.run();
        }
      },

      addEventListener: function(event_name, handler) {
         // Use a list to store event listeners that are
         // applied prior to render time
         event_listeners[event_name] = handler;
         if (view !== null){
           view.addEventListener(event_name, handler);
         }
      },

      addSignalListener: function(signal_name, handler) {
         signal_listeners[signal_name] = handler;
      },

      addShinySignalListener: function(signal_name) {
        if (HTMLWidgets.shinyMode) {
          signal_listeners[signal_name] =
            function(name, value) {
              Shiny.onInputChange(el.id + "_" + signal_name, value);
            };
         }
      },

      insert: function(table_name, table_data) {
        table_insert[table_name] = table_data;
      }

    };

  }
});


// Helper function to get view object via the htmlWidgets object
function getVegaView(selector){

  // Get the HTMLWidgets object
  var htmlWidgetsObj = HTMLWidgets.find(selector);

  console.log(htmlWidgetsObj);
  var view_obj = null;

  if (typeof(htmlWidgetsObj) !== "undefined"){
    view_obj = htmlWidgetsObj.getView();
  }

  return(view_obj);
}

if (HTMLWidgets.shinyMode) {
Shiny.addCustomMessageHandler('callView', function(message){

    // get the correct HTMLWidget instance
    var htmlWidgetsObj = HTMLWidgets.find("#" + message.id);
    if( typeof(htmlWidgetsObj) !== "undefined"){
      htmlWidgetsObj.callView(message.fn, message.params);
    }

});
}
