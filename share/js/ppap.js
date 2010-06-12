
$(document).ready(function() 
    { 
        $("table.sortable").tablesorter( {textExtraction: ppapTextExtraction} ); 
    } 
);

var ppapTextExtraction = function(node)  
{  
    // extract data from markup and return it  
   var html = node.innerHTML;
//if (html.match(new RegExp(/([0-9\.]+?)\s+(.+?)/)))
//{
	
   html = html.replace(/^([0-9\.]+?)\s+(.+?)$/, '$1');
//	alert(html);
//}
   return html; 
} 
