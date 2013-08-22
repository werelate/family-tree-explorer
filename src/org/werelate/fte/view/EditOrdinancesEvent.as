package org.werelate.fte.view
{
	import flash.events.Event;

	public class EditOrdinancesEvent extends Event
	{
		public var ordinances:XMLList;
		
		public function EditOrdinancesEvent(ordinances:XMLList) {
			super("ok");
			this.ordinances = ordinances;
		}
	}
}