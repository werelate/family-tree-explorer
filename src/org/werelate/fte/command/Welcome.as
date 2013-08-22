package org.werelate.fte.command
{
	import mx.logging.ILogger;
	import mx.logging.Log;
	import flash.events.Event;
	import mx.containers.TitleWindow;
	import mx.managers.PopUpManager;
	import flash.display.DisplayObject;
	import mx.core.Application;
	import org.werelate.fte.view.WelcomeView;
	
	public class Welcome implements Command
	{
		private static const logger:ILogger = Log.getLogger("Welcome");

		private var popup:TitleWindow;
		private var userName:String;
		private var fileName:String;
		
		public function execute():void {
			popup = new WelcomeView();
			popup.addEventListener("close", handleClose);
			popup.addEventListener("open", handleOpen);
			popup.addEventListener("create", handleCreate);
			PopUpManager.addPopUp(popup, DisplayObject(Application.application), true);
			PopUpManager.centerPopUp(popup);
		}
		
		private function handleClose(event:Event):void {
//			logger.debug("close " + event.toString());
			PopUpManager.removePopUp(popup);
		}
		
		private function handleCreate(event:Event):void {
//			logger.debug("create ");
			handleClose(event);
			Controller.instance.fileNew();
		}
		
		private function handleOpen(event:Event):void {
//			logger.debug("open ");
			handleClose(event);
			Controller.instance.fileOpen();
		}
	}
}