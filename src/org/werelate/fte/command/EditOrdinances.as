package org.werelate.fte.command
{
	import org.werelate.fte.model.Page;
	import org.werelate.fte.model.PersonPage;
	import org.werelate.fte.model.Model;
	import flash.events.Event;
	import org.werelate.fte.view.EditOrdinancesEvent;
	import mx.rpc.events.ResultEvent;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.containers.TitleWindow;
	import mx.managers.PopUpManager;
	import org.werelate.fte.model.FamilyPage;
	import org.werelate.fte.service.WRServices;
	import flash.display.DisplayObject;
	import mx.core.Application;
	import org.werelate.fte.view.EditPersonOrdinancesView;
	import org.werelate.fte.view.EditFamilyOrdinancesView;
	import org.werelate.fte.view.EditOrdinancesView;
	import org.werelate.fte.view.PleaseWait;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	public class EditOrdinances implements Command
	{
		private static const logger:ILogger = Log.getLogger("EditOrdinances");

		private var page:Page;
		private var pleaseWait:PleaseWait;
		private var popup:EditOrdinancesView;
		private var timer:Timer
		
		public function EditOrdinances(page:Page) {
			this.page = page;
		}		
		
		public function execute():void {
			// request to cache the page
			Controller.instance.cacheManager.cachePage(page);
			if (!page.isCached) {
				// put up a please wait dialog
				pleaseWait = new PleaseWait();
				// set the popup click handler to the cancel function
				pleaseWait.addEventListener("close", handlePleaseWaitClose);
				// show the popup
				PopUpManager.addPopUp(pleaseWait, DisplayObject(Application.application), true);
				PopUpManager.centerPopUp(pleaseWait);
				// activate a timer to check for the page being cached every 250ms
				timer = new Timer(250,0);
				timer.addEventListener(TimerEvent.TIMER, checkCached);
				timer.start();
			}
			else {
				editOrdinances();
			}
		}
		
		private function handlePleaseWaitClose(event:Event):void {
			PopUpManager.removePopUp(pleaseWait);
//			logger.debug("close " + event.toString());
		}
		
		private function checkCached(event:Event):void {
			if (page.isCached) {
				timer.stop();
				handlePleaseWaitClose(event);
				editOrdinances();
			}
		}
		
		private function editOrdinances():void {
			if (page.ns == Model.PERSON_NS) {
				popup = new EditPersonOrdinancesView();
			}
			else {
				popup = new EditFamilyOrdinancesView();
			}
			popup.init(page.dataAsXML);
			popup.addEventListener("close", handleClose);
			popup.addEventListener("ok", handleOk);
			PopUpManager.addPopUp(popup, DisplayObject(Application.application), true);
			PopUpManager.centerPopUp(popup);
		}
		
		private function handleClose(event:Event):void {
//			logger.debug("close " + event.toString());
			PopUpManager.removePopUp(popup);
		}
		
		private function handleOk(event:EditOrdinancesEvent):void {
			handleClose(event);
			if (page.ns == Model.PERSON_NS) {
				PersonPage(page).updateOrdinances(event.ordinances);
			}
			else {
				FamilyPage(page).updateOrdinances(event.ordinances);
			}
			WRServices.instance.updateData(Model.instance.userName, Model.instance.treeName, 
					page.ns, page.title, page.data, handleResult);
		}
		
		private function handleResult(event:ResultEvent):void {
//			logger.debug("handleResult dataVersion=" + event.result.@dataVersion);
			var status:int = event.result.@status;
			if (status != WRServices.STATUS_OK) {
				WRServices.instance.handleError(status);
			}
			else {
				page.dataVersion = event.result.@dataVersion;
				Controller.instance.cacheManager.updateData(page);
			}
		}
	}
}
