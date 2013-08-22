package org.werelate.fte.model
{
	import mx.utils.StringUtil;
	
	public class BasicPersonInfo
	{
		public var living:Boolean;
		public var given:String;
		public var surname:String;
		
		public function BasicPersonInfo(living:Boolean, given:String, surname:String):void {
			this.living = living;
			this.given = (given != null && StringUtil.trim(given).length > 0 ? StringUtil.trim(given) : null);
			this.surname = (surname != null && StringUtil.trim(surname).length > 0 ? StringUtil.trim(surname) : null);
		}
	}
}