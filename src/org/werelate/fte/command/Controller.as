package org.werelate.fte.command
{
	import flash.external.ExternalInterface;
	
	import mx.controls.Alert;
	import mx.events.MenuEvent;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.rpc.events.ResultEvent;
	import mx.preloaders.DownloadProgressBar;
	import flash.net.SharedObject;
	import flash.events.ContextMenuEvent;
	import mx.controls.listClasses.ListBase;
	import mx.controls.dataGridClasses.DataGridItemRenderer;
	import mx.controls.listClasses.ListData;
	import mx.controls.Tree;
	import mx.controls.listClasses.BaseListData;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import org.werelate.fte.model.*;
	import org.werelate.fte.util.Utils;
	import org.werelate.fte.service.WRServices;
	import org.werelate.fte.view.FamilyTree;
//	import org.werelate.fte.view.Changes;
	import flash.events.Event;
	import mx.events.CloseEvent;
	import org.werelate.fte.view.HourglassButton;
	import org.werelate.fte.service.Service;
	import flash.net.FileReference;
	import mx.core.Application;
	import flash.utils.unescapeMultiByte;
	import org.werelate.fte.util.StringUtils;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	
	public class Controller
	{
		private static const logger:ILogger = Log.getLogger("Controller");

		/** Reference to singleton instance of this class. */
		private static var _instance:Controller;
		
		public var cacheManager:CacheManager;
		private var isSavingEdit:Boolean;
		private var isUploadingFile:Boolean;
		private var contextMenuPage:Page;
		private var pagesToAccept:Array;
//		private var fileReference:FileReference;
		private var pageToRemove:Page;
		private var exitTimer:Timer;
		
		public function Controller()
		{
		    _instance = this;
		    cacheManager = new CacheManager();
		    isSavingEdit = false;
		    isUploadingFile = false;
		    contextMenuPage = null;
		    pagesToAccept = new Array();
		    pageToRemove = null;
		}
		
		public static function get instance():Controller
		{
		    return _instance;
		}
		
		public function init():void {
//			logger.debug("init");
			Model.instance.init();
			openFamilyTreeExplorer();
			Model.instance.mainMenu.resetEnabled();
		}
		
//		public function savingEdit():void {
//			logger.debug("savingEdit");
//			isSavingEdit = true;
//		}
		
//		public function uploadingFile():void {
//			logger.debug("uploadingFile");
//			isUploadingFile = true;
//		}
		
		public function contentLoaded(htmlTitle:String, url:String, revid:int, treeNames:String, userName:String):void {
//			logger.debug("contentLoaded " + url);
			Model.instance.status.setMessage("load", "");
			Model.instance.contentURL = url;
			Model.instance.defaultUserName = userName;
			var page:Page = Model.instance.getContentPage();
//			logger.debug("contentLoaded " + (page != null ? "Y" : "N") + revid + (page != null && page.isSelectable() ? "Y" : "N"));
			if (page != null && page.ns == Model.SPECIAL_NS && page.title == "Movepage" && url.indexOf("&action=success") > 0) {
				var oldStart:int = url.indexOf("&oldtitle=");
				var newStart:int = url.indexOf("&newtitle=");
				if (oldStart > 0 && newStart > 0) {
					oldStart += "&oldtitle=".length;
					newStart += "&newtitle=".length;
					var oldEnd:int = url.indexOf("&", oldStart);
					var newEnd:int = url.indexOf("&", newStart);
					var oldNsTitle:String = 
						Utils.decodeUrl(oldEnd < 0 ? url.substring(oldStart) : url.substring(oldStart, oldEnd));
					var newNsTitle:String = 
						Utils.decodeUrl(newEnd < 0 ? url.substring(newStart) : url.substring(newStart, newEnd));
//					logger.debug("contentLoaded moving page");
					movePage(Utils.getNsFromTitleNs(oldNsTitle), Utils.getTitleFromTitleNs(oldNsTitle),
								Utils.getNsFromTitleNs(newNsTitle), Utils.getTitleFromTitleNs(newNsTitle));
				}
			}
			else if (page != null && htmlTitle.indexOf("Action complete") == 0 && url.indexOf("&action=delete") > 0) {
				removePageFromFTE(page, true);
			}
			else if (page != null && revid > 0 && page.isSelectable()) {
				var updated:Boolean = page.updateLatest(revid);
//				logger.warn("trees=" + treeNames);
				var trees:Array = StringUtils.unescapeXml(treeNames).split("|");
				if (page.isTalkPage && !page.isInTree && 
					 Model.instance.pages.getPage(Utils.getMainNs(page.ns), page.title).isInTree) {
					// add the talk page, since we already have the main page
//					logger.debug("contentLoaded get talk page");
					page.isInTree = true;
					page.hasBeenChanged = true;
					cacheManager.cachePage(page, true);
				}
				else if (!page.isTalkPage && userName == Model.instance.userName && page.isInTree && trees.indexOf(Model.instance.treeName) < 0) {
					// remove page from tree
//					logger.warn("removing page");
					removePageFromFTE(page, false);
				}
				else if (!page.isTalkPage && userName == Model.instance.userName && !page.isInTree && trees.indexOf(Model.instance.treeName) >= 0) {
					// add page to tree
//					logger.warn("adding page");
					addPageToFTE(page);
				}
				else if (page.isInTree && updated) {
//					logger.debug("contentLoaded caching page updated " + revid);
					page.hasBeenChanged = true;
					cacheManager.cachePage(page, true);
				}
			}
			isSavingEdit = false;
			isUploadingFile = false;
			Model.instance.selectContentPage();
			Model.instance.mainMenu.resetEnabled();
		}
		
		public function openFamilyTreeExplorer():void {
//			logger.debug("openFamilyTreeExplorer");
			WRServices.instance.openFamilyTreeExplorer(handleOpenFTEResult);
		}
		private function handleOpenFTEResult(event:ResultEvent):void {
//			logger.debug("OpenFamilyTreeExplorer result " + event.result.user + " " + event.result.notice);
			var status:int = event.result.@status;
			if (status != WRServices.STATUS_OK) {
				WRServices.instance.handleError(status);
			}
			else {
				var notice:String = event.result.notice;
				var userName:String = null;
				var fileName:String = null;
				var pageTitle:String = null;
				if (notice.length > 0) {
					Alert.show(notice, 'Notice');
				}
				setDefaultUserNameResult(event);
//				logger.debug("Open FTE defaults " + Application.application.parameters.userName + "/" +
//				            Application.application.parameters.treeName + "/" + 
//				            Application.application.parameters.page);
				if (Application.application.parameters.userName != null && Application.application.parameters.userName.length > 0) {
					userName = Application.application.parameters.userName;
					fileName = Application.application.parameters.treeName;
					pageTitle = Application.application.parameters.page;
				}
				else if (Model.instance.defaultUserName != null) {
					userName = Model.instance.defaultUserName;
					fileName = getDefaultTreeName(Model.instance.defaultUserName);
				}
				if (!StringUtils.isEmpty(fileName)) {
					var oft:OpenFamilyTree = new OpenFamilyTree();
					Model.instance.alertErrors = false;
					oft.doOpen(userName, fileName, pageTitle);
					Model.instance.alertErrors = true;
				}
				else {
					var command:Command = new Welcome();
					command.execute();
				}
			}
		}
		
		public function setDefaultUserName():void {
			// see if the user has logged in yet				
			WRServices.instance.openFamilyTreeExplorer(setDefaultUserNameResult);
		}
		private function setDefaultUserNameResult(event:ResultEvent):void {
//			logger.debug("setDefaultUserNameResult result " + event.result.user);
			var status:int = event.result.@status;
			if (status == WRServices.STATUS_OK) {
				var user:String = event.result.user;
				if (user.length > 0) {
					Model.instance.defaultUserName = user;
				}
			}
		}
		
		public function loadContentNewWindow(url:String):void {
//			logger.debug("loadContentNewWindow " + url);
			ExternalInterface.call("loadContentNewWindow", url);
		}
		
		public function loadContent(url:String):void {
			if (url != Model.instance.contentURL) {
//				logger.debug("loadContent " + url);
				Model.instance.status.setMessage("load", "Loading page...");
				ExternalInterface.call("loadContent", url);
			}
		}
		
		public function loadPage(page:Page, params:Object = null):void {
//			logger.debug("loadPage " + page.title);
			var titleUrl:String;
			if (page.ns == Model.MAIN_NS) {
				titleUrl = Utils.encodeUrl(page.title);
			}
			else {
				titleUrl = Utils.encodeUrl(Utils.getNsString(page.ns) + ":" + page.title);
			}
			var url:String;
			if (params == null) {
				url = Model.WR_WIKI_PATH + titleUrl;
			}
			else {
				url = Model.WR_INDEX_URL + "?title=" + titleUrl + "&" + Utils.encodeUrlParams(params);
			}
			loadContent(url);
		}
		
		public function loadSelectedPage():void {
//			logger.debug("loadSelectedPage");
			if (Model.instance.selectedPage != null) {
				loadPage(Model.instance.selectedPage);
			}
		}
		
		private function getPageFromContextEvent(event:ContextMenuEvent):Page {
//			logger.warn("getPageFromContextEvent " + (event.mouseTarget.parent != null ? event.mouseTarget.parent.name : ""));
			var page:Page = null;
			if (event.mouseTarget is DataGridItemRenderer) {
				var dgir:DataGridItemRenderer = DataGridItemRenderer(event.mouseTarget);
				page = Page(dgir.data);
			}
			else if (event.mouseTarget.parent != null && 
						(event.mouseTarget.parent.name == "pedigreeView" || event.mouseTarget.parent.name == "descendencyView")) {
				var ft:FamilyTree = FamilyTree(event.mouseTarget.parent);
				page = ft.highlightedPage;
			}
//			else if (event.mouseTarget.parent != null && 
//						event.mouseTarget.parent.name == "changesView") {
//				var cv:Changes = Changes(event.mouseTarget.parent);
//				page = cv.highlightedPage;
//			}
			else if (event.mouseTarget.parent != null && event.mouseTarget.parent.name == "summaryCanvas") {
				page = Model.instance.selectedPage;
			}
			else if (event.mouseTarget is HourglassButton) {
				page = HourglassButton(event.mouseTarget).page;
			}
			return page;
		}
		
		public function contextMenuHandler(event:ContextMenuEvent):void {
			contextMenuPage = getPageFromContextEvent(event);
			var cm:ContextMenu = ContextMenu(event.target);
			cm.hideBuiltInItems();
			cm.customItems = new Array();
			if (contextMenuPage != null) {
//				logger.debug("contextMenuHandler " + contextMenuPage.title);
				var cmi:ContextMenuItem;
				
   	     	cmi = new ContextMenuItem("Make this page primary", false, 
	   	     	Model.instance.mainMenu.getMakePrimaryEnabled(contextMenuPage), true);
      	  	cmi.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, contextMenuItemHandler);
        		cm.customItems.push(cmi);

//   	     	cmi = new ContextMenuItem("View Changes", false, 
//	   	     	Model.instance.mainMenu.getViewChangesEnabled(contextMenuPage), true);
//      	  	cmi.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, contextMenuItemHandler);
//        		cm.customItems.push(cmi);

//   	     	cmi = new ContextMenuItem("Acknowledge Changes", false, 
//	   	     	Model.instance.mainMenu.getAcceptChangesEnabled(contextMenuPage), true);
//      	  	cmi.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, contextMenuItemHandler);
//        		cm.customItems.push(cmi);

   	     	cmi = new ContextMenuItem("Add this page to tree", false, 
	   	     	Model.instance.mainMenu.getAddPageEnabled(contextMenuPage), true);
      	  	cmi.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, contextMenuItemHandler);
        		cm.customItems.push(cmi);

   	     	cmi = new ContextMenuItem("Remove this page from tree", false, 
	   	     	Model.instance.mainMenu.getRemovePageEnabled(contextMenuPage), true);
      	  	cmi.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, contextMenuItemHandler);
        		cm.customItems.push(cmi);

//   	     	cmi = new ContextMenuItem("Edit LDS ordinances", false,
//	   	     	Model.instance.mainMenu.getEditOrdinancesEnabled(contextMenuPage), true);
//      	  	cmi.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, contextMenuItemHandler);
//        		cm.customItems.push(cmi);

   	     	cmi = new ContextMenuItem("Bookmark this page", false, 
	   	     	Model.instance.mainMenu.getAddBookmarkEnabled(contextMenuPage), true);
      	  	cmi.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, contextMenuItemHandler);
        		cm.customItems.push(cmi);
        		
   	     	cmi = new ContextMenuItem("Remove bookmark", false, 
	   	     	Model.instance.mainMenu.getRemoveBookmarkEnabled(contextMenuPage), true);
      	  	cmi.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, contextMenuItemHandler);
        		cm.customItems.push(cmi);
   		}
		}
		
		public function contextMenuItemHandler(event:ContextMenuEvent):void {
			if (contextMenuPage != null) {
//				logger.debug("contextMenuItemHandler " + contextMenuPage.title);

				var caption:String = event.target.caption;
				switch (caption) {
					case "Make this page primary":
						makePrimary(contextMenuPage);
						break;
//					case "Acknowledge Changes":
//						acceptChanges(contextMenuPage);
//						break;
//					case "View Changes":
//						viewChanges(contextMenuPage);
//						break;
					case "Add this page to tree":
						addPage(contextMenuPage);
						break;
					case "Remove this page from tree":
						removePage(contextMenuPage);
						break;
//					case "Edit LDS ordinances":
//						editOrdinances(contextMenuPage);
//						break;
					case "Bookmark this page":
						addBookmark(contextMenuPage);
						break;
					case "Remove bookmark":
						removeBookmark(contextMenuPage);
						break;
					default:
						break;
				}
			}
		}

		public function mainMenuHandler(event:MenuEvent):void {
//      	logger.debug("MainMenu " + event.item.@data);
      	var menuItem:String = event.item.@data;
      	switch (menuItem) {
      		case "new":
      			fileNew();
      			break;
      		case "open":
      			fileOpen();
      			break;
//      		case "import":
//      			fileImport();
//      			break;
      		case "close":
      			fileClose();
      			break;
      		case "copy":
      			fileCopy();
      			break;
      		case "rename":
      			fileRename();
      			break;
//      		case "delete":
//      			fileDelete();
//      			break;
      		case "exit":
      			fileExit();
      			break;
      		case "makeprimary":
      			makePrimary();
      			break;
//      		case "viewchanges":
//      			viewChanges();
//      			break;
//      		case "acceptchanges":
//      			acceptChanges();
//      			break;
//      		case "editordinances":
//      			editOrdinances();
//      			break;
      		case "addpage":
      			addPage();
      			break;
      		case "removepage":
      			removePage();
      			break;
//      		case "addperson":
//      			addPerson();
//      			break;
//      		case "addimage":
//      			addImage();
//      			break;
//      		case "addarticle":
//      			addArticle();
//      			break;
//      		case "adduserpage":
//      			addUserPage();
//      			break;
      		case "find":
      			find();
      			break;
//      		case "gotopage":
//      			gotoPage();
//      			break;
      		case "addbookmark":
      			addBookmark();
      			break;
      		case "removebookmark":
      			removeBookmark();
      			break;
      		case "bookmark":
      			gotoBookmark(event.item.@ns, event.item.@title);
      			break;
//      		case "searchweb":
//      			searchWeb();
//      			break;
//      		case "searchwerelate":
//      			searchWeRelate();
//      			break;
//      		case "places":
//      			places();
//      			break;
//      		case "names":
//      			names();
//      			break;
//      		case "sources":
//      			sources();
//      			break;
//      		case "articles":
//      			articles();
//      			break;
//      		case "myrelate":
//      			myRelate();
//      			break;
//      		case "tutorial":
//      			helpTutorial();
//      			break;
      		case "helpFTE":
      			helpFTE();
      			break;
      		case "helpTutorials":
      			helpTutorials();
      			break;
      		case "helpContents":
      			helpContents();
      			break;
      		case "helpSearch":
      			helpSearch();
      			break;
//      		case "helpPeople":
//      			helpPeople();
//      			break;
//      		case "helpFamilies":
//      			helpFamilies();
//      			break;
//      		case "helpSources":
//      			helpSources();
//      			break;
//      		case "helpImages":
//      			helpImages();
//      			break;
//      		case "contents":
//      			helpContents();
//      			break;
//      		case "about":
//      			about();
//      			break;
//      		case "feedback":
//      			feedback();
//      			break;
      		default:
//		      	logger.error("menu item not found " + event.item.@data);
      	}
		}

		public function fileNew():void {
			var command:Command = new CreateFamilyTree();
			command.execute();
		}	
		
		public function fileOpen():void {
			var command:Command = new OpenFamilyTree();
			command.execute();
		}
		
		public function fileImport():void {
//			fileReference = new FileReference();
//			var command:Command = new ImportGedcom(fileReference);
//			command.execute();
			loadPage(Model.instance.pages.getPage(Model.SPECIAL_NS, "ImportGedcom"), 
						{wrTreeName:Model.instance.treeName});
		}
		
		public function fileClose():void {
			Controller.instance.loadContent(Model.WR_HOMEPAGE);
			doFileClose();
		}
		
		public function doFileClose():void {
			var userName:String = Model.instance.userName;
			Model.instance.clearTree();
			Model.instance.selectContentPage();
			Model.instance.mainMenu.updateBookmarks(Model.instance.pages.bookmarks);
			Model.instance.mainMenu.resetEnabled();
			cacheManager.closeTreeCache();
			Controller.instance.saveDefaultTreeName(userName, null);
		}
		
		public function fileCopy():void {
			var command:Command = new CopyFamilyTree();
			command.execute();
		}
		
		public function fileRename():void {
			var command:Command = new RenameFamilyTree();
			command.execute();
		}
		
//		public function fileDelete():void {
//			var command:Command = new DeleteFamilyTree();
//			command.execute();
//		}
		
		public function fileExit():void {
//			Model.instance.clearTree();
			cacheManager.closeTreeCache();
			exitTimer = new Timer(350,1); // wait before exiting
			exitTimer.addEventListener(TimerEvent.TIMER_COMPLETE, doExit);
			Utils.activateTimer(exitTimer);
		}
		
		private function doExit(event:Event):void {
			ExternalInterface.call("loadParentContent", 
				(Model.instance.contentURL ? Model.instance.contentURL : Model.WR_WIKI_PATH + "Main_Page"));
		}
		
//		public function acceptChanges(page:Page = null):void {
//			// if changes view open, check for multiple selection
//			if (page == null && Model.instance.selectedTab == Model.CHANGED_PAGES_TAB) {
//				pagesToAccept = new Array();
//				for each (page in Model.instance.selectedChangedPages) {
//					logger.debug("acceptChanges queue" + page.title);
//					pagesToAccept.push(page);
//				}
//				page = pagesToAccept.pop();
//			}
//			if (page == null) page = Model.instance.selectedPage;
//			logger.debug("acceptChanges " + page.title);
//			WRServices.instance.acceptPage(page.ns, page.title, acceptPageResultHandler);
//		}
//		private function acceptPageResultHandler(event:ResultEvent):void {
//			logger.debug("AcceptPage result " + event.result.toString());
//			var status:int = event.result.@status;
//			if (status != WRServices.STATUS_OK) {
//				WRServices.instance.handleError(status);
//			}
//			else {
//				var ns:int = int(event.result.@ns);
//				var title:String = event.result.@title;
//				// update page
//				var page:Page = Model.instance.pages.getPage(ns, title);
//				page.oldid = int(event.result.@revid);
//				page.latest = page.oldid;
//				// update cache
//				cacheManager.cachePage(page);
//				Model.instance.mainMenu.resetEnabled();
//			}
//			if (pagesToAccept.length > 0) {
//				acceptChanges(pagesToAccept.pop());
//			}
//		}
		
//		public function editOrdinances(page:Page = null):void {
//			if (page == null) page = Model.instance.selectedPage;
//			var command:Command = new EditOrdinances(page);
//			command.execute();
//		}
//
		public function makePrimary(page:Page = null):void {
			if (page == null) page = Model.instance.selectedPage;
			Model.instance.primaryPage = page;
			// load page if not already selected
			if (page != Model.instance.selectedPage) {
				loadPage(page);
			}
			Model.instance.mainMenu.resetEnabled();
		}
		
		public function find(): void {
			var command:Command = new Find();
			command.execute();
		}
		
//		public function gotoPage():void {
//			var command:Command = new GotoPage();
//			command.execute();
//		}

		public function addPage(page:Page = null):void {
			if (page == null) page = Model.instance.selectedPage;
			WRServices.instance.addPage(Utils.getMainNs(page.ns), page.title, addPageResultHandler);
		}
		private function addPageResultHandler(event:ResultEvent):void {
//			logger.debug("AddPage result " + event.result.toString());
			var status:int = event.result.@status;
			if (status == WRServices.STATUS_NOT_FOUND) {
				Alert.show("Page has not been created.  To create the page, click on the Edit button at the top of the page", "Notice");
			}
			else if (status != WRServices.STATUS_OK) {
				WRServices.instance.handleError(status);
			}
			else {
				var ns:int = int(event.result.@ns);
				var title:String = event.result.@title;
				// add main page
				var page:Page = Model.instance.pages.getPage(ns, title);
//				page.oldid = int(event.result.@revid);
//				page.latest = page.oldid;
//				addPageToFTE(page);
//				if (page == Model.instance.selectedPage) {
					// force a reload of the page
					loadPage(page, {action:"purge"});
//				}
			}
		}

		private function addPageToFTE(page:Page):void {
			page.isInTree = true;
			page.oldid = page.latest; // assume latest version is accepted
			if (Model.instance.primaryPage == null && Model.instance.mainMenu.getMakePrimaryEnabled(page)) {
				Model.instance.primaryPage = page;
			}
//			if (Model.instance.selectedPage != null &&
//					Model.instance.selectedPage.ns == page.ns && Model.instance.selectedPage.title == page.title) {
//				Model.instance.selectedPage = page; // page is now in tree, so update selectedPage object
//			}
			cacheManager.cachePage(page);
//			if (page == Model.instance.selectedPage) {
//				loadPage(page); // force page load so user can see that they're now watching the page
//			}
			// add talk page
//			var latest:int = int(event.result.@talk_revid);
//			if (latest > 0) {
//				page = Model.instance.pages.getPage(Utils.getTalkNs(ns), title);
//				page.oldid = latest;
//				page.latest = latest;
//				page.isInTree = true;
//				cacheManager.cachePage(page);
//			}
			// be sure to re-compute the hourglass pages
//logger.warn("addPageToFTE compute");
			Model.instance.pages.computeHourglassPages(true);
			Model.instance.mainMenu.resetEnabled();
		}

		
		public function removePage(page:Page = null):void {
			if (page == null) page = Model.instance.selectedPage;
			pageToRemove = page;
			Alert.show("Do you also want to delete the page from WeRelate.org?", 
								"Delete from WeRelate.org?", 
								Alert.YES | Alert.NO, null, handleRemoveConfirm, null, Alert.NO);
		}
		public function handleRemoveConfirm(event:CloseEvent):void {
			WRServices.instance.removePage(Utils.getMainNs(pageToRemove.ns), pageToRemove.title, 
												(event.detail == Alert.YES), removePageResultHandler);
			pageToRemove = null;
		}
		private function removePageResultHandler(event:ResultEvent):void {
//			logger.debug("RemovePage result " + event.result.toString());
			var status:int = event.result.@status;
			if (status != WRServices.STATUS_OK) {
				WRServices.instance.handleError(status);
			}
			else {
				var ns:int = int(event.result.@ns);
				var title:String = event.result.@title;
				var page:Page = Model.instance.pages.getPage(ns, title);
				if (page === Model.instance.selectedPage) {
					// force a reload of the page
					loadPage(page, {action:"purge"});
				}
				else {
					var deleted:Boolean = (String(event.result.@delete_status).length > 0 && event.result.@delete_status == WRServices.STATUS_OK);
					removePageFromFTE(page, deleted);
					if (event.result.@delete_status == WRServices.STATUS_NOT_AUTHORIZED) {
						Alert.show("Page removed from tree but could not be deleted from WeRelate.org", "Not Deleted"); 
					}
				}
			}
		}
		
		private function removePageFromFTE(page:Page, deleted:Boolean):void {
			// remove main page
			var p:Page = Model.instance.pages.getPage(Utils.getMainNs(page.ns), page.title);
			p.isInTree = false;
			if (p.isCached) {
				cacheManager.uncachePage(p);
			}
			// re-cache changed pages
			if (deleted) {
				for each (var related:Page in p.getRelatedPages()) {
					if (related.isInTree && related.isCached) {
						cacheManager.cachePage(related, true);
					}
				}
			}
			// remove talk page
			p = Model.instance.pages.getPage(Utils.getTalkNs(page.ns), page.title);
			p.isInTree = false;
			if (p.isCached) {
				cacheManager.uncachePage(p);
			}
			// might have been bookmarked, so update bookmarks
			Model.instance.mainMenu.updateBookmarks(Model.instance.pages.bookmarks);
			// if we're removing the primary page, we'd better choose a different page
//			logger.warn("removing page " + page.title);
//			logger.warn("selected page " + Model.instance.selectedPage.title);
			if (page == Model.instance.primaryPage) {
				p = page.getRelatedPageInTree();
//				logger.warn("making primary page " + (p == null ? "null" : p.title));
				Model.instance.primaryPage = p;
			}
			// be sure to re-compute the hourglass pages
//logger.warn("removePageFromFTE compute");
			Model.instance.pages.computeHourglassPages(true);
			Model.instance.mainMenu.resetEnabled();
		}
		
//		public function addPerson():void {
//			var command:Command = new AddPage(Model.PERSON_NS);
//			command.execute();
//		}
		
//		public function addImage():void {
//			loadContent(Model.WR_WIKI_PATH + "Special:Upload");
//		}
		
//		public function addArticle():void {
//			var command:Command = new AddPage(Model.MAIN_NS);
//			command.execute();
//		}
		
//		public function addUserPage():void {
//			var command:Command = new AddPage(Model.USER_NS);
//			command.execute();
//		}
		
//		public function viewChanges(page:Page = null):void {
//			if (page == null) page = Model.instance.selectedPage;
//			loadPage(page, {oldid:page.oldid, diff:0});
//		}
		
		public function addBookmark(page:Page = null):void {
			if (page == null) page = Model.instance.selectedPage;
			WRServices.instance.bookmarkPage(Utils.getMainNs(page.ns), page.title, addBookmarkResultHandler);
		}
		private function addBookmarkResultHandler(event:ResultEvent):void {
//			logger.debug("AddBookmark result " + event.result.toString());
			var status:int = event.result.@status;
			if (status != WRServices.STATUS_OK) {
				WRServices.instance.handleError(status);
			}
			else {
				var ns:int = int(event.result.@ns);
				var title:String = event.result.@title;
				var page:Page = Model.instance.pages.getPage(ns, title);
				if (page != null) {
					page.isBookmarked = true;
					if (Model.instance.mainMenu.getMakePrimaryEnabled(page)) {
						Model.instance.primaryPage = page;
					}
					if (Model.instance.selectedPage != page) {
						loadPage(page);
					}
					Model.instance.mainMenu.updateBookmarks(Model.instance.pages.bookmarks);
				}
				Model.instance.mainMenu.resetEnabled();
			}
		}
		
		public function removeBookmark(page:Page = null):void {
			if (page == null) page = Model.instance.selectedPage;
			WRServices.instance.unbookmarkPage(page.ns, page.title, removeBookmarkResultHandler);
		}
		private function removeBookmarkResultHandler(event:ResultEvent):void {
//			logger.debug("RemoveBookmark result " + event.result.toString());
			var status:int = event.result.@status;
			if (status != WRServices.STATUS_OK) {
				WRServices.instance.handleError(status);
			}
			else {
				var ns:int = int(event.result.@ns);
				var title:String = event.result.@title;
				var page:Page = Model.instance.pages.getPage(ns, title);
				if (page != null) {
					page.isBookmarked = false;
					Model.instance.mainMenu.updateBookmarks(Model.instance.pages.bookmarks);
				}
				Model.instance.mainMenu.resetEnabled();
			}
		}
		
		public function gotoBookmark(ns:int, title:String):void {
//			logger.info("gotoBookmark " + title);
			var page:Page = Model.instance.pages.getPage(ns, title);
			if (page != null) {
				if (Model.instance.mainMenu.getMakePrimaryEnabled(page)) {
					Model.instance.primaryPage = page;
				}
				if (Model.instance.selectedPage != page) {
					loadPage(page);
				}
			}
		}

//		public function searchWeb():void {
//			loadContent(Model.WR_WIKI_PATH + "WeRelate:Search Web");
//		}
		
//		public function searchWeRelate():void {
//			loadContent(Model.WR_WIKI_PATH + "WeRelate:Search WeRelate");
//		}
		
//		public function places():void {
//			loadContent(Model.WR_WIKI_PATH + "WeRelate:Places");
//		}
		
//		public function names():void {
//			loadContent(Model.WR_WIKI_PATH + "WeRelate:Names");
//		}
		
//		public function sources():void {
//			loadContent(Model.WR_WIKI_PATH + "WeRelate:Sources");
//		}
		
//		public function articles():void {
//			loadContent(Model.WR_WIKI_PATH + "WeRelate:Articles");
//		}

//		public function myRelate():void {
//			loadContent(Model.WR_WIKI_PATH + "Special:MyRelate");
//		}

//		public function helpTutorial():void {
//			loadContentNewWindow(Model.WR_WIKI_PATH + "Help:Family Tree Explorer tutorial");
//		}
		
		public function helpFTE():void {
			loadContent(Model.WR_WIKI_PATH + "Help:Family Tree Explorer");
		}
		
		public function helpTutorials():void {
			loadContent(Model.WR_WIKI_PATH + "Help:Tutorials");
		}
		
		public function helpContents():void {
			loadContent(Model.WR_WIKI_PATH + "Help:Contents");
		}
		
		public function helpSearch():void {
			loadContent(Model.WR_WIKI_PATH + "Special:Search/help");
		}
		
//		public function helpPeople():void {
//			loadContentNewWindow(Model.WR_WIKI_PATH + "Help:Person pages");
//		}
		
//		public function helpFamilies():void {
//			loadContentNewWindow(Model.WR_WIKI_PATH + "Help:Family pages");
//		}
		
//		public function helpSources():void {
//			loadContentNewWindow(Model.WR_WIKI_PATH + "Help:Sources");
//		}
		
//		public function helpImages():void {
//			loadContentNewWindow(Model.WR_WIKI_PATH + "Help:Images");
//		}
		
//		public function about():void {
//			loadContent(Model.WR_HOMEPAGE);
//		}

//		public function feedback():void {
//			loadContent(Model.WR_WIKI_PATH + "WeRelate talk:Family Tree Explorer");
//		}
		
		public function movePage(oldNs:int, oldTitle:String, newNs:int, newTitle:String):void {
			// remove page from cache
			var p:Page = Model.instance.pages.getPage(oldNs, oldTitle);
			if (p.isCached) {
				cacheManager.uncachePage(p);
			}
			// rename page
			var page:Page = Model.instance.pages.renamePage(oldNs, oldTitle, newNs, newTitle);
			// re-cache page
			Controller.instance.cacheManager.cachePage(page, true);
			// re-cache related pages
			for each (var relatedPage:Page in page.getRelatedPages()) {
				if (relatedPage.isInTree && relatedPage.isCached) {
					Controller.instance.cacheManager.cachePage(relatedPage, true);
				}
			}
			// if this is the main page, assume talk page as moved as well
			if (Utils.getMainNs(oldNs) == oldNs) {
				movePage(Utils.getTalkNs(oldNs), oldTitle, Utils.getTalkNs(newNs), newTitle);
			}
		}

		private function getUserSettingsKey(userName:String):String {
			return CacheManager.getCacheKey("settings-" + userName);
		}
		
		private function getDefaultTreeName(userName:String):String {
			var so:SharedObject = SharedObject.getLocal(getUserSettingsKey(userName), "/");
			if (so.data.savedSettings == "true") {
				return so.data.defaultFilename;
			}
			return null;
		}
		
		public function saveDefaultTreeName(userName:String, fileName:String):void {
			var so:SharedObject = SharedObject.getLocal(getUserSettingsKey(userName), "/");
			if (fileName == null) {
				so.clear();
			}
			else {
				so.data.savedSettings = "true";
				so.data.defaultFilename = fileName;
				so.flush();
			}
		}
		
		public function cacheAllPages():void {
			cacheManager.cacheAllPages();
		}
	}
}