package org.werelate.fte.model
{
	import mx.core.UIComponent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import mx.logging.ILogger;
	import mx.logging.Log;

	/**
	 * Records status messages in a stack, where each message is associated with and ID
	 * so you can update a particular status message, and returns the top-most status message.
	 */
	public class Status extends EventDispatcher
	{
		private static const logger:ILogger = Log.getLogger("Status");

		private var statuses:Array;
	
		public function Status() {
			statuses = new Array();
   	   dispatchEvent(new Event("messageChanged"));
      }
      
		[Bindable("messageChanged")]
		public function get message():String {
			if (statuses.length > 0) {
				return statuses[statuses.length-1].message;
			}
			else {
				return "";
			}
		}
		
		public function setMessage(id:String, message:String):void {
			var found:int = -1;
			for (var i:int = 0; i < statuses.length; i++) {
				if (statuses[i].id == id) {
					found = i;
					break;
				}
			}
			var changed:Boolean = ((found == -1 && message.length > 0) || (found == statuses.length - 1));
			if (found == -1) {
				if (message.length > 0) {
//					logger.info("setMessage add " + id);
					statuses.push({id:id, message:message});
				}
			}
			else if (message.length > 0) {
//				logger.info("setMessage update " + id);
				statuses[found].message = message;
			}
			else {
//				logger.info("setMessage remove " + id);
				statuses.splice(found,1);
			}
			if (changed) {
				dispatchEvent(new Event("messageChanged"));
			}
		}
	}
}