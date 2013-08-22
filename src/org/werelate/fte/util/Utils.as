package org.werelate.fte.util
{
	import mx.utils.URLUtil;
	import org.werelate.fte.model.Model;
	import flash.utils.unescapeMultiByte;
	import flash.utils.escapeMultiByte;
	import flash.utils.Timer;
	
	public class Utils
	{
		private static const urlSpaceRegExp:RegExp = /[+_]/g;
		private static const spaceRegExp:RegExp = / /g;
		private static const slashRegExp:RegExp = /%2F/g;
		
		public static function decodeUrl(url:String):String {
			return unescapeMultiByte(url).replace(urlSpaceRegExp, " ");
		}
		
		public static function encodeUrl(url:String):String {
			// MediaWiki wants /'s in titles to not be encoded
			return escapeMultiByte(url.replace(spaceRegExp, " ")).replace(slashRegExp, "/");
		}
		
		public static function encodeUrlParams(params:Object):String {
			var result:String = "";
			for (var key:String in params) {
				var value:String = params[key];
				if (result.length > 0) {
					result += "&";
				}
				result += encodeUrl(key) + "=" + encodeUrl(value);
			}
			return result;
		}
		
		private static function getURLPathDecoded(url:String):String {
			url = decodeUrl(url);
			var pos:int = url.indexOf("://");
			if (pos > 0) {
				pos = url.indexOf("/", pos+3);
				if (pos >= 0) {
					return url.substr(pos);
				}
			}
			return "";
		}
		
		public static function isWeRelatePage(url:String):Boolean {
			if (url == null || url.length == 0) {
				return false;
			}
			var server:String = URLUtil.getServerName(url);
			return (server == "werelate.org" || StringUtils.endsWith(server, ".werelate.org"));
		}
		
		public static function isSelectable(url:String):Boolean {
			return isWeRelatePage(url) && isSelectableNs(getNsFromTitleNs(getTitleNsFromUrl(url)));
		}
		
		public static function isSelectableNs(ns:int):Boolean {
			for each (var fteNs:int in Model.instance.selectableNamespaces) {
				if (ns == fteNs) {
					return true;
				}
			}
			return false;
		}
		
		public static function getTitleFromTitleNs(titleNs:String):String {
			if (titleNs != "") {
				var pos:int = titleNs.indexOf(":");
				// if part before the : is a valid namespace
				if (pos > 0 && getNsInt(titleNs.substr(0, pos)) != 0) {
					return titleNs.substr(pos+1);
				}
				else {
					return titleNs;
				}
			}
			return "";
		}
		
		// return 0 if not one of the other namespaces
		public static function getNsFromTitleNs(titleNs:String):int {
			if (titleNs != "") {
				var pos:int = titleNs.indexOf(":");
				if (pos > 0) {
					return getNsInt(titleNs.substring(0, pos));
				}
			}
			return Model.MAIN_NS;
		}
		
		public static function getNsInt(nsString:String):int {
			nsString = nsString.toLowerCase();
			for each (var ns:Object in Model.instance.allNamespaces) {
				var label:String = ns.label.toLowerCase();
				if (ns.ns != 0 && label == nsString) {
					return ns.ns;
				}
			}
			return Model.MAIN_NS;
		}
		
		public static function getNsString(nsInt:int):String {
			for each (var ns:Object in Model.instance.allNamespaces) {
				if (ns.ns == nsInt) {
					return ns.label;
				}
			}
			return "";
		}
		
		public static function getTitleNs(nsInt:int, title:String):String {
			return getNsString(nsInt) + ":" + title;
		}

		public static function getTitleNsFromUrl(url:String):String {
			var title:String = "";
			var path:String = getURLPathDecoded(url);
			var pos:int;
			if (path.indexOf("/w/index.php?") == 0 || path.indexOf("/wiki/Special:ShowPedigree?") == 0) {
				pos = path.indexOf("title=");
				if (pos >= 0) {
					var endPos:int = path.indexOf("&", pos);
					title = path.substring(pos + "title=".length, endPos >= 0 ? endPos : path.length);
				}
			}
			else if (path.indexOf("/wiki/") == 0) {
				title = path.substr("/wiki/".length);
			}
			// strip off trailing #
			pos = title.indexOf('#');
			if (pos >= 0) {
				title = title.substr(0, pos);
			}
			return title;
		}
		
		public static function getTalkNs(ns:int):int {
			return (ns % 2 == 1 ? ns : ns + 1);
		}
		
		public static function getMainNs(ns:int):int {
			return (ns % 2 == 0 ? ns : ns - 1);
		}
		
		public static function arraySetDiff(a:Array, b:Array):Array {
			var result:Array = new Array();
			for each (var e:* in a) {
				if (b.indexOf(e) == -1) {
					result.push(e);
				}
			}
			for each (e in b) {
				if (a.indexOf(e) == -1) {
					result.push(e);
				}
			}
			return result;
		}
		
		public static function arrayListDiff(a:Array, b:Array):Boolean {
			if (a.length != b.length) {
				return true;
			}
			for (var i:int = 0; i < a.length; i++) {
				if (a[i] != b[i]) {
					return true;
				}
			}
			return false;
		}
		
		public static function activateTimer(timer:Timer):void {
			if (!timer.running) {
				timer.reset();
				timer.start();
			}
		}
		
		public static function summation(s:int):int {
			s = Math.abs(s);
			var r:int = 0;
			for (var i:int = 1; i <= s; i++) {
				r += i;
			}
			return r;
		}
	}
}