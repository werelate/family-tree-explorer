package org.werelate.fte.view
{
	import flash.events.Event;

	public class CopyEvent extends Event
	{
		public var fileName:String;
		
		public function CopyEvent(fileName:String) {
			super("copy");
			this.fileName = fileName;
		}
	}
}