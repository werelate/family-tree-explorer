package org.werelate.fte.view
{
	import flash.events.Event;

	public class FindEvent extends Event
	{
		public var text:String;
		public var ns:int;
		
		public function FindEvent(ns:int, text:String) {
			super("find");
			this.ns = ns;
			this.text = text;
		}
	}
}