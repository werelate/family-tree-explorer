package org.werelate.fte.command
{
	import mx.preloaders.DownloadProgressBar;
	import flash.events.Event;
	import mx.rpc.events.ResultEvent;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import org.werelate.fte.view.RenameFamilyTreeView;
	import mx.core.Application;
	import flash.display.DisplayObject;
	import mx.managers.PopUpManager;
	import org.werelate.fte.service.WRServices;
	import mx.containers.TitleWindow;
	import org.werelate.fte.model.Model;
	import org.werelate.fte.view.CopyFamilyTreeView;
	import org.werelate.fte.view.CopyEvent;
	import mx.controls.Alert;
	
	public class CopyFamilyTree implements Command
	{
		private static const logger:ILogger = Log.getLogger("CopyFamilyTree");

		private var popup:TitleWindow;
		private var newUserName:String;
		private var newFileName:String;

		public function execute():void {
			if (Model.instance.defaultUserName != null) {
				// pop up dialog to get tree name
				popup = new CopyFamilyTreeView();
				popup.addEventListener("close", handleClose);
				popup.addEventListener("copy", handleCopy);
				PopUpManager.addPopUp(popup, DisplayObject(Application.application), true);
				PopUpManager.centerPopUp(popup);
			}
			else {
				WRServices.instance.handleError(WRServices.STATUS_NOT_LOGGED_IN, "save this tree");
			}
		}

		private function handleClose(event:Event):void {
//			logger.debug("close " + event.toString());
			PopUpManager.removePopUp(popup);
		}
		
		private function handleCopy(event:CopyEvent):void {
			this.newUserName = Model.instance.defaultUserName;
			this.newFileName = event.fileName;
//			logger.debug("copy " + event.fileName);
			handleClose(event);
			WRServices.instance.copyFamilyTree(Model.instance.userName, Model.instance.treeName, 
															this.newUserName, this.newFileName, handleResult);
		}
		
		private function handleResult(event:ResultEvent):void {
//			logger.debug("CopyFamilyTree result " + newUserName + "/" + newFileName + ":" + event.result.toString());
			var status:int = event.result.@status;
			if (status != WRServices.STATUS_OK) {
				WRServices.instance.handleError(status);
			}
			else {
				Alert.show("The tree has copied successfully.\nYou will be added as a 'Watcher' to the pages in the next 10-15 minutes.", "Notice");
				Controller.instance.cacheManager.copyTree(newUserName, newFileName);
				Model.instance.copySettings(newUserName, newFileName);
				Controller.instance.doFileClose();
				var oft:OpenFamilyTree = new OpenFamilyTree();
				oft.doOpen(newUserName, newFileName, null);
			}
		}
	}
}
