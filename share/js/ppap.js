var current_index = -1;

$.tablesorter.addWidget({
    // give the widget a id
    id: "color",
    // format is called when the on init and when a sorting has finished
    format: function(table) {
        if (!table.config.sortList.length)
            return;
        if ( current_index == table.config.sortList[0][0] )
            return;

        current_index = table.config.sortList[0][0];
        $('tr.warning,tr.error', table)
            .removeClass('warning').removeClass('error');
        if ( !ppapIsNumeric(ppapTextExtraction(
            $('tbody tr:first td:eq('+current_index+')', table).get(0)
        )))
            return;

        var order = table.config.sortList[0][1];

        var vals = [];
        var sum = 0;
        $("tbody tr", table).each(function() {
            var val = parseFloat(ppapTextExtraction(
                $("td:eq("+current_index+')', this).get(0)
            ));
            sum += val;
            vals.push(val);
        });
        var maxval = Math.max.apply(Math, vals);
        var minval = Math.min.apply(Math, vals);

        // * median and std.deviation math *
        var mean = sum / vals.length;
        var variance = 0;
        for(var j=0; j < vals.length; j++) {
            variance += Math.pow(vals[j] - mean,2);
        }
        variance /= vals.length;
        var std_dev = Math.sqrt(variance);

        var threshold_1 = std_dev;
        var threshold_2 = (maxval/100)*80;

        $("tbody tr",table).each(function(){
            var val = parseFloat(ppapTextExtraction(
                $("td:eq("+current_index+')', this).get(0)
            ));
            if (val > threshold_2)
                $(this).addClass('error');
            else if (val > threshold_1)
                $(this).addClass('warning');
        });
    }
});

var ppapTextExtraction = function(node)
{
    return node.childNodes[0].innerHTML;
}
var ppapIsNumeric = function(n)
{
    return !isNaN(parseFloat(n)) && isFinite(n);
}

$(function() {
    $.extend($.tablesorter.themes.bootstrap, {
        table    : 'table table-bordered table-condensed',
        header   : 'bootstrap-header',
        icons    : '',
        sortNone : 'bootstrap-icon-unsorted', 
        sortAsc  : 'icon-chevron-up', 
        sortDesc : 'icon-chevron-down', 
        active   : '', // applied when column is sorted 
        hover    : '', // use custom css here - bootstrap class may not override it 
        filterRow: '', // filter row class 
        even     : '', // odd row zebra striping 
        odd      : ''  // even row zebra striping 
    });
    $("table.sortable").tablesorter({
        textExtraction: ppapTextExtraction,
        widgets: ['color', 'uitheme'],
        widgetOptions: {
            uitheme: "bootstrap"
        }
    });
} );

