var current_index;

$.tablesorter.addWidget({ 
    // give the widget a id 
    id: "color", 
    // format is called when the on init and when a sorting has finished 
    format: function(table) {
	var vals = []; 
	var allvals = 0;
	var order = '';
    var ascSort = "." + table.config.cssAsc;
    var descSort = "." + table.config.cssDesc;    
    $(ascSort).add(descSort).each(function() {
    $("tr:visible", table.tBodies[0]).find("td:nth-child(" + ($("thead th", table).index(this) + 1) + ")").each(function() {
	if ($("thead th", table).hasClass(table.config.cssAsc))
	{
		order ='asc';
	} else
	{
		order = 'desc';
	}
    var txt = $(this).text();
	txt = txt.replace(/^([0-9\.]+?)\s+(.+?)$/, '$1');
	txt = parseFloat(txt);
	allvals += txt;
	vals.push(txt);
    });
    
    });
    vals = vals.sort( function(a,b) { return a - b; } );
	var maxval = vals[vals.length-1];
    var minval = vals[0];
    
    // * median and std.deviation math *
    var mean = allvals / vals.length;
    var med_idx = Math.round(vals.length / 2);
    var med_value = vals[med_idx];
	var variance = 0;
    for(var j=0; j < vals.length; j++)
    {
        variance = variance + Math.pow(vals[j] - mean,2);
    }
    variance = variance / vals.length;
    var std_dev = Math.sqrt(variance);
    // 

    //simple
    //var threshold_1 = (allvals/100)*30;
    //var threshold_2 = (allvals/100)*80;
 
    var threshold_1 = std_dev;
    var threshold_2 = (maxval/100)*80;
    	
	var cval;
        // loop all tr elements and insert a copy of the "headers"     
        for(var i=0; i < table.tBodies[0].rows.length; i++) {
			if (order == 'asc')
			{
				cval = vals[vals.length-1-i];	
			}
			else
			{
				cval = vals[i];
			}
			if (cval > threshold_2)
			{
			$("tbody tr:eq(" + i + ")",table).attr('style','background: #e32636');
			}
			else if (cval > threshold_1)
			{
			$("tbody tr:eq(" + i + ")",table).attr('style','background: #FFFF00');
			}
			else
			{
			$("tbody tr:eq(" + i + ")",table).attr('style','background: #FFFFFF');	
			}
        } 

        }
    });  


$(document).ready(function() 
    { 
        //$("table.sortable").tablesorter( {textExtraction: ppapTextExtraction} ); 
        $("table.sortable").tablesorter( {textExtraction: ppapTextExtraction, widgets: ['color']} ); 
    } 
);

var ppapTextExtraction = function(node)  
{  
    // extract data from markup and return it  
   var html = node.innerHTML;
   html = html.replace(/^([0-9\.]+?)\s+(.+?)$/, '$1');
   html = html.replace(/^<a href(.+?)>(.+?)<\/a>$/, '$2');
   return html; 
} 
