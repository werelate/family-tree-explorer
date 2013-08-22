package org.werelate.fte.view
{
	import flash.events.Event;
	import mx.events.TreeEvent;
	import mx.events.ListEvent;
	import mx.controls.Tree;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.collections.ArrayCollection;
	import mx.utils.ObjectUtil;

	import org.werelate.fte.model.Page;
	import org.werelate.fte.model.Model;
	import org.werelate.fte.command.Controller;
	import mx.controls.treeClasses.TreeItemRenderer;

	public class FamilyTree extends Tree
	{
		private static const logger:ILogger = Log.getLogger("FamilyTree");

		[Embed("../../../../../images/male.png")] 
      public var maleSymbol:Class; 
      [Embed("../../../../../images/female.png")] 
      public var femaleSymbol:Class;
		[Embed("../../../../../images/family.png")] 
      public var familySymbol:Class;
      [Embed("../../../../../images/question.png")] 
      public var unknownSymbol:Class;
      [Embed("../../../../../images/wait.png")] 
      public var hourglassSymbol:Class;
//      [Embed("../../../../../images/changed.png")] 
//      public var changedSymbol:Class;

		[Bindable]
		public var isPedigree:Boolean;
		
		private var myOpenItems:Object;
		private var mySelectedPage:Page;
		private var updating:Boolean;
		private var _highlightedPage:Page;
		private var currentPage:Page;
		
		public function FamilyTree()
		{
			super();
//			dataTipFunction = treeTipFunction;
			showDataTips = false;
			iconFunction = treeIconFunction;
			labelFunction = myLabelFunction;
			myOpenItems = openItems == null ? null : openItems.slice();
			mySelectedPage = null;
			updating = false;
			_highlightedPage = null;
			currentPage = null;
			addEventListener("itemOpen", itemOpen);
			addEventListener("itemClose", itemClose);
			addEventListener("change", change);
			addEventListener("itemClick", itemClick);
			addEventListener("valueCommit", valueCommit);
			addEventListener("mouseOver", mouseOver);
 		}
 		
 		private function mouseOver(event:Event):void {
 			if (event.target.parent is TreeItemRenderer) {
 				var tir:TreeItemRenderer = TreeItemRenderer(event.target.parent);
 				_highlightedPage = tir.data.page;
// 				logger.debug("mouseOver " + (_highlightedPage == null ? "null" : _highlightedPage.title));
 			}
 		}
 		
 		public function get highlightedPage():Page {
 			return _highlightedPage;
 		}
 		
 		private function cacheChildren(item:Object):void {
 			if (item != null && item.children != null && item.children.length == 0 && 
 				 item.childPages != null && item.childPages.length > 0) {
 				for each (var page:Page in item.childPages) {
 					item.children.addItem(page.toTreeItem(isPedigree));
 					Controller.instance.cacheManager.cachePage(page);
 				}
 			}
 		}
 		
 		private function itemOpen(event:TreeEvent):void {
// 			logger.debug("itemOpen " + event.item.page.title);
 			myOpenItems = openItems == null ? null : openItems.slice();
			cacheChildren(event.item);
			this.validateNow();
			selectPageIfVisible();
		}

 		private function itemClose(event:TreeEvent):void {
// 			logger.debug("itemClose " + event.item.page.title);
 			myOpenItems = openItems == null ? null : openItems.slice();
 		}
 		
 		private function change(event:Event):void {
// 			logger.debug("change");
			currentPage = Page(event.currentTarget.selectedItem.page);
 		}
 		
		private function itemClick(event:ListEvent):void {
			if (currentPage != null) {
//				logger.debug("itemClick " + currentPage.title);
				Controller.instance.loadPage(currentPage);
			}
		}
			
 		private function containsItem(items:Object, item:Object):Boolean {
 			for each (var i:Object in items) {
 				if (i.page.title == item.page.title && i.page.ns == item.page.ns) {
 					return true;
 				}
 			}
 			return false;
 		}
 		
 		private function reopenItemsRecursive(item:Object):void {
 			if (containsItem(myOpenItems, item)) {
				this.expandItem(item, true, false, false);
				cacheChildren(item);
 			}
			if (item.children != null) {
	 			for each (var child:Object in item.children) {
	 				reopenItemsRecursive(child);
	 			}
	 		}
	 	}
 		
 		private function reopenItems():void {
// 			logger.debug("reopenItems " + openItems.length + " : " + myOpenItems.length);
 			if (dataProvider.length > 0) {
	 			reopenItemsRecursive(dataProvider.getItemAt(0));
	 		}
 			myOpenItems = openItems == null ? null : openItems.slice();
 		}
 		
 		private function valueCommit(event:Event):void {
// 			logger.debug("valueCommit " + openItems.length + " : " + myOpenItems.length);
 			if (!updating && openItems.length == 0 && myOpenItems.length > 0) {
 				updating = true;
// 				logger.debug("updating ");
				invalidateList();
				reopenItems();
				validateNow();
//				logger.debug("selecting " + (mySelectedPage == null ? "null" : mySelectedPage.title));
				selectPageIfVisible();
				updating = false;
 			}
 		}
 		
 		private function getItemForPageRecursive(item:Object, page:Page):Object {
 			if (page == null) {
 				return null;
 			}
 			else if (item.page.title == page.title && item.page.ns == page.ns) {
 				return item;
 			}
			else if (item.children != null) {
	 			for each (var child:Object in item.children) {
					var result:Object = getItemForPageRecursive(child, page);
					if (result != null) {
						return result;
					}
	 			}
	 		}
	 		return null;
 		}
 		
 		private function getItemForPage(page:Page):Object {
// 			logger.debug("getItemForPage " + (page == null ? "null" : page.title + " " + page.ns));
 			if (dataProvider != null && dataProvider.length > 0) {
	 			return getItemForPageRecursive(dataProvider.getItemAt(0), page);
	 		}
	 		else {
	 			return null;
	 		}
 		}
 		
 		private function selectPageIfVisible():void {
 			var item:Object = getItemForPage(mySelectedPage);
	 		if (selectedItem == item) {
//	 			logger.debug("selectItemIfVisible same " + (item == null ? "null" : item.page.title));
	 			// do nothing - this case needs to be here
	 		}
 			else if (item != null && this.isItemVisible(item)) {
// 				logger.debug("selectItemIfVisible selecting item " + item.page.title);
	 			selectedItem = item;
	 		}
	 		else if (item == null) {
//	 			logger.debug("selectItemIfVisible null");
	 			selectedItem = null;
	 		}
	 		else {
//	 			logger.debug("selectItemIfVisible not visible");
	 			selectedItem = null;
	 		}
 		}
 		
 		public function set selectedPage(page:Page):void {
//			logger.debug("set selectedPage " + (page == null ? "null" : page.title));
	 		mySelectedPage = page;
			currentPage = page;
			selectPageIfVisible();
 		}
 		
 		public function set items(items:ArrayCollection):void {
// 			logger.debug("set items");
 			dataProvider = items;
 		}
 		
		private function myLabelFunction(item:Object):String {
			return item.page.tip;
		}		
		
//		private function treeTipFunction(item:Object):String {
//			return item.page.tip;
//		}
		
      private function treeIconFunction(item:Object):Class { 
      	if (!item.page.isInTree) {
      		return unknownSymbol;
      	}
      	else if (!item.page.isCached) {
      		return hourglassSymbol;
      	}
//      	else if (!item.page.isCurrent) {
//      		return changedSymbol;
//      	}
      	else if (item.page.ns == Model.FAMILY_NS) {
      		return familySymbol;
      	}
      	else if (item.page.ns == Model.PERSON_NS && item.page.gender == "M") {
				return maleSymbol;
			}
			else if (item.page.ns == Model.PERSON_NS && item.page.gender == "F") {
				return femaleSymbol;
			}
			else {
				return unknownSymbol;
			}
		}
	}
}