package org.werelate.fte.service
{
	import mx.logging.ILogger;
	import mx.logging.Log;
	import flash.events.Event;
	import mx.rpc.events.FaultEvent;
	import mx.controls.Alert;

	import org.werelate.fte.model.Model;
	import org.werelate.fte.command.Controller;
	import flash.net.FileReference;
	import flash.net.URLRequest;
	import flash.events.ProgressEvent;
	import org.werelate.fte.view.PleaseWait;
	import org.werelate.fte.util.StringUtils;
	
	public class WRServices
	{
		public static const STATUS_OK:int = 0;
		public static const STATUS_INVALID_ARG:int = -1;
		public static const STATUS_NOT_LOGGED_IN:int = -2;
		public static const STATUS_NOT_AUTHORIZED:int = -3;
		public static const STATUS_DB_ERROR:int = -4;
		public static const STATUS_DUP_KEY:int = -5;
		public static const STATUS_NOT_FOUND:int = -6;
		public static const STATUS_WIKI_ERROR:int = -7;
		public static const STATUS_GEDCOM_PROCESSING:int = -9;
		public static const STATUS_GEDCOM_WAITING:int = -10;
		public static const STATUS_GEDCOM_ERROR_START:int = -100;
		public static const STATUS_GEDCOM_ERROR:int = -100;
		public static const STATUS_GEDCOM_OVERLAP:int = -101;
		public static const STATUS_GEDCOM_NOT_GEDCOM:int = -102;
		public static const STATUS_GEDCOM_REGENERATE:int = -105;

		private static const logger:ILogger = Log.getLogger("WRServices");

		/** Reference to singleton instance of this class. */
		private static var _instance:WRServices;
		
		public function WRServices()
		{
		    _instance = this;
		}
		
		public static function get instance():WRServices
		{
		    return _instance;
		}
		
		public function openFamilyTreeExplorer(resultHandler:Function, asyncExecute:Boolean = false):void {
//			logger.debug("openFamilyTreeExplorer");
			var service:Service = new Service(Model.WR_INDEX_URL, {action:"ajax", rs:"wfOpenFamilyTreeExplorer"},
														 handleFault, resultHandler);
			if (asyncExecute) {
				service.asyncExecute();
			}
			else {
				service.syncExecute();
			}
		}
		
		public function createFamilyTree(userName:String, name:String, resultHandler:Function):void {
			var service:Service = new Service(Model.WR_INDEX_URL, 
				{action:"ajax", rs:"wfCreateFamilyTree", rsargs:"user=" + userName + "|name=" + name}, 
				handleFault, resultHandler);
			service.syncExecute();
		}

		public function renameFamilyTree(userName:String, name:String, newName:String, resultHandler:Function):void {
			var service:Service = new Service(Model.WR_INDEX_URL, 
				{action:"ajax", rs:"wfRenameFamilyTree", rsargs:"user=" + userName + "|name=" + name + "|newname=" + newName}, 
				handleFault, resultHandler);
			service.syncExecute();
		}

		public function copyFamilyTree(userName:String, name:String, newUserName:String, newName:String, resultHandler:Function):void {
			var service:Service = new Service(Model.WR_INDEX_URL, 
				{action:"ajax", rs:"wfCopyFamilyTree", rsargs:"user=" + userName + "|name=" + name + 
																			"|newuser=" + newUserName + "|newname=" + newName}, 
				handleFault, resultHandler);
			service.syncExecute();
		}

		public function openFamilyTree(userName:String, name:String, resultHandler:Function):void {
			var service:Service = new Service(Model.WR_INDEX_URL, 
				{action:"ajax", rs:"wfOpenFamilyTree", rsargs:"user=" + userName + "|name=" + name},
				handleFault, resultHandler);
			service.syncExecute();
		}
		
		public function listFamilyTrees(userName:String, resultHandler:Function):void {
			var service:Service = new Service(Model.WR_INDEX_URL,
				{action:"ajax", rs:"wfListFamilyTrees", rsargs:"user=" + userName},
				handleFault, resultHandler);
			service.asyncExecute();
		}
		
		public function deleteFamilyTree(userName:String, treeName:String, resultHandler:Function):void {
			var service:Service = new Service(Model.WR_INDEX_URL,
				{action:"ajax", rs:"wfDeleteFamilyTree", 
				 rsargs:"user=" + userName + "|name=" + treeName + "|delete_pages=1"},
				handleFault, resultHandler);
			service.asyncExecute("Deleting tree...");
		}

		public function createFamilyTreePage(ns:int, title:String, content:String, resultHandler:Function):void {
			var args:String = "<create user=\"" + StringUtils.escapeXml(Model.instance.userName) + 
					"\" name=\"" + StringUtils.escapeXml(Model.instance.treeName) + 
					"\" ns=\"" + ns + 
					"\" title=\"" + StringUtils.escapeXml(title) + 
					"\">" + StringUtils.escapeXml(content) +
					"</create>";
			var service:Service = new Service(Model.WR_INDEX_URL,
				{action:"ajax", rs:"wfCreateFamilyTreePage", rsargs:args},
				handleFault, resultHandler, false);
			service.syncExecute();
		}
		
		public function addPage(ns:int, title:String, resultHandler:Function):void {
			if (Model.instance.userName == Model.instance.defaultUserName) {
				var service:Service = new Service(Model.WR_INDEX_URL, 
					{action:"ajax", rs:"wfAddFamilyTreePage", 
					 rsargs:"user=" + Model.instance.userName + "|name=" + Model.instance.treeName + "|ns=" + ns + "|title=" + title}, 
					handleFault, resultHandler);
				service.asyncExecute("Adding page...");
			}
			else {
				notAuthorized(StringUtils.isEmpty(Model.instance.defaultUserName), "add pages to this tree");
			}
		}
		
		public function removePage(ns:int, title:String, deletePage:Boolean, resultHandler:Function):void {
			if (Model.instance.userName == Model.instance.defaultUserName) {
				var service:Service = new Service(Model.WR_INDEX_URL, 
					{action:"ajax", rs:"wfRemoveFamilyTreePage", 
					 rsargs:"user=" + Model.instance.userName + "|name=" + Model.instance.treeName + 
					 "|ns=" + ns + "|title=" + title + (deletePage ? "|delete_page=1" : "")}, 
					handleFault, resultHandler);
				service.asyncExecute("Removing page...");
			}
			else {
				notAuthorized(StringUtils.isEmpty(Model.instance.defaultUserName), "remove pages from this tree");
			}
		}
		
//		public function acceptPage(ns:int, title:String, resultHandler:Function):void {
//			var service:Service = new Service(Model.WR_INDEX_URL, 
//				{action:"ajax", rs:"wfAcceptFamilyTreePage", 
//				 rsargs:"user=" + Model.instance.userName + "|name=" + Model.instance.treeName + "|ns=" + ns + "|title=" + title}, 
//				handleFault, resultHandler);
//			service.asyncExecute("Accepting changes...");
//		}
		
		public function bookmarkPage(ns:int, title:String, resultHandler:Function):void {
			if (Model.instance.userName == Model.instance.defaultUserName) {
				var service:Service = new Service(Model.WR_INDEX_URL, 
					{action:"ajax", rs:"wfBookmarkFamilyTreePage", 
					 rsargs:"user=" + Model.instance.userName + "|name=" + Model.instance.treeName + "|ns=" + ns + "|title=" + title}, 
					handleFault, resultHandler);
				service.asyncExecute("Bookmarking page...");
			}
			else {
				notAuthorized(StringUtils.isEmpty(Model.instance.defaultUserName), "bookmark pages");
			}
		}
		
		public function unbookmarkPage(ns:int, title:String, resultHandler:Function):void {
			if (Model.instance.userName == Model.instance.defaultUserName) {
				var service:Service = new Service(Model.WR_INDEX_URL, 
					{action:"ajax", rs:"wfUnbookmarkFamilyTreePage", 
					 rsargs:"user=" + Model.instance.userName + "|name=" + Model.instance.treeName + "|ns=" + ns + "|title=" + title}, 
					handleFault, resultHandler);
				service.asyncExecute("Removing bookmark...");
			}
			else {
				notAuthorized(StringUtils.isEmpty(Model.instance.defaultUserName), "unbookmark pages");
			}
		}
		
		public function savePrimaryPage(userName:String, name:String, ns:int, title:String, resultHandler:Function):void {
			if (userName == Model.instance.defaultUserName) {
				var service:Service = new Service(Model.WR_INDEX_URL, 
					{action:"ajax", rs:"wfSetPrimaryFamilyTreePage", 
					 rsargs:"user=" + userName + "|name=" + name + "|ns=" + ns + "|title=" + title},
					handleFault, resultHandler);
				service.asyncExecute("Setting primary page...");
			}
		}
		
		public function downloadPages(requests:Array, userName:String, treeName:String, resultHandler:Function, faultHandler:Function = null):void {
			var args:String = "<download user=\"" + StringUtils.escapeXml(userName) + "\" name=\"" + StringUtils.escapeXml(treeName) + "\">";
			for each (var request:Object in requests) {
				args += "<page ns=\"" + request.ns + "\" title=\"" + StringUtils.escapeXml(request.title) + "\"" +
						(request.getOldid ? " oldid=\"1\"" : "") + 
						(request.getData ? " data=\"1\"" : "") + 
						"/>";
			}
			args += "</download>";
			var service:Service = new Service(Model.WR_INDEX_URL,
				{action:"ajax", rs:"wfDownloadFamilyTreePages", rsargs:args},
				faultHandler == null ? handleFault : faultHandler, resultHandler, false);
			service.asyncExecute();
		}
		
//		public function importGedcom(userName:String, treeName:String, fileReference:FileReference, resultHandler:Function):void {
//			var ms:ModalService = new ModalService(Model.WR_INDEX_URL, 
//				{action:"ajax", rs:"wfUploadGedcom", rsargs:"user=" + userName + "|name=" + treeName},
//				handleFault, resultHandler);
//			ms.uploadFile(fileReference);
//		}
		
		public function updateData(userName:String, treeName:String, ns:int, title:String,
											data:String, resultHandler:Function):void {
			var args:String = "<update user=\"" + StringUtils.escapeXml(userName) + "\" name=\"" + StringUtils.escapeXml(treeName) + 
									"\" ns=\"" + ns + "\" title=\"" + StringUtils.escapeXml(title) + "\">" +
									data + "</update>";
			var service:Service = new Service(Model.WR_INDEX_URL, 
				{action:"ajax", rs:"wfUpdateData", rsargs:args}, handleFault, resultHandler, false);
			service.asyncExecute("Updating page...");
		}
		
		private function handleFault(event:FaultEvent):void {
			Alert.show("Error communicating with server: " + event.type, "Error");
//			logger.debug("fault " + event.toString());
		}
		
		private function notAuthorized(needLogin:Boolean, msg:String = null):void {
			if (msg == null) {
				msg = "perform this function";
			}
			if (needLogin) {
				Alert.show("To " + msg + " you need to sign in", "Notice");
				Controller.instance.loadContent(Model.WR_WIKI_PATH + "Special:Userlogin");
			}
			else {
				Alert.show("To " + msg + " you need to save this tree as your own tree (click on File, then on Save As)", "Notice");
			}
		}
		
		public function handleError(status:int, message:String = ""):void {
			if (Model.instance.alertErrors) {
				switch (status) {
					case STATUS_OK:
						break;
					case STATUS_NOT_LOGGED_IN:
						notAuthorized(true, message);
						break;
					case STATUS_NOT_AUTHORIZED:
						notAuthorized(false, message);
						break;
					case STATUS_DB_ERROR:
						Alert.show("Database error - please try again later", "Error");
						break;
					case STATUS_DUP_KEY:
						Alert.show("An entry with this key already exists", "Notice");
						break;
					case STATUS_NOT_FOUND:
						Alert.show(message + " not found", "Notice");
						break;
					case STATUS_WIKI_ERROR:
						Alert.show("Error updating wiki page", "Error");
						break;
					case STATUS_GEDCOM_PROCESSING:
						Alert.show("Your GEDCOM is currently being processed.\nPlease try again in 10-60 minutes.  If it not ready then, please email dallan@werelate.org.", "Notice");
						break;
					case STATUS_INVALID_ARG:
					default:
						Alert.show("Internal error: " + status, "Error");
						break;
				}
			}
		}
	}
}