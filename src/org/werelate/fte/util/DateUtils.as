package org.werelate.fte.util
{
	public class DateUtils
	{
		private static var months:Object = {january:1, february:2, march:3, april:4, may:5, june:6, july:7, august:8, september:9, october:10, november:11, december:12,
														jan:1, feb:2, mar:3, apr:4, may:5, jun:6, jul:7, aug:8, sep:9, oct:10, nov:11, dec:12,
														febr:2, sept:9};
		private static var alphaNumRegExp:RegExp = /(\d+|[^0-9\s\'~!@#$%^&*()_+\-={}|:`<>?;,\/\"\[\]\.\\\\]+)/g;
		private static function isYear(y:int):Boolean {
			return y >= 1000 && y <= 2200;
		}		
		private static function getAlphaMonth(mon:String):int {
			mon = mon.toLowerCase();
			if (months[mon]) {
				return months[mon];
			}
			return 0;
		}
		private static function isDay(d:int):Boolean {
			return d >= 1 && d <= 31;
		}
		private static function isNumMonth(m:int):Boolean {
			return m >= 1 && m <= 12;
		}
		
		public static function getDateSortKey(date:String):String {
			var result:String = "";
			var year:int = 0;
			var month:int = 0;
			var day:int = 0;
			var monthError:Boolean = false;
			var dayError:Boolean = false;
			var fields:Array = date.match(alphaNumRegExp);
			for (var i:int = 0; i < fields.length; i++) {
				var field:String = fields[i];
				var num:int = int(field);
				if (isYear(num)) {
					if (year == 0) year = num;
				}
				else if (getAlphaMonth(field) > 0) {
					if (month > 0) monthError = true;
					month = getAlphaMonth(field);
				}
				else if (isDay(num) && (!isNumMonth(num) ||
												(i > 0 && getAlphaMonth(fields[i-1])) ||
												(i < fields.length - 1 && getAlphaMonth(fields[i+1])))) {
					if (day) dayError = true;
					day = num;
				}
				else if (i > 0 && isYear(int(fields[i-1]))) {
					// ignore -- probably 1963/4
				}
				else if (isNumMonth(num)) {
					if (month) monthError = true;
					month = num;
				}
			}
			if (year) {
				result = String(year);
				if (month > 0 && !monthError) {
					result += (month < 10 ? "0" + String(month) : String(month));
					if (day > 0 && !dayError) {
						result += (day < 10 ? "0" + String(day) : String(day));
					}
				}
			}
			return result;
		}
	}
}