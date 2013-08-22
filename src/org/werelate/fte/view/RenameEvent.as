package org.werelate.fte.view
{
	import flash.events.Event;

	public class RenameEvent extends Event
	{
		public var fileName:String;
		
		public function RenameEvent(fileName:String) {
			super("rename");
			this.fileName = fileName;
		}
	}
}