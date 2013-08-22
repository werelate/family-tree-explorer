package org.werelate.fte.command
{
	import mx.logging.ILogger;
	import mx.logging.Log;
	import flash.events.Event;
	import mx.containers.TitleWindow;
	import mx.core.Application;
	import flash.display.DisplayObject;
	import mx.managers.PopUpManager;

	import org.werelate.fte.model.Model;
	import org.werelate.fte.view.FindEvent;
	import org.werelate.fte.view.FindView;
	
	public class Find implements Command
	{
		private static const logger:ILogger = Log.getLogger("Find");

		private var popup:TitleWindow;

		public function Find() {
			// nothing to do
		}		
		
		public function execute():void {
			popup = new FindView();
			popup.addEventListener("close", handleClose);
			popup.addEventListener("find", handleFind);
			PopUpManager.addPopUp(popup, DisplayObject(Application.application), true);
			PopUpManager.centerPopUp(popup);
		}
		
		private function handleClose(event:Event):void {
//			logger.debug("close " + event.toString());
			PopUpManager.removePopUp(popup);
		}
		
		private function handleFind(event:FindEvent):void {
//			logger.debug("find " + event.text);
			handleClose(event);
			Model.instance.selectedTab = Model.INDEX_TAB;
			Model.instance.selectedNamespace = event.ns;
			Model.instance.findText = event.text;
		}
	}
}