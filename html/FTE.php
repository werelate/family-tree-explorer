<!-- saved from url=(0014)about:internet -->
<html lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title></title>
<script src="AC_OETags.js" language="javascript"></script>
<style>
body { margin: 0px; overflow:hidden }
</style>
<script language="JavaScript" type="text/javascript">
<!--
// -----------------------------------------------------------------------------
// Globals
// Major version of Flash required
var requiredMajorVersion = 9;
// Minor version of Flash required
var requiredMinorVersion = 0;
// Minor version of Flash required
var requiredRevision = 0;
// -----------------------------------------------------------------------------

function loadContent(url){
	parent.content.location.href = url;
}
function loadParentContent(url){
	parent.location.href = url;
}
function loadContentNewWindow(url){
	var upload=parent.window.open(url,'','height=600,width=700,scrollbars=yes,resizable=yes,toolbar=yes,menubar=no,location=no,directories=no');
}
// -->
</script>
</head>

<body scroll="no">
<script language="JavaScript" type="text/javascript">
<!--
// Version check for the Flash Player that has the ability to start Player Product Install (6.0r65)
var hasProductInstall = DetectFlashVer(6, 0, 65);

// Version check based upon the values defined in globals
var hasRequestedVersion = DetectFlashVer(requiredMajorVersion, requiredMinorVersion, requiredRevision);


// Check to see if a player with Flash Product Install is available and the version does not meet the requirements for playback
if ( hasProductInstall && !hasRequestedVersion ) {
	// MMdoctitle is the stored document.title value used by the installation process to close the window that started the process
	// This is necessary in order to close browser windows that are still utilizing the older version of the player after installation has completed
	// DO NOT MODIFY THE FOLLOWING FOUR LINES
	// Location visited after installation is complete if installation is required
	var MMPlayerType = (isIE == true) ? "ActiveX" : "PlugIn";
	var MMredirectURL = window.location;
    document.title = document.title.slice(0, 47) + " - Flash Player Installation";
    var MMdoctitle = document.title;

	AC_FL_RunContent(
		"src", "playerProductInstall",
		"FlashVars", "MMredirectURL="+MMredirectURL+'&MMplayerType='+MMPlayerType+'&MMdoctitle='+MMdoctitle+"",
		"width", "100%",
		"height", "100%",
		"align", "middle",
		"id", "FTE",
		"quality", "high",
		"bgcolor", "#bfcfff",
		"name", "FTE",
		"allowScriptAccess","sameDomain",
		"type", "application/x-shockwave-flash",
		"pluginspage", "http://www.adobe.com/go/getflashplayer"
	);
} else if (hasRequestedVersion) {
	// if we've detected an acceptable version
	// embed the Flash Content SWF when all tests are passed
	AC_FL_RunContent(
			"src", "FTE.4",
			"flashVars", "host=www.werelate.org&userName=<?php echo urlencode(@$_REQUEST['userName']); ?>&treeName=<?php echo urlencode(@$_REQUEST['treeName']); ?>&page=<?php echo urlencode(@$_REQUEST['page']); ?>",
			"width", "100%",
			"height", "100%",
			"align", "middle",
			"id", "FTE",
			"quality", "high",
			"bgcolor", "#bfcfff",
			"name", "FTE",
			"allowScriptAccess","sameDomain",
			"type", "application/x-shockwave-flash",
			"pluginspage", "http://www.adobe.com/go/getflashplayer"
	);
  } else {  // flash is too old or we can't detect the plugin
    var alternateContent = 'The Family Tree Explorer requires the Adobe Flash Player. '
   	+ '<a href=http://www.adobe.com/go/getflash/>Get Flash</a>';
    document.write(alternateContent);  // insert non-flash content
  }
// -->
</script>
<noscript>
  	<object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"
			id="FTE" width="100%" height="100%"
			codebase="http://fpdownload.macromedia.com/get/flashplayer/current/swflash.cab">
			<param name="movie" value="FTE.3.swf" />
			<param name="quality" value="high" />
			<param name="bgcolor" value="#bfcfff" />
			<param name="allowScriptAccess" value="sameDomain" />
			<param name="flashVars" value="host=www.werelate.org&userName=<?php echo urlencode(@$_REQUEST['userName']); ?>&treeName=<?php echo urlencode(@$_REQUEST['treeName']); ?>&page=<?php echo urlencode(@$_REQUEST['page']); ?>"/>
			<embed src="FTE.4.swf" quality="high" bgcolor="#bfcfff"
				width="100%" height="100%" name="FTE" align="middle"
				play="true"
				loop="false"
				quality="high"
				allowScriptAccess="sameDomain"
				type="application/x-shockwave-flash"
				pluginspage="http://www.adobe.com/go/getflashplayer"
				flashVars="userName=<?php echo urlencode(@$_REQUEST['userName']); ?>&treeName=<?php echo urlencode(@$_REQUEST['treeName']); ?>&page=<?php echo urlencode(@$_REQUEST['page']); ?>">
			</embed>
	</object>
</noscript>
</body>
</html>
