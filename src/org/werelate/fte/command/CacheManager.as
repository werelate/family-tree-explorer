package org.werelate.fte.command
{
	import mx.logging.ILogger;
	import mx.logging.Log;
	import org.werelate.fte.model.Page;
	import org.werelate.fte.service.WRServices;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.events.FaultEvent;
	import org.werelate.fte.model.Model;
	import flash.net.SharedObject;
	import flash.net.SharedObjectFlushStatus;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.events.Event;
	import org.werelate.fte.util.StringUtils;
	import mx.core.UIComponent;
	import mx.core.Application;
	import org.werelate.fte.view.PleaseWait;
	import mx.managers.PopUpManager;
	import flash.display.DisplayObject;
	import mx.controls.Alert;
	import org.werelate.fte.util.Utils;

	public class CacheManager
	{
		private static const logger:ILogger = Log.getLogger("CacheManager");
		private static const DOWNLOAD_TIMER_DELAY:int = 250;
		private static const CACHEALL_TIMER_DELAY:int = 500; // give screen time to repaint
		private static const CHECK_REQUESTS_TIMER_DELAY:int = 2000;
		private static const MAX_DOWNLOAD_REQUESTS:int = 100;
		private static const MAX_CACHEALL_REQUESTS:int = 10000;
		private static var filenameRegExp:RegExp = /[^0-9A-Za-z()\-]/g;

		private var requests:Array;
		private var dlTimer:Timer;
		private var crTimer:Timer;
		private var pleaseWait:PleaseWait;
		private var pagesToCache:int;
		private var treeCache:TreeCache;
		
		public function CacheManager() {
			requests = new Array();
			dlTimer = new Timer(DOWNLOAD_TIMER_DELAY,1); // wait between page downloadrequests
			dlTimer.addEventListener(TimerEvent.TIMER_COMPLETE, downloadPages);
			crTimer = new Timer(CHECK_REQUESTS_TIMER_DELAY,1); // wait between request queue checks
			crTimer.addEventListener(TimerEvent.TIMER_COMPLETE, checkRequestQueue);
			treeCache = null;
		}
		
		public static function getCacheKey(key:String):String {
			return StringUtils.romanize(key).replace(filenameRegExp,"_");
		}
		
		public function openTreeCache(userName:String, fileName:String):void {
			treeCache = new TreeCache(userName, fileName);
		}
		
		public function closeTreeCache():void {
			if (treeCache != null) {
				treeCache.flush();
				treeCache = null;
			}
		}
		
		public function uncacheTree():void {
			if (treeCache != null) {
				treeCache.remove();
				treeCache = null;
			}
		}
		
		public function copyTree(newUserName:String, newTreeName:String):void {
			if (treeCache != null) {
				treeCache.copy(newUserName, newTreeName);
			}
		}
		
//		public function migrateTreeCache(pages:Object):void {
//			treeCache.migrate(pages);
//		}
		
		public function cachePage(page:Page, forceDownload:Boolean = false):void {
			if (page != null && page.isInTree && (!page.isCached || !page.isCacheCurrent() || forceDownload)) {
				var getPage:Boolean = false;
				var getData:Boolean = false;
				var request:Object = removeFromRequests(page, true);
				if (request == null) { // isn't already in request queue
//					logger.info("cachePage: " + page.title + " " + (page.isInTree ? "t " : "f ") + status);
					var status:int = treeCache.readPage(page); // is it already cached?
					if (forceDownload || status != TreeCache.UPDATE_FOUND) {
						// this is a little inefficient because we read the cache in the event
						// of a forced download to determine whether we need to request the data
						getPage = true;
						getData = (status == TreeCache.UPDATE_NEED_DATA);
					}
				}
				else { // previously put into queue
					getPage = true;
					if (request.forceDownload) {
						forceDownload = true;
					}
					getData = request.getData;
				}
				if (getPage) {
					addToRequests(page, forceDownload, getData);
					Utils.activateTimer(dlTimer);
				}
			}
		}
		
		public function uncachePage(page:Page):void {
			treeCache.uncachePage(page);
			page.isCached = false;
		}
		
 		public function updateData(page:Page):void {
			treeCache.cachePage(page, "", page.data, true);
			treeCache.flush();
 		}
 		
 		public function cacheAllPages():void {
// 			logger.info("cacheAllPages");
 			pleaseWait = new PleaseWait();
 			pleaseWait.title = "Reading Pages";
			// set the popup click handler to the cancel function
			pleaseWait.addEventListener("close", handlePleaseWaitClose);
			// show the popup
			PopUpManager.addPopUp(pleaseWait, DisplayObject(Application.application), true);
			PopUpManager.centerPopUp(pleaseWait);
			PopUpManager.bringToFront(pleaseWait);
	 		pleaseWait.validateNow();
			Model.instance.suspendViewUpdate = true;
 			pagesToCache = 0;
 			for each (var page:Page in Model.instance.pages.allPages) {
 				if (page.isInTree && !page.isCached) {
	 				cachePage(page);
	 				pagesToCache++;
	 			}
	 		}
 			if (requests.length > 0) {
	 			Utils.activateTimer(crTimer);
 			}
 			else {
 				handlePleaseWaitClose(new Event("close"));
 			}
 		}
 		
		private function checkRequestQueue(event:Event):void {
			if (requests.length > 0) {
				pleaseWait.setProgress(pagesToCache - requests.length, pagesToCache);
				Utils.activateTimer(crTimer);
			}
			else {
				handlePleaseWaitClose(event);
			}
		}
		
		private function handlePleaseWaitClose(event:Event):void {
			PopUpManager.removePopUp(pleaseWait);
			Model.instance.suspendViewUpdate = false;
			Model.instance.pages.computeIndexPages(false);
		}
		
		private function addToRequests(page:Page, forceDownload:Boolean, getData:Boolean):void {
//			logger.info("addToRequests " + page.title);
			requests.push({page:page, forceDownload:forceDownload, getData:getData});
		}
		
		// returns the removed request, or null if not found
		private function removeFromRequests(page:Page, forceDownload:Boolean):Object {
			for (var i:int = 0; i < requests.length; i++) {
				if (requests[i].page == page && (forceDownload || !requests[i].forceDownload)) {
					return requests.splice(i, 1)[0];
				}
			}
			return null;
		}
		
		private function downloadPages(event:Event):void {
//			logger.debug("downloadPages " + requests.length);
			var downloadRequests:Array = new Array();
			while (requests.length > 0 && downloadRequests.length < MAX_DOWNLOAD_REQUESTS) {
				var request:Object = requests.pop();
				var page:Page = request.page;
				if (page.isInTree) {
					// if we're forcing the download, we also want to get the updated oldid
					// this is inefficient when the user has just edited the page and we know the new oldid already
					downloadRequests.push({ns:page.ns, title:page.title, 
												getOldid:request.forceDownload, getData:request.getData});
				}
			}
			if (downloadRequests.length > 0) {
//				logger.warn("downloading " + downloadRequests.length);
				Model.instance.status.setMessage("cache", "Caching pages...");
				WRServices.instance.downloadPages(downloadRequests, Model.instance.userName, Model.instance.treeName, 
																handleResult, handleFault);
			}
			else {
				Model.instance.status.setMessage("cache", "");
				treeCache.flush(); // flush cache when we reach a steady state
			}
		}
		
		private function handleResult(event:ResultEvent):void {
			var status:int = event.result.@status;
//			logger.warn("downloadPage result" + status);
			if (status != WRServices.STATUS_OK && status != WRServices.STATUS_NOT_FOUND) {
				WRServices.instance.handleError(status);
				Model.instance.status.setMessage("cache", "");
			}
			else {
				if (status == WRServices.STATUS_NOT_FOUND) {
//					logger.warn("downloadPage not found");
				}
				for each (var pageXml:XML in event.result.page) {
//					logger.debug("download page " + pageXml.@ns + " " + pageXml.@title + 
//										" " + pageXml.@revid + " " + pageXml.@oldid);
					// get page
					var page:Page = Model.instance.pages.getPage(pageXml.@ns, pageXml.@title);
					if (page.isInTree) {
						var text:String = String(pageXml);
						var data:String = String(pageXml.@data);
						page.latest = int(pageXml.@revid);
						// cache page
						treeCache.cachePage(page, text, data);

						// update page
						var requestedOldid:Boolean = false;
						if (pageXml.@oldid && int(pageXml.@oldid) > 0) {
							requestedOldid = true;
							page.oldid = int(pageXml.@oldid);
//							page.setLastmod(pageXml.@user, pageXml.@date, pageXml.@comment);
						}
						var changeCandidates:Array = page.setFields(text, data);
						
						// fetch change candidates
						for each (var candidate:Page in changeCandidates) {
							if (candidate.isInTree && candidate.isCached) {
//								logger.warn("handleResult cachePage " + candidate.title);
								cachePage(candidate, true);
							}
						}
						// remove this page if it got into the request queue while we were waiting for it
						// if we got an oldid, we were also forcing the download
						removeFromRequests(page, requestedOldid);
					}
				}
				// wait a little while and download the next set of pages
				Utils.activateTimer(dlTimer);
			}
		}
		
		private function handleFault(event:FaultEvent):void {
//			logger.debug("fault " + event.toString());
			Model.instance.status.setMessage("cache", "Error occurred while caching pages");
			Utils.activateTimer(dlTimer); // try again
		}
	}
}
