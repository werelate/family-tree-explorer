package org.werelate.fte.command
{
	import org.werelate.fte.model.Page;
	import org.werelate.fte.util.StringUtils;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.rpc.events.FaultEvent;
	import flash.events.NetStatusEvent;
	import flash.net.SharedObject;
	import flash.net.SharedObjectFlushStatus;
	import mx.controls.Alert;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.events.Event;
	import org.werelate.fte.util.Utils;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	
	public class TreeCache
	{
		public static const UPDATE_FOUND:int = 0;
		public static const UPDATE_NEED_PAGE:int = 1;
		public static const UPDATE_NEED_DATA:int = 2;

		private static const logger:ILogger = Log.getLogger("TreeCache");
		private static const SHARED_OBJECT_COUNT:int = 10;
//		private static const MIGRATION_TIMER_DELAY:int = 1000;
//		private static const MAX_MIGRATION_REQUESTS:int = 10;
		
		private var sharedObjects:Array;
		private var sharedObjectsDirty:Array;
		private var pendingIndex:int;
//		private var migrationQueue:Array;
//		private var migrationTimer:Timer;

		private static function getTreeCacheKey(userName:String, treeName:String, cacheSeq:int):String {
			return "pages-" + userName + "-" + treeName + "-" + cacheSeq;
		}
		
		public function TreeCache(userName:String, treeName:String) {
			sharedObjects = new Array(SHARED_OBJECT_COUNT);
			sharedObjectsDirty = new Array(SHARED_OBJECT_COUNT);
			pendingIndex = 0;
			for (var i:int = 0; i < SHARED_OBJECT_COUNT; i++) {
				sharedObjects[i] = SharedObject.getLocal(
					CacheManager.getCacheKey(getTreeCacheKey(userName, treeName, i)), "/");
				sharedObjectsDirty[i] = false;
			}
//			migrationTimer = new Timer(MIGRATION_TIMER_DELAY,1); // wait between page migration requests
//			migrationTimer.addEventListener(TimerEvent.TIMER_COMPLETE, migratePages);
		}
		
		public function remove():void {
			for (var i:int = 0; i < SHARED_OBJECT_COUNT; i++) {
//				logger.info("remove " + i);
			}
		}
		
		// returns UPDATE_FOUND, UPDATE_NEED_PAGE, or UPDATE_NEED_DATA (which implies need_page as well)
		public function readPage(page:Page):int {
			var key:String = getPageKey(page);
			var o:Object = readPageData(key);
//			logger.info("readPage " + key);
			if (o == null || o.revid != page.latest) {
//				logger.info("readPage not found " + page.ns + ":" + page.title + "->" + page.latest);
				// page.isCached = false; -- page is still cached, just out of date -- isCached needs to remain true
				if (page.dataVersion > 0 && (o == null || o.dataVersion != page.dataVersion)) {
					return UPDATE_NEED_DATA;
				}
				else {
					return UPDATE_NEED_PAGE;
				}
			}
			else if (page.dataVersion > 0 && o.dataVersion != page.dataVersion) {
//				logger.info("readPage need data " + page.ns + ":" + page.title + ":" + o.dataVersion + "->" + page.dataVersion);
				// a little inefficient here because if we just need the data, we're going to request
				// the page content as well.  But this should hardly ever happen.
				return UPDATE_NEED_DATA;
			}
			else {
				page.setFields(o.text, o.data);
				page.cacheVersion = o.revid;
				page.cacheDataVersion = o.dataVersion;
				return UPDATE_FOUND;
			}
		}
		
		public function cachePage(page:Page, text:String, data:String, updateDataOnly:Boolean = false):void {
			cachePageData(getPageKey(page), page.title, page.ns, page.latest, page.dataVersion, text, data, updateDataOnly, page);
		}
		
		public function uncachePage(page:Page):void {
			var key:String = getPageKey(page);
			var i:int = getSharedObjectIndex(key);
			sharedObjects[i].data[key] = null;
			sharedObjectsDirty[i] = true;
			
		}
		
		public function flush():void {
			for (var i:int = 0; i < SHARED_OBJECT_COUNT; i++) {
				if (sharedObjectsDirty[i]) {
					try {
						if (sharedObjects[i].flush() != SharedObjectFlushStatus.FLUSHED) {
//							logger.warn("savePage pending");
							sharedObjects[i].addEventListener(NetStatusEvent.NET_STATUS, handlePending);
							pendingIndex = i;
							break;
						}
						sharedObjectsDirty[i] = false;
					}
					catch (e:Error) {
						Security.showSettings(SecurityPanel.LOCAL_STORAGE);
					}
				}
			}
		}
		
		public function copy(newUserName:String, newTreeName:String):void {
			for (var i:int = 0; i < SHARED_OBJECT_COUNT; i++) {
				var so:SharedObject = SharedObject.getLocal(
					CacheManager.getCacheKey(getTreeCacheKey(newUserName, newTreeName, i)), "/");
				for (var key:String in sharedObjects[i].data) {
					so.data[key] = sharedObjects[i].data[key];
				}
				so.flush();
			}
		}
		
//		public function migrate(pages:Object):void {
//			migrationQueue = new Array();
//			for (var key:String in pages) {
//				migrationQueue.push(pages[key]);
//			}
//			Utils.activateTimer(migrationTimer);
//		}
		
//		public function migratePages(event:Event):void {
//			var i:int = 0;
//			while (migrationQueue.length > 0 && i++ < MAX_MIGRATION_REQUESTS) {
//				var page:Page = migrationQueue.pop();
//				var so:SharedObject = SharedObject.getLocal(CacheManager.getCacheKey(getOldPageKey(page)), "/");
//				if (so.data.ns == page.ns && so.data.title == page.title) { // page found in old cache
//					var cacheKey:String = getPageKey(page);
//					var o:Object = readPageData(cacheKey);
//					if (o == null || o.ns != page.ns || o.title != page.title) { // but not in new cache
//						cachePageData(cacheKey, so.data.title, so.data.ns, so.data.revid, so.data.dataVersion, so.data.text, so.data.data, false, page);
//					}
//					so.clear();
//				}
//			}
//			if (migrationQueue.length > 0) {
//			Utils.activateTimer(migrationTimer);
//			}
//			else {
//				flush();
//			}
//		}
		
//		private function getOldPageKey(page:Page):String {
//			return page.ns + "-" + page.title;
//		}

		private function getPageKey(page:Page):String {
			return page.ns + ":" + page.title;
		}
		
		private function getSharedObjectIndex(key:String):int {
			var sum:int
			for (var i:int = 0; i < key.length; i++) {
				sum += key.charCodeAt(i);
			}
			return sum % SHARED_OBJECT_COUNT;
		}
		
		private function readPageData(key:String):Object {
			var i:int = getSharedObjectIndex(key);
			return sharedObjects[i].data[key];
		}
		
		private function cachePageData(key:String, title:String, ns:int, latest:int, dataVersion:int, 
												text:String, data:String, updateDataOnly:Boolean, page:Page):void {
			var o:Object = new Object();
			o.title = title;
			o.ns = ns;
			if (!updateDataOnly) {
				o.revid = latest;
				o.text = text;
				page.cacheVersion = latest;
			}
			// HACK assume that the page version we initially downloaded is the same
			// as the version we just got.  Assumption fails only if the user is logged in
			// simultaneously in multiple family tree explorers on the same tree and edits
			// the same LDS/Image data in each one.
			// if we have data to save, or we need to clear out the data field
			if (data.length > 0 || dataVersion == 0 || updateDataOnly) {
				o.dataVersion = dataVersion;
				o.data = data;
				page.cacheDataVersion = dataVersion;
			}
			
			var i:int = getSharedObjectIndex(key);
			sharedObjects[i].data[key] = o;
			sharedObjectsDirty[i] = true;
		}
		
		private function handlePending(event:NetStatusEvent):void {
//			logger.warn("handlePending " + event.info.code);
			sharedObjects[pendingIndex].removeEventListener(NetStatusEvent.NET_STATUS, handlePending);
			if (event.info.code == "SharedObject.Flush.Success") {
//				logger.warn("handlePending success");
				flush();
			}
			else {
				Alert.show("Local storage is used to cache\npages for faster access.\n" +
							  "Please allow storage in the future.");
			}
		}
	}
}