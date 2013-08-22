package org.werelate.fte.view
{
	import flash.events.Event;

	public class AddAncestorsEvent extends Event
	{
		public var people:Array;
		
		public function AddAncestorsEvent(people:Array):void {
			super("addAncestors");
			this.people = people;
		}
	}
}