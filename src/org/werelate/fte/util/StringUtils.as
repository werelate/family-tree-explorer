package org.werelate.fte.util
{
	public class StringUtils
	{
		public static function endsWith(haystack:String, needle:String):Boolean {
			return haystack.length >= needle.length && 
						haystack.substr(haystack.length - needle.length) == needle;
		}
		
		public static function escapeXml(s:String):String {
			// escape <>&"'
			return s.replace(/&/g,'&amp;').
        	 			replace(/</g,'&lt;').
        	 			replace(/>/g,'&gt;').
        	 			replace(/\"/g,'&quot;').
        	 			replace(/'/g,'&apos;');
		}
		
		public static function unescapeXml(s:String):String {
			// unescape <>&"'
			return s.replace(/&lt;/g,'<').
        	 			replace(/&gt;/g,'>').
        	 			replace(/&quot;/g,'"').
        	 			replace(/&apos;/g,"'").
        	 			replace(/&amp;/g,'&');
		}
		
		public static function strcmp(s1:String, s2:String):int {
			if (s1 < s2) {
				return -1;
			}
			else if (s1 > s2) {
				return 1;
			}
			return 0;
		}
		
		public static function stricmp(s1:String, s2:String):int {
			return StringUtils.strcmp(s1.toLowerCase(), s2.toLowerCase());
		}
		
		private static var separatorRegExp:RegExp = /[ \.\'\-]/;
		
		public static function toMixedCase(s:String):String {
			var result:String = "";
			var prevChar:String = "";
			for (var i:int = 0; i < s.length; i++) {
				var ch:String = s.charAt(i);
				if (i == 0 || prevChar.search(separatorRegExp) != -1) {
					result += ch.toUpperCase();
				}
				else {
					result += ch.toLowerCase();
				}
				prevChar = ch;
			}
			return result;
		}
		
		private static var translate:Object = {
			"\u00c0":"A", "\u00c1":"A", "\u00c2":"A", "\u00c3":"A", "\u00c4":"A", "\u00c5":"A", "\u00c6":"Ae", "\u00c7":"C",
			"\u00c8":"E", "\u00c9":"E", "\u00ca":"E", "\u00cb":"E", "\u00cc":"I", "\u00cd":"I", "\u00ce":"I", "\u00cf":"I", 
			"\u00d0":"D", "\u00d1":"N", "\u00d2":"O", "\u00d3":"O", "\u00d4":"O", "\u00d5":"O", "\u00d6":"O", 
			"\u00d8":"O", "\u00d9":"U", "\u00da":"U", "\u00db":"U", "\u00dc":"U", "\u00dd":"Y", "\u00de":"Th", "\u00df":"Ss", 
			"\u00e0":"a", "\u00e1":"a", "\u00e2":"a", "\u00e3":"a", "\u00e4":"a", "\u00e5":"a", "\u00e6":"ae", "\u00e7":"c", 
			"\u00e8":"e", "\u00e9":"e", "\u00ea":"e", "\u00eb":"e", "\u00ec":"i", "\u00ed":"i", "\u00ee":"i", "\u00ef":"i",
			"\u00f0":"o", "\u00f1":"n", "\u00f2":"o", "\u00f3":"o", "\u00f4":"o", "\u00f5":"o", "\u00f6":"o", 
			"\u00f8":"o", "\u00f9":"u", "\u00fa":"u", "\u00fb":"u", "\u00fc":"u", "\u00fd":"y", "\u00fe":"th", "\u00ff":"y"
		};

		public static function romanize(s:String):String {
			var result:Array = new Array(s.length);
			for (var i:int = 0; i < s.length; i++) {
				if (s.charCodeAt(i) >= 128) {
					var ch:String = translate[s.charAt(i)];
					if (ch == null || ch.length == 0) {
						ch = "?"
					}
					result[i] = ch;
				}
				else {
					result[i] = s.charAt(i);
				}
			}
			return result.join("");
		}
		
		public static function isEmpty(s:String):Boolean {
			return s == null || s.length == 0;
		}
	}
}