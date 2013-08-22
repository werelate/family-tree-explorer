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
	import org.werelate.fte.view.RenameEvent;
	
	public class RenameFamilyTree implements Command
	{
		private static const logger:ILogger = Log.getLogger("RenameFamilyTree");

		private var popup:TitleWindow;
		private var newFileName:String;
		private var userName:String;

		public function execute():void {
			popup = new RenameFamilyTreeView();
			popup.addEventListener("close", handleClose);
			popup.addEventListener("rename", handleRename);
			PopUpManager.addPopUp(popup, DisplayObject(Application.application), true);
			PopUpManager.centerPopUp(popup);
		}

		private function handleClose(event:Event):void {
//			logger.debug("close " + event.toString());
			PopUpManager.removePopUp(popup);
		}
		
		private function handleRename(event:RenameEvent):void {
			this.newFileName = event.fileName;
			this.userName = Model.instance.userName;
//			logger.debug("rename " + event.fileName);
			handleClose(event);
			WRServices.instance.renameFamilyTree(userName, Model.instance.treeName, this.newFileName, handleResult);
		}
		
		private function handleResult(event:ResultEvent):void {
//			logger.debug("RenameFamilyTree result " + newFileName + ":" + event.result.toString());
			var status:int = event.result.@status;
			if (status != WRServices.STATUS_OK) {
				WRServices.instance.handleError(status);
			}
			else {
				Controller.instance.cacheManager.copyTree(userName, newFileName);
				Model.instance.copySettings(userName, newFileName);
				Controller.instance.cacheManager.uncacheTree();
				Controller.instance.doFileClose();
				var oft:OpenFamilyTree = new OpenFamilyTree();
				oft.doOpen(userName, newFileName, null);
			}
		}
	}
}