package cgifunctions;

use File::Basename;
use lib '../lib';
use DAL;

=head
This method contains methods for the cgi pages to reuse code.

Methods:
new() - constructor

makeNoVrmlFile() - declares the path to output vrml file and path to localhosts output directory
makeBaseNumber() - inner method to create a basenumber for the vrmlfile 

makeJavaScript() - generates the javascript for dynamically adding values to a selectbox

embedVrmlFile() - generates HTML to embed a wrl file

What to do in this file:
1. Need to set the filepath for the xml-files you have got.

=cut

###############
# Constructor #
###############

my $FILEPATH = "D:\\Apps\\wamp\\www\\output\\"; # output folder for the wrl-files
my $WEBFILEPATH = "http://localhost/output/";
my $dal;

sub new()
{
	# Instantiates the whole class
	#Params:
	#1: self
	#2: filepath - written as d:\\apps\\etc\\etc2\\ - static
	my $class = shift;
	
	$dal = new DAL(); 
	
	my $ref = {};
	bless($ref);
	return $ref;
	
}
1;

sub makeNoVrmlFile()
{
	# Declares correct vrmlfile - print vrml output to this file
	#Params:
	#1: self
	# Returns two strings, vrmlFile and vrmlFileHandle
	
	my $self = shift;
	
	my @files = <$FILEPATH*.wrl>;
	for (@files)
	{
		# Need to collect the basename of the wrl file, to get a new file which is not there already
		my $temp = basename($_);
		$temp =~ s/.wrl//;
		push(@baseNumbers, $temp);
	}
	my $nrOfWRLFiles = @files + 1;
	
	my $baseNumber = &makeBaseNumber($nrOfWRLFiles);
	
	my $baseVrmlFile = "" . ($baseNumber) . ".wrl";
	
	$vrmlFile = "$WEBFILEPATH$baseVrmlFile";
	$vrmlFileHandle = "$FILEPATH$baseVrmlFile";
	
	return ($vrmlFile,$vrmlFileHandle);
}

sub makeBaseNumber()
{
	my $nr = shift;
	my $bool = "false";
	for (@baseNumbers)
	{
		if ($_ == $nr)
		{
			$bool = "true";
		}
	}
	if ($bool eq "true")
	{
		$nr++;
		return &makeBaseNumber($nr);
	}
	return $nr;
}

sub makeJavaScript()
{
	# Makes a showDDL method + help methods for this one
	# The showDDL method takes a selectbox and new values as parameters
	# Dynamically changes the values of the incoming selectbox
	#Params:
	#1: self
	#Returns the javascript as a string
	
	my $self = shift;
	
	my $jScript = "";
	$jScript .= "
<script type='text/javascript'>
<!--//
	function showDDL(criteriaDDL, arrVerdier)
	{		
		var arr = new Array();
		var arr = arrVerdier.split('\;');
		
		var selectBox = document.getElementById(criteriaDDL);
		
		selectBox.style.visibility='visible';
		
		removeAllOptions(selectBox);
		addOption(selectBox,'1000','Select criteria');
		
		//addOption(selectBox,nr,spanID);
		
		//document.getElementById(spanID).style.visibility='visible';
	
		for (var i = 0; i < arr.length; i++)
		{
			addOption(selectBox,arr[i],arr[i]);
		}
	}
	
	function isArray(testObject) {   
	    return testObject && !(testObject.propertyIsEnumerable('length')) && typeof testObject === 'object' && typeof testObject.length === 'number';
	}
	
	function removeAllOptions(selectbox)
	{
		var i;
		for(i = selectbox.options.length-1; i >= 0; i--)
		{
			//selectbox.options.remove(i);
			selectbox.remove(i);
		}
	}
	
	function addOption(selectbox, value, text )
	{
		var optn = document.createElement('OPTION');
		optn.text = text;
		optn.value = value;
	
		selectbox.options.add(optn);
	}

//-->
</script>
";

	return $jScript;
	
}

sub makeSelectBox()
{
	# Method to generate HTML code for a selectbox
	#Params:
	#1: self
	#2: name of selectbox
	#3: number of javascript (send as "-1" if this is not to be included)
	#4: tablename
	#5->infinity: components
	#Returns a string of html code with one select box
	
	my $self = shift;
	
	my $selectboxname = shift;
	my $selectboxnameValue = $selectboxname . "Value";
	my $no = shift;
	if (!($no eq "-1"))
	{
		$selectboxname .= $no;
		$selectboxnameValue = $selectboxname . "Value" . $no;
	}
	
	my $table = shift;
	my @comps = @_;
	my $compsLength = @comps;
	my @javaComps;
	
	my $critValueString = "";
	
	my $temp = ""; # string containing html code to return
    	
    # Criteria selectbox
    	
   	$temp .= "<select name='$selectboxname' id='$selectboxname'>\n";
   	
   	
   	for (my $c = 0; $c < $compsLength; $c++)
   	{
   		@javaComps = $dal->getDistinctValuesFromTable($table, $comps[$c]);
   		if ($c == 0)
   		{
   			$critValueString .= &makeValueSelectBox($selectboxnameValue,@javaComps);
   		}
   		for (@javaComps){ $_ .= ";" };
   		$temp .= "\t<option value='$comps[$c]' onClick=\"showDDL('$selectboxnameValue', '@javaComps')\">$comps[$c]</option>\n";
   	}
    	
   	$temp .= "</select>\n";
   	
   	$temp .= $critValueString;
   	
   	return $temp;
}

sub makeValueSelectBox()
{
	# Method to generate html for a hidden selectbox
	# Inner method, so don't include self
	#Params:
	#1: selectboxnameValue - other selectboxes
	#2->infinity: values to put in the selectbox
	#Return a string of selectbox in html code
	my $selectboxnameValue = shift;
	my @values = @_;
	my $valuesLength = @values;
	my $temp = "";
	
	$temp .= "<select name='$selectboxnameValue' id='$selectboxnameValue'>\n";
	for (my $v = 0; $v < $valuesLength; $v++)
	{
		$temp .= "\t<option value='$values[$v]' >$values[$v]</option>\n";
	}
    $temp .= "</select>";
    
    return $temp;
}

