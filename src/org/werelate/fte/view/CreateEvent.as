package org.werelate.fte.view
{
	import flash.events.Event;

	public class CreateEvent extends Event
	{
		public var fileName:String;
		
		public function CreateEvent(fileName:String) {
			super("create");
			this.fileName = fileName;
		}
	}
}