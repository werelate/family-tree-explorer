package org.werelate.fte.model
{
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import mx.collections.XMLListCollection;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.collections.ArrayCollection;
	import org.werelate.fte.util.Utils;

	public class MainMenu extends EventDispatcher
	{
		private static const logger:ILogger = Log.getLogger("MainMenu");

		private var mainMenuXML:XML =
		    <mainmenu>
		        <menuitem label="File" data="file">
		            <menuitem label="New Tree..." data="new"/>
		            <menuitem label="Open Tree..." data="open"/>
		            <menuitem label="Close Tree" data="close"/>
		            <menuitem type="separator" data=""/>
<!--
		            <menuitem label="Import GEDCOM..." data="import"/>
-->		            
		            <menuitem label="Rename Tree..." data="rename"/>
		            <menuitem label="Copy Tree..." data="copy"/>
<!--
		            <menuitem label="Delete Tree" data="delete"/>
-->		            
		            <menuitem type="separator" data=""/>
		            <menuitem label="Exit" data="exit"/>
		        </menuitem>
		        <menuitem label="Edit" data="edit">
		        		<menuitem label="Add this page to tree" data="addpage"/>
		            <menuitem label="Make this page primary" data="makeprimary"/>
<!--
		            <menuitem label="View Changes" data="viewchanges"/>
		            <menuitem label="Acknowledge Changes" data="acceptchanges"/>
		            <menuitem label="Edit LDS ordinances" data="editordinances"/>
-->
		            <menuitem type="separator" data=""/>
		            <menuitem label="Find in tree..." data="find"/>
<!--		            
						<menuitem label="Go to Page..." data="gotopage"/>
-->						
		        </menuitem>
		        <menuitem label="Bookmarks" data="bookmarks">
		        		<menuitem label="Bookmark This Page" data="addbookmark"/>
		        		<menuitem label="Remove Bookmark" data="removebookmark"/>
		            <menuitem type="separator" data=""/>
		        </menuitem>
		        <menuitem label="Help" data="help">
		            <menuitem label="Family Tree Explorer" data="helpFTE"/>
		            <menuitem type="separator" data=""/>
		            <menuitem label="Tutorials" data="helpTutorials"/>
		            <menuitem label="Contents" data="helpContents"/>
		            <menuitem label="Search" data="helpSearch"/>
<!--
		            <menuitem label="Tutorial" data="tutorial"/>
		            <menuitem label="Person Pages" data="helpPeople"/>
		            <menuitem label="Family Pages" data="helpFamilies"/>
		            <menuitem label="Sources and MySources" data="helpSources"/>
		            <menuitem label="Images" data="helpImages"/>
		            <menuitem label="WeRelate" data="contents"/>
		            <menuitem type="separator" data=""/>
		            <menuitem label="About Family Tree Explorer" data="about"/>
		            <menuitem label="Feedback" data="feedback"/>
-->
		        </menuitem>
		    </mainmenu>;
		    
		private var _mainMenuCollection:XMLListCollection;
		
		public function MainMenu() {
			_mainMenuCollection = new XMLListCollection(mainMenuXML.children());
			dispatchEvent(new Event("mainMenuCollectionChanged"));
			resetEnabled();
		}
		
		public function resetEnabled():void {
			setEnabled("file", "delete", isTreeOpen() && isMyTree());
			setEnabled("file", "close", isTreeOpen());
//			setEnabled("file", "import", isTreeOpen());
			setEnabled("file", "rename", isTreeOpen() && isMyTree());
			setEnabled("file", "copy", isTreeOpen() && !isMyTree());
			
			setEnabled("edit", "addpage", addPageEnabled);
			setEnabled("edit", "makeprimary", makePrimaryEnabled);
//			setEnabled("edit", "viewchanges", viewChangesEnabled);
//			setEnabled("edit", "acceptchanges", acceptChangesEnabled);
//			setEnabled("edit", "editordinances", editOrdinancesEnabled);
			setEnabled("edit", "find", isTreeOpen());
			
//			setEnabled("add", "addpage", addPageEnabled);
//			setEnabled("add", "addperson", addEnabled);
//			setEnabled("add", "addimage", addEnabled);
//			setEnabled("add", "addarticle", addEnabled);
//			setEnabled("add", "adduserpage", addEnabled);

			setEnabled("bookmarks", "addbookmark", addBookmarkEnabled);
			setEnabled("bookmarks", "removebookmark", removeBookmarkEnabled);

//			dispatchEvent(new Event("acceptChangesEnabledChanged"));
			dispatchEvent(new Event("makePrimaryEnabledChanged"));
//			dispatchEvent(new Event("viewChangesEnabledChanged"));
			dispatchEvent(new Event("addPageEnabledChanged"));
			dispatchEvent(new Event("removePageEnabledChanged"));
			dispatchEvent(new Event("viewsEnabledChanged"));
			dispatchEvent(new Event("addBookmarkEnabledChanged"));
			dispatchEvent(new Event("removeBookmarkEnabledChanged"));
		}
		
		public function updateBookmarks(bookmarks:ArrayCollection):void {
//			logger.info("updateBookmarks");
			var bookmarkMenu:XML = mainMenuXML.menuitem.(@data=="bookmarks")[0];

			// remove previous bookmarks
			var add:XML = bookmarkMenu.menuitem[0];
			var remove:XML = bookmarkMenu.menuitem[1];
			var separator:XML = bookmarkMenu.menuitem[2];
			delete bookmarkMenu.menuitem;
			bookmarkMenu.appendChild(add);
			bookmarkMenu.appendChild(remove);
			bookmarkMenu.appendChild(separator);

			for each (var page:Page in bookmarks) {
				// add page to bookmarks
//				logger.info("adding " + page.title);
				var menuItem:XML = <menuitem/>;
				menuItem.@data = "bookmark";
				menuItem.@label = page.nsTitle;
				menuItem.@title = page.title;
				menuItem.@ns = page.ns;
				bookmarkMenu.appendChild(menuItem);
			}
			dispatchEvent(new Event("mainMenuCollectionChanged"));
		}
		
		[Bindable("mainMenuCollectionChanged")]
		public function get mainMenuCollection():XMLListCollection {
			return _mainMenuCollection;
		}
		
		private function setEnabled(levelOne:String, levelTwo:String, enabled:Boolean):void {
			mainMenuXML.menuitem.(@data==levelOne).menuitem.(@data==levelTwo).@enabled=enabled;
		}
		
		private function isTreeOpen():Boolean {
			return (Model.instance.treeName != null);
		}
		
		private function isMyTree():Boolean {
			return Model.instance.userName == Model.instance.defaultUserName;
		}
		
//		[Bindable("acceptChangesEnabledChanged")]
//		public function get acceptChangesEnabled():Boolean {
//			if (Model.instance.selectedTab == Model.CHANGED_PAGES_TAB) {
//				return (isTreeOpen() && Model.instance.selectedChangedPages.length > 0);
//			}
//			return getAcceptChangesEnabled(Model.instance.selectedPage);
//		}
		
//		public function getAcceptChangesEnabled(page:Page):Boolean {
//			return (isTreeOpen() && page != null && page.isInTree && !page.isCurrent);
//		}

//		public function get editOrdinancesEnabled():Boolean {
//			return getEditOrdinancesEnabled(Model.instance.selectedPage);
//		}
//
//		public function getEditOrdinancesEnabled(page:Page):Boolean {
//			return (isTreeOpen() && isMyTree() && page != null && page.isInTree &&
//						(page.ns == Model.FAMILY_NS || page.ns == Model.PERSON_NS));
//		}

		[Bindable("makePrimaryEnabledChanged")]
		public function get makePrimaryEnabled():Boolean {
			return getMakePrimaryEnabled(Model.instance.selectedPage);
		}
		
		public function getMakePrimaryEnabled(page:Page):Boolean {
			return (isTreeOpen() && page != null && page.isInTree && 
				page != Model.instance.primaryPage && (page.ns == Model.PERSON_NS || page.ns == Model.FAMILY_NS));
		}

		[Bindable("addEnabledChanged")]
		public function get addEnabled():Boolean {
			return isTreeOpen();
		}
		
//		[Bindable("viewChangesEnabledChanged")]
//		public function get viewChangesEnabled():Boolean {
//			return getViewChangesEnabled(Model.instance.selectedPage);
//		}

//		public function getViewChangesEnabled(page:Page):Boolean {
//			return (isTreeOpen() && page != null && page.isInTree && !page.isCurrent);
//		}

		[Bindable("addPageEnabledChanged")]
		public function get addPageEnabled():Boolean {
			return getAddPageEnabled(Model.instance.selectedPage);
		}
		public function getAddPageEnabled(page:Page):Boolean {
			return isTreeOpen() && page != null && !page.isInTree && 
				!page.isTalkPage && page.isSelectable();
		}
		
		[Bindable("removePageEnabledChanged")]
		public function get removePageEnabled():Boolean {
			return getRemovePageEnabled(Model.instance.selectedPage);
		}
		public function getRemovePageEnabled(page:Page):Boolean {
			return isTreeOpen() && page != null && page.isInTree && !page.isTalkPage;
		}
		
		[Bindable("viewsEnabledChanged")]
		public function get viewsEnabled():Boolean {
			return isTreeOpen();
		}

		[Bindable("addBookmarkEnabledChanged")]
		public function get addBookmarkEnabled():Boolean {
			return getAddBookmarkEnabled(Model.instance.selectedPage);
		}
		
		public function getAddBookmarkEnabled(page:Page):Boolean {
			return (isTreeOpen() && page != null && page.isInTree && 
						!Model.instance.pages.getPage(Utils.getMainNs(page.ns), page.title).isBookmarked);
		}

		[Bindable("removeBookmarkEnabledChanged")]
		public function get removeBookmarkEnabled():Boolean {
			return getRemoveBookmarkEnabled(Model.instance.selectedPage);
		}
		
		public function getRemoveBookmarkEnabled(page:Page):Boolean {
			return (isTreeOpen() && page != null && page.isInTree && 
						Model.instance.pages.getPage(Utils.getMainNs(page.ns), page.title).isBookmarked);
		}
	}
}