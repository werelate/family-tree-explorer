package org.werelate.fte.command
{
	import flash.events.Event;
	import flash.display.DisplayObject;
	import mx.rpc.events.ResultEvent;
	import mx.containers.TitleWindow;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.managers.PopUpManager;
	import mx.core.Application;
	import mx.collections.ArrayCollection;
	import mx.controls.List;

	import org.werelate.fte.service.WRServices;
	import org.werelate.fte.view.OpenFamilyTreeView;
	import org.werelate.fte.view.OpenEvent;
	import org.werelate.fte.model.Model;
	import org.werelate.fte.model.Page;
	import org.werelate.fte.util.Utils;
	import mx.controls.Alert;
	import flash.utils.Timer;
	import flash.events.TimerEvent;

	public class OpenFamilyTree implements Command
	{
		private static const logger:ILogger = Log.getLogger("OpenFamilyTree");
		private static const REFRESH_TIMER_DELAY:int = 50;
		
		private var popup:OpenFamilyTreeView;
		private var userName:String;
		private var fileName:String;
		private var defaultPageTitle:String;
		private var primaryPageTitle:String;
		private var refreshTimer:Timer;
		
		public function execute():void {
			Controller.instance.setDefaultUserName();
			// pop up dialog to get tree name
			popup = new OpenFamilyTreeView();
			if (Model.instance.defaultUserName != null) {
				popup.userName = Model.instance.defaultUserName;
			}
			popup.addEventListener("close", handleClose);
			popup.addEventListener("open", handleOpen);
			PopUpManager.addPopUp(popup, DisplayObject(Application.application), true);
			PopUpManager.centerPopUp(popup);
		}
		
		private function handleClose(event:Event):void {
//			logger.debug("close " + event.toString());
			PopUpManager.removePopUp(popup);
		}
		
		private function handleOpen(event:OpenEvent):void {
			handleClose(event);
			doOpen(event.userName, event.fileName, null);
		}
		
		public function doOpen(userName:String, fileName:String, pageTitle:String):void {
			this.userName = userName;
			this.fileName = fileName;
			this.defaultPageTitle = pageTitle;
			this.primaryPageTitle = null;
//			logger.debug("open " + userName + "/" + fileName);
			refreshTimer = new Timer(REFRESH_TIMER_DELAY,1); // wait before refresh views
			refreshTimer.addEventListener(TimerEvent.TIMER_COMPLETE, refreshViews);
			WRServices.instance.openFamilyTree(userName, fileName, handleResult);
		}
		
		private function handleGedcomWarning(status:int):void {
			var msg:String;
			switch (status) {
				case WRServices.STATUS_GEDCOM_WAITING:
					msg = "Your GEDCOM is still waiting\nin the queue to be processed.";
					break;
				case WRServices.STATUS_GEDCOM_ERROR:
				case WRServices.STATUS_GEDCOM_REGENERATE:
					msg = "We had a problem processing your GEDCOM.  You don't need to do anything.  " + 
							"We will review your GEDCOM and should have your pages ready as soon as possible.  " +
							"Please email dallan@werelate.org for more information.";
					break;
				case WRServices.STATUS_GEDCOM_OVERLAP:
					msg = "Your GEDCOM appears to overlap with a GEDCOM you have uploaded previously.  " + 
							"Please click on the 'My Relate' button near the top of the page on the right, " + 
							"then click on 'Check messages' for more information.";
					break;
				case WRServices.STATUS_GEDCOM_NOT_GEDCOM:
					msg = "The file you uploaded does not appear to be a GEDCOM file.  " + 
							"Please click on the 'My Relate' button near the top of the page on the right, " + 
							"then click on 'Check messages' for more information.";
					break;
				default:
					msg = "There was a problem processing your GEDCOM.  " + 
							"Please email dallan@werelate.org for more information.";
			}
			Alert.show(msg, "Notice");
		}
		
		private function handleResult(event:ResultEvent):void {
//			logger.debug("OpenFamilyTree status= " + event.result.@status);
			var status:int = event.result.@status;
			if (status != WRServices.STATUS_OK && 
				 status != WRServices.STATUS_GEDCOM_WAITING &&
				 status > WRServices.STATUS_GEDCOM_ERROR_START) {
				// errors include STATUS_GEDCOM_PROCESSING
				WRServices.instance.handleError(status, this.fileName);
			}
			else {
				if (status != WRServices.STATUS_OK) {
					// warnings are STATUS_GEDCOM_WAITING, and various GEDCOM problems
					handleGedcomWarning(status);
				}
				Controller.instance.doFileClose();
				Model.instance.userName = userName;
				Model.instance.treeName = fileName;
				this.primaryPageTitle = event.result.@primary;
				Controller.instance.cacheManager.openTreeCache(Model.instance.userName, fileName);
				// add pages to tree
				Model.instance.suspendViewUpdate = true;
				var isEmpty:Boolean = true;
				for each (var p:XML in event.result.p) {
					var page:Page = Model.instance.pages.getPage(p.@n, p.@t);
					page.init(p.@o, p.@l, p.@dv, p.@u, p.@d, p.@c, p.@f, true);
					// add talk page too
					var latest:int = p.@tl;
					if (latest > 0) {
						page = Model.instance.pages.getPage(Utils.getTalkNs(page.ns), p.@t);
						page.init(p.@to, p.@tl, 0, p.@tu, p.@td, p.@tc, 0, true);
					}
					isEmpty = false;
				}
				Model.instance.suspendViewUpdate = false;
//logger.warn("OpenFamilyTree userName=" + userName + " defaultUserName=" + Model.instance.defaultUserName + " isEmpty=" + (isEmpty ? "true" : "false"));
				if (isEmpty && userName == Model.instance.defaultUserName) {
					var cft:CreateFamilyTree = new CreateFamilyTree();
//logger.warn("OpenFamilyTree handleEmptyTree");
					cft.handleEmptyTree();
				}
				// return control and refresh the views a little later
				Utils.activateTimer(refreshTimer);
//				logger.debug("OpenFamilyTree end");
			}
		}
			
		private function refreshViews(event:Event):void {
			Model.instance.loadSettings(defaultPageTitle, primaryPageTitle);
			if (Model.instance.selectedPage != null) {
				Controller.instance.loadPage(Model.instance.selectedPage);
			}
			else {
				Controller.instance.loadContent(Model.WR_HOMEPAGE);
				Model.instance.selectContentPage();
			}
			Model.instance.mainMenu.resetEnabled();
//			Model.instance.pages.computeHourglassPages(true);
			Model.instance.pages.computeIndexPages(true);
//			Model.instance.pages.computeChangedPages();
			Model.instance.pages.computeBookmarks();
			Model.instance.mainMenu.updateBookmarks(Model.instance.pages.bookmarks);
			if (Model.instance.primaryPage == null && Model.instance.pages.indexPages.length > 0) {
				Model.instance.selectedTab = Model.INDEX_TAB;
//				Alert.show("Please select a Person or Family to be the \"root\"\n"+
//							  "of the tree. Do this by right-clicking on the one you\n"+
//							  "want from this index view and selecting 'Make Primary'.\n"+
//							  "You can then switch to the 'Pedigree and Descendants'\n"+
//							  "view by clicking on the first tab (the one with the\n" + 
//							  "black tree) in the row of tabs above.",
//							  "Select the Primary Person or Family");
			}
//			else if (Model.instance.pages.changedPages.length > 0) {
//				Model.instance.selectedTab = Model.CHANGED_PAGES_TAB;
//			}
			if (userName == Model.instance.defaultUserName) {
				Controller.instance.saveDefaultTreeName(userName, fileName);
			}
			// no longer needed
//			Controller.instance.cacheManager.migrateTreeCache(Model.instance.pages.allPages);
		}
	}
}