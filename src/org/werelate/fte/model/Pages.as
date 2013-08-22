package org.werelate.fte.model
{
	import mx.logging.ILogger;
	import mx.logging.Log;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import mx.collections.ArrayCollection;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import org.werelate.fte.util.Utils;
	import org.werelate.fte.command.Controller;
	
	public class Pages extends EventDispatcher
	{
		private static const logger:ILogger = Log.getLogger("Pages");
		
		private var _allPages:Object;
		private var _pedigreeItems:ArrayCollection;
		private var _descendencyItems:ArrayCollection;
		private var _indexPages:ArrayCollection;
//		private var _changedPages:ArrayCollection;
		private var _bookmarks:ArrayCollection;
		private var _hgPages:Array;
		private var _hgAncLeaves:int;
		private var _hgDescLeaves:int;

		public function Pages() {
			init();
		}
		
		private function init():void {
			_allPages = new Object();
			_pedigreeItems = new ArrayCollection();
			_descendencyItems = new ArrayCollection();
			_indexPages = new ArrayCollection();
			_indexPages.sort = getSort("title");
//			_changedPages = new ArrayCollection();
//			_changedPages.sort = getSort(Model.INDEX_LABEL);
			_bookmarks = new ArrayCollection();
			_bookmarks.sort = getSort("nsTitle");
			_hgPages = new Array();
			_hgAncLeaves = 0;
			_hgDescLeaves = 0;
		}
		
		public function clearAll():void {
			init();
			dispatchEvent(new Event("pagesChanged"));
			dispatchEvent(new Event("indexPagesChanged"));
			dispatchEvent(new Event("pedigreeItemsChanged"));
			dispatchEvent(new Event("descendencyItemsChanged"));
//			dispatchEvent(new Event("changedPagesChanged"));
			dispatchEvent(new Event("bookmarksChanged"));
			dispatchEvent(new Event("hgPagesChanged"));
			dispatchEvent(new Event("hgAncLeavesChanged"));
			dispatchEvent(new Event("hgDescLeavesChanged"));
		}
		
		public function get allPages():Object {
			return _allPages;
		}
		
//		[Bindable("changedPagesChanged")]
//		public function get changedPages():ArrayCollection {
//			return _changedPages;
//		}
		
		[Bindable("indexPagesChanged")]
		public function get indexPages():ArrayCollection {
			return _indexPages;
		}
		
		[Bindable("pedigreeItemsChanged")]
		public function get pedigreeItems():ArrayCollection {
			return _pedigreeItems;
		}
		
		[Bindable("descendencyItemsChanged")]
		public function get descendencyItems():ArrayCollection {
			return _descendencyItems;
		}
		
		[Bindable("bookmarksChanged")]
		public function get bookmarks():ArrayCollection {
//			logger.debug("get bookmarks " + _bookmarks.length);
			return _bookmarks;
		}
		
		[Bindable("hgPagesChanged")]
		public function get hgPages():Array {
			return _hgPages;
		}
		
		[Bindable("hgAncLeavesChanged")]
		public function get hgAncLeaves():int {
			return _hgAncLeaves;
		}
		
		[Bindable("hgDescLeavesChanged")]
		public function get hgDescLeaves():int {
			return _hgDescLeaves;
		}
		
		public function makePrimary(page:Page):void {
			// reset pedigree and descendency pages
			pedigreeItems.removeAll();
			descendencyItems.removeAll();
			if (page != null) {
				var item:Object = page.toTreeItem(true);
				pedigreeItems.addItem(item);
				item = page.toTreeItem(false);
				descendencyItems.addItem(item);
			}
			
			dispatchEvent(new Event("pedigreeItemsChanged"));
			dispatchEvent(new Event("descendencyItemsChanged"));
		}
		
		public function makeSelected(page:Page):void {
//			hgPages.length = 0;
			if (page != null) {
//logger.warn("makeSelected compute");
				computeHourglassPages(true);
			}
		}
		
		private static function getSort(fieldName:String):Sort {
			var sort:Sort = new Sort();
			sort.fields = [new SortField(fieldName, true)];
			return sort;
		}
		
		private function belongsInIndex(page:Page):Boolean {
			return (page.isInTree && 
					  (Model.instance.selectedNamespace == -1 || page.ns == Model.instance.selectedNamespace) &&
				     page.matches(Model.instance.findTokens));
		}
		
		// ns is -1 to select all namespaces except people and families
		public function computeIndexPages(defaultSort:Boolean):void {
//			logger.debug("computeIndexPages begin");
			// remove all pages
			_indexPages.removeAll();
			// sort on title by default
			if (defaultSort) {
				_indexPages.sort = getSort(Model.instance.selectedNamespace == -1 ? "nsTitle" : "title");
			}
			_indexPages.refresh();
			// add pages
			for each (var page:Page in _allPages) {
				if (belongsInIndex(page)) {
					_indexPages.addItem(page);
				}
			}
			// refresh and dispatch event
//			logger.debug("computeIndexPages end");
			dispatchEvent(new Event("indexPagesChanged"));
		}		
		
		private function addAncestorPages(page:Page, generations:int, newHgPages:Array, leaves:Object, cacheRequests:Array):Boolean {
			if (!page.isInTree || generations > Model.instance.hgAncGenerations) {
				return false;
			}
			if (!page.isCached) {
				if (cacheRequests.indexOf(page) < 0) {
					cacheRequests.push(page);
				}
				return false;
			}
			var added:Boolean = false;
			if (page.ns == Model.PERSON_NS) {
				for each (var familyTitle:String in PersonPage(page).childOfFamilies) {
					var familyPage:Page = getPage(Model.FAMILY_NS, familyTitle);
					newHgPages.push(familyPage);
					added = true;
					if (!addAncestorPages(familyPage, generations, newHgPages, leaves, cacheRequests)) {
						leaves.ancLeaves++;
					}
				}
			}
			else {
				for each (var spouseTitle:String in FamilyPage(page).husbands) {
					var spousePage:Page = getPage(Model.PERSON_NS, spouseTitle);
					newHgPages.push(spousePage);
					added = true;
					if (!addAncestorPages(spousePage, generations+1, newHgPages, leaves, cacheRequests)) {
						leaves.ancLeaves++;
					}
				}
				for each (spouseTitle in FamilyPage(page).wives) {
					spousePage = getPage(Model.PERSON_NS, spouseTitle);
					newHgPages.push(spousePage);
					added = true;
					if (!addAncestorPages(spousePage, generations+1, newHgPages, leaves, cacheRequests)) {
						leaves.ancLeaves++;
					}
				}
			}
			return added;
		}
		
		private function addDescendantPages(page:Page, generations:int, newHgPages:Array, leaves:Object, cacheRequests:Array):Boolean {
			if (!page.isInTree || generations > Model.instance.hgDescGenerations) {
				return false;
			}
			if (!page.isCached) {
				if (cacheRequests.indexOf(page) < 0) {
					cacheRequests.push(page);
				}
				return false;
			}
			var added:Boolean = false;
			if (page.ns == Model.PERSON_NS) {
				for each (var familyTitle:String in PersonPage(page).spouseOfFamilies) {
					var familyPage:Page = getPage(Model.FAMILY_NS, familyTitle);
					newHgPages.push(familyPage);
					added = true;
					if (!addDescendantPages(familyPage, generations, newHgPages, leaves, cacheRequests)) {
						leaves.descLeaves++;
					}
				}
			}
			else {
				for each (var childTitle:String in FamilyPage(page).children) {
					var childPage:Page = getPage(Model.PERSON_NS, childTitle);
					newHgPages.push(childPage);
					added = true;
					if (!addDescendantPages(childPage, generations+1, newHgPages, leaves, cacheRequests)) {
						leaves.descLeaves++;
					}
				}
			}
			return added;
		}
		
		public function computeHourglassPages(forceEvents:Boolean):void {
//			logger.info("computeHourglassPages");
			var newHgPages:Array = new Array();
			var leaves:Object = {ancLeaves:0, descLeaves:0};
			var cacheRequests:Array = new Array();
			if (Model.instance.selectedPage != null) {
				var ns:int = Utils.getMainNs(Model.instance.selectedPage.ns);
				var page:Page = Model.instance.pages.getPage(ns, Model.instance.selectedPage.title);
				if (page.ns == Model.PERSON_NS || ns == Model.FAMILY_NS) {
					newHgPages = new Array();
					newHgPages.push(page);
					addAncestorPages(page, 1, newHgPages, leaves, cacheRequests);
					addDescendantPages(page, 1, newHgPages, leaves, cacheRequests);
				}
				else { // non person/family page selected, so just return
					return;
				}
			}
			if (leaves.ancLeaves == 0) {
				leaves.ancLeaves = 1;
			}
			if (leaves.descLeaves == 0) {
				leaves.descLeaves = 1;
			}
//			logger.debug("computeHourglassPages count=" + newHgPages.length + " _hgPages=" + _hgPages.length);
			var dispatch:Boolean = forceEvents || Utils.arrayListDiff(_hgPages, newHgPages);
			if (dispatch) {
//				logger.info("computeHourglassPages dispatching ancLeaves=" + leaves.ancLeaves + " descLeaves=" + leaves.descLeaves);
				_hgPages = newHgPages;
				_hgAncLeaves = leaves.ancLeaves;
				_hgDescLeaves = leaves.descLeaves;
				dispatchEvent(new Event("hgAncLeavesChanged"));
				dispatchEvent(new Event("hgDescLeavesChanged"));
				dispatchEvent(new Event("hgPagesChanged"));
				for each (page in cacheRequests) {
//					logger.debug("computeHourglassPages cachePage");
					Controller.instance.cacheManager.cachePage(page);
				}
			}
		}
		
//		public function computeChangedPages():void {
//			logger.debug("computeChangedPages");
//			// remove all pages
//			if (_changedPages.length > 0)	_changedPages.removeAll();
//			// add pages
//			for (var key:String in _allPages) {
//				var page:Page = _allPages[key];
//				if (page.isInTree && !page.isCurrent) {
//					logger.debug("computeChangedPages " + page.title);
//					_changedPages.addItem(page);
//				}
//			}
//			// refresh view and dispatch event
//			_changedPages.refresh();
//			dispatchEvent(new Event("changedPagesChanged"));
//		}
		
		public function computeBookmarks():void {
//			logger.debug("computeBookmarks");
			// remove all pages
			_bookmarks.removeAll();
			// add pages
			for (var key:String in _allPages) {
				var page:Page = _allPages[key];
				if (page.isInTree && page.isBookmarked) {
					_bookmarks.addItem(page);
				}
			}
			// refresh view and dispatch event
			_bookmarks.refresh();
			dispatchEvent(new Event("bookmarksChanged"));
		}

		private function replacePageInTree(children:ArrayCollection, pos:int, page:Page, isPedigree:Boolean):void {
//			logger.info("replacePageInTree " + page.title + " " + pos + " -> " + children.length);
			children.removeItemAt(pos);
//			logger.info("   addItemAt");
			children.addItemAt(page.toTreeItem(isPedigree), pos);
//			logger.info("   end");
		}
		
 		private function updateTree(children:ArrayCollection, page:Page, isPedigree:Boolean):Boolean {
 			var updated:Boolean = false;
 			if (children != null) {
 				for (var i:int = 0; i < children.length; i++) {
 					var child:Object = children.getItemAt(i);
	 				if (child.page.ns == page.ns && child.page.title == page.title) {
//	 					logger.debug("updateTree " + page.title);
	 					// replace child
	 					replacePageInTree(children, i, page, isPedigree);
	 					updated = true;
	 				}
	 				if (updateTree(child.children, page, isPedigree)) {
	 					updated = true;
	 				}
	 			}
	 		}
	 		return updated;
 		}
 		
 		public static function getPageIndex(pages:ArrayCollection, page:Page):int {
 			if (page == null) {
	 			return -1;
 			}
 			else if (pages == null || pages.length == 0) {
 				return -1;
 			} 			
// 			return pages.getItemIndex(page);  DOESN'T ALWAYS WORK
 			for (var i:int = 0; i < pages.length; i++) {
 				if (pages[i] == page) {
//					logger.warn("getPageIndex " + i + "=" + pages.getItemIndex(page) + " " + (pages[i] == page ? "equal" : "not") + " " + page.title);
 					return i;
 				}
 			}
 			return -1;
 		}
 		
		public function pageChanged(page:Page):void {
			if (page == null || Model.instance.suspendViewUpdate) {
				return;
			}

			var index:int = getPageIndex(_indexPages, page);
//			logger.info("pageChanged " + index + " " + page.title);
			var indexChanged:Boolean = false;
			var pageBelongsInIndex:Boolean = belongsInIndex(page);
			if (index >= 0 && !pageBelongsInIndex) {
				_indexPages.removeItemAt(index);
				indexChanged = true;
			}
			else if (index == -1 && pageBelongsInIndex) {
				_indexPages.addItem(page);
				indexChanged = true;
			}
			if (indexChanged) {
				_indexPages.refresh();
			}
			// if the selectedNamespace is -1, then we're just showing the titles, which (almost) never change
			if (indexChanged || (index >= 0 && pageBelongsInIndex && Model.instance.selectedNamespace != -1)) {
//				logger.debug("pageChanged indexChanged");
				dispatchEvent(new Event("indexPagesChanged"));
			}
			
//			index = getPageIndex(_changedPages, page);
//			var changedPagesChanged:Boolean = false;
//			if (index >= 0 && !(page.isInTree && !page.isCurrent)) {
//				_changedPages.removeItemAt(index);
//				changedPagesChanged = true;
//				logger.debug("pageChanged changesRemoved " + page.title);
//			}
//			else if (index == -1 && page.isInTree && !page.isCurrent) {
//				_changedPages.addItem(page);
//				changedPagesChanged = true;
//				logger.debug("pageChanged changesAdded " + page.title);
//			}
//			if (changedPagesChanged) {
//				_changedPages.refresh();
//			}
//			if (changedPagesChanged || (index >= 0 && page.isInTree && !page.isCurrent)) {
//				logger.debug("pageChanged changesChanged " + page.title);
//				dispatchEvent(new Event("changedPagesChanged"));
//			}
			
			index = getPageIndex(_bookmarks, page);
			var bookmarksChanged:Boolean = false;
			if (index >= 0 && !(page.isInTree && page.isBookmarked)) {
				_bookmarks.removeItemAt(index);
				bookmarksChanged = true;
			}
			else if (index == -1 && page.isInTree && page.isBookmarked) {
//				logger.debug("pageChanged add bookmark");
				_bookmarks.addItem(page);
				bookmarksChanged = true;
			}
			if (bookmarksChanged) {
//				logger.debug("pageChanged bookmarksChanged");
				_bookmarks.refresh();
				dispatchEvent(new Event("bookmarksChanged"));
			}

//logger.warn("pageChanged compute");
			computeHourglassPages(false);
			
			if (updateTree(_pedigreeItems, page, true)) {
				//TODO necessary?
				dispatchEvent(new Event("pedigreeItemsChanged"));
			}
			if (updateTree(_descendencyItems, page, false)) {
				//TODO necessary?
				dispatchEvent(new Event("descendencyItemsChanged"));
			}
		}
		
		private function getPageKey(ns:int, title:String):String {
			return ns + ":" + title;
		}
		
		private function createPage(ns:int, title:String):Page {
			var page:Page;
			if (ns == Model.PERSON_NS) {
				page = new PersonPage(this, title);
			}
			else if (ns == Model.FAMILY_NS) {
				page = new FamilyPage(this, title);
			}
			else {
				page = new Page(this, ns, title);
			}
			return page;
		}
		
		// guaranteed to return the same object for the same ns and title
		public function getPage(ns:int, title:String):Page {
			var key:String = getPageKey(ns, title);
			var page:Page = _allPages[key];
			if (page != null) {
				return page;
			}
			// create a new page
			page = createPage(ns, title);
			_allPages[key] = page;
			return page;
		}
		
		public function renamePage(oldNs:int, oldTitle:String, newNs:int, newTitle:String):Page {
//			logger.info("renamePage " + oldNs + ":" + oldTitle + "->" + newNs + ":" + newTitle);
			var oldKey:String = getPageKey(oldNs, oldTitle);
			var page:Page = getPage(oldNs, oldTitle);
			var newKey:String = getPageKey(newNs, newTitle);
			delete _allPages[oldKey];
			_allPages[newKey] = page;
			page.title = newTitle;
			page.ns = newNs;
			return page;
		}
	}
}