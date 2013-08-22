package org.werelate.fte.view
{
	import flash.events.Event;

	public class OpenEvent extends Event
	{
		public var userName:String;
		public var fileName:String;
		
		public function OpenEvent(userName:String, fileName:String) {
			super("open");
			this.userName = userName;
			this.fileName = fileName;
		}
	}
}