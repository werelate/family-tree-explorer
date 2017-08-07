<?php
if(isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] != "https"){
    $redirect = 'https://' . $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI'];
    header('HTTP/1.1 301 Moved Permanently');
    header('Location: ' . $redirect);
    exit();
}
?>
<html>
<title>Family Tree Explorer</title>
<frameset cols="370,*">
<frame src="https://www.werelate.org/fte/FTE.php?userName=<?php echo urlencode(@$_REQUEST['userName']); ?>&treeName=<?php echo urlencode(@$_REQUEST['treeName']); ?>&page=<?php echo urlencode(@$_REQUEST['page']); ?>" name="fte"/>
<frame src="https://www.werelate.org/wiki/WeRelate:Family_Tree_Explorer" name="content"/>
<noframes>
<body>Your browser must support frames in order to use Family Tree Explorer</body>
</noframes>
</frameset>
</html>
