package org.werelate.fte.model
{
	import flash.events.Event;
	import mx.utils.StringUtil;
	import mx.collections.ArrayCollection;
	import org.werelate.fte.util.Utils;
	import org.werelate.fte.util.DateUtils;
	
	public class FamilyPage extends Page
	{
		private var _husbandName:String;
		private var _husbandSortKey:String;
		private var _wifeName:String;
//		private var _wifeSortKey:String;
		private var _marriage:String;
		private var _marriagedate:String;
//		private var _marriageSortKey:String;
		private var _childrenInfo:String;
		private var _husbands:Array;
		private var _wives:Array;
		private var _children:Array;
		
		public function FamilyPage(pages:Pages, title:String) {
			super(pages, Model.FAMILY_NS, title);
			_husbandName = "";
			_husbandSortKey = "";
			_wifeName = "";
//			_wifeSortKey = "";
			_marriage = "";
			_marriagedate = "";
//			_marriageSortKey = "";
			_childrenInfo = "";
			_husbands = new Array();
			_wives = new Array();
			_children = new Array();
			setHusbandSortKey(new Event("titleChanged"));
			super.addEventListener("titleChanged", setHusbandSortKey);
			dispatchEvent(new Event("summaryChanged"));
			dispatchEvent(new Event("tipChanged"));
			dispatchEvent(new Event("husbandNameChanged"));
			dispatchEvent(new Event("wifeNameChanged"));
//			dispatchEvent(new Event("wifeSortKeyChanged"));
			dispatchEvent(new Event("marriageChanged"));
//			dispatchEvent(new Event("marriageSortKeyChanged"));
			dispatchEvent(new Event("childrenInfoChanged"));
			dispatchEvent(new Event("husbandsChanged"));
			dispatchEvent(new Event("wivesChanged"));
			dispatchEvent(new Event("childrenChanged"));
		}
		
		[Bindable("summaryChanged")]
		override public function get summary():String {
			requestCache();
			if (!isInTree) {
				return nsTitle + "\n(not in tree)";
			}
			else if (!isCached) {
//				return nsTitle + (isCurrent ? "\n(waiting to be cached)" : "") + "\n"+lastmodMsg);
				return nsTitle + "\n(waiting to be cached)";
			}
			else {
				return nsTitle + 
					"\nHusband: " + _husbandName + "\nWife: " + _wifeName + "\n" +
					(marriage ? "m. " + _marriage + "\n" : "") +
					ordinanceSummary +
					_childrenInfo;
//					(isCurrent ? "" : lastmodMsg);
			}
		}
		
		private static const indexNumber:RegExp = /\s+\(\d+\)$/;
		
		[Bindable("tipChanged")]
		override public function get tip():String {
			requestCache();
			if (!isInTree) {
				return title + " (not in tree)";
			}
			else if (!isCached) {
//				return title + (isCurrent ? " (waiting to be cached)" : "") + " "+lastmodMsg);
				return title + " (waiting to be cached)";
			}
			else {
				return (_husbandName ? _husbandName.replace(indexNumber,"") : "unknown") + " and " + 
				       (_wifeName ? _wifeName.replace(indexNumber,"") : "unknown") + 
						 (_marriagedate ? "  m. " + _marriagedate : "");
//						 (isCurrent ? "" : ""); //" "+lastmodMsg);
			}
		}
		
		[Bindable("husbandNameChanged")]	
		public function get husbandName():String {
			requestCache();
			return _husbandName;
		}
		
		[Bindable("husbandSortKeyChanged")]	
		public function get husbandSortKey():String {
//			requestCache();
			return _husbandSortKey;
		}
		
		private function setHusbandSortKey(event:Event):void {
			var spouses:Array = title.split(/\s+and\s+/, 2);
			var pieces:Array = String(spouses[0]).split(/\s+/);
			if (pieces.length > 1) {
				_husbandSortKey = '';
				for (var i:int = 1; i < pieces.length; i++) {
					_husbandSortKey += String(pieces[i]).toLowerCase() + " ";
				}
				_husbandSortKey += String(pieces[0]).toLowerCase();
			}
			else {
				_husbandSortKey = " " + title.toLowerCase();
			}
			dispatchEvent(new Event("husbandSortKeyChanged"));
		}
		
		[Bindable("wifeNameChanged")]	
		public function get wifeName():String {
			requestCache();
			return _wifeName;
		}
		
//		[Bindable("wifeSortKeyChanged")]	
//		public function get wifeSortKey():String {
//			requestCache();
//			return _wifeSortKey;
//		}
		
		[Bindable("childrenChanged")]
		public function get children():Array {
			requestCache();
			return _children;
		}
		
		[Bindable("childrenInfoChanged")]
		private function get childrenInfo():String {
			requestCache();
			return _childrenInfo;
		}
		
		[Bindable("husbandsChanged")]
		public function get husbands():Array {
			requestCache();
			return _husbands;
		}
		
		[Bindable("wivesChanged")]
		public function get wives():Array {
			requestCache();
			return _wives;
		}
		
		[Bindable("marriageChanged")]	
		public function get marriage():String {
			requestCache();
			return _marriage;
		}
		
//		[Bindable("marriageSortKeyChanged")]	
//		public function get marriageSortKey():String {
//			requestCache();
//			return _marriageSortKey;
//		}
		
		private static function getName(person:XML):String {
			var result:String = StringUtil.trim(person.@title_prefix + " " + person.@given + " " + 
															person.@surname + " " + person.@title_suffix);
			if (result.length == 0) {
				result = person.@title;
			}
			return result;
		}
		
		private static function getFirstPersonName(xmlList:XMLList):String {
			for each (var person:XML in xmlList) {
				return getName(person);
			}
			return "";
		}
		
		private static function getChildrenInfo(xmlList:XMLList):String {
			var result:String = "";
			for each (var person:XML in xmlList) {
				result += "child: " + getName(person) + 
						(person.@birthdate ? ", " + person.@birthdate : "") +"\n";
			}
			return result;
		}
		
//		private static function getSortKey(xmlList:XMLList):String {
//			for each (var person:XML in xmlList) {
//				var sort:String = StringUtil.trim(person.@surname + ", " + person.@given + " " + person.@title_suffix);
//				if (sort.length == 0) {
//					var title:String = String(person.@title);
//					var end:int = title.lastIndexOf(" (");
//					var start:int = 0;
//					if (end >= 0) {
//						start = title.lastIndexOf(" ", end-1);
//						if (start >= 0 && end - start > 1) {
//							sort = title.substring(start+1, end);
//						}
//					}
//				}
//				return sort;
//			}
//			return "";
//		}
		
		private static function getPersonTitles(xmlList:XMLList):Array {
			var result:Array = new Array();
			for each (var person:XML in xmlList) {
				result.push(String(person.@title));
			}
			return result;
		}
		
		private function addChangedPages(oldTitles:Array, newTitles:Array, changedPages:Array):void {
			var titles:Array = Utils.arraySetDiff(oldTitles, newTitles);
			for each (var title:String in titles) {
				changedPages.push(_pages.getPage(Model.PERSON_NS, title));
			}
		}

		override public function setFields(text:String, data:String):Array {
			var changedPages:Array = new Array();
//			logger.debug("Family setFields " + text);
			var start:int = text.indexOf("<family>");
			if (start >= 0) {
				var end:int = text.indexOf("</family>", start);
				if (end >= 0) {
					var xml:XML = XML(text.substring(start, end + "</family>".length + 1));
					_husbandName = getFirstPersonName(xml.husband);
//					_husbandSortKey = getSortKey(xml.husband);
					_wifeName = getFirstPersonName(xml.wife);
//					_wifeSortKey = getSortKey(xml.wife);
					_marriage = PersonPage.getDatePlace(xml, "Marriage");
					_marriagedate = xml.event_fact.(@type == "Marriage").@date;
//					_marriageSortKey = DateUtils.getDateSortKey(_marriagedate);
					_childrenInfo = getChildrenInfo(xml.child);
//					logger.debug("Family setFields date=" + _marriagedate + " key=" + _marriageSortKey);

					// construct related pages from WLH
					if (hasBeenChanged && !isCached) {
						for each (var p:Page in _pages) {
							if (p is PersonPage) {
								if (PersonPage(p).childOfFamilies.indexOf(this.title) >= 0) {
									_children.push(p.title);
								}
								if (PersonPage(p).spouseOfFamilies.indexOf(this.title) >= 0) {
									if (PersonPage(p).gender == "M") {
										_husbands.push(p.title);
									}
									else {
										_wives.push(p.title);
									}
								}
							}
						}
					}

					var oldTitles:Array;
					if (hasBeenChanged) {
						oldTitles = _husbands.slice();
					}
					_husbands = getPersonTitles(xml.husband);
					if (hasBeenChanged) {
						addChangedPages(oldTitles, _husbands, changedPages);
					}

					if (hasBeenChanged) {
						oldTitles = _wives.slice();
					}
					_wives = getPersonTitles(xml.wife);
					if (hasBeenChanged) {
						addChangedPages(oldTitles, _wives, changedPages);
					}
					
					if (hasBeenChanged) {
						oldTitles = _children.slice();
					}
					_children = getPersonTitles(xml.child);
					if (hasBeenChanged) {
						addChangedPages(oldTitles, _children, changedPages);
					}
					
//					logger.debug("Family setFields2 " + _husbandName + ":" + _wifeName + ":" + _marriage);
					dispatchEvent(new Event("summaryChanged"));
					dispatchEvent(new Event("tipChanged"));
					dispatchEvent(new Event("husbandNameChanged"));
//					dispatchEvent(new Event("husbandSortKeyChanged"));
					dispatchEvent(new Event("wifeNameChanged"));
//					dispatchEvent(new Event("wifeSortKeyChanged"));
					dispatchEvent(new Event("marriageChanged"));
//					dispatchEvent(new Event("marriageSortKeyChanged"));
					dispatchEvent(new Event("childrenInfoChanged"));
					dispatchEvent(new Event("husbandsChanged"));
					dispatchEvent(new Event("wivesChanged"));
					dispatchEvent(new Event("childrenChanged"));
				}
			}
			super.setFields(text, data);
			return changedPages;
		}
		
		private function getPersonPages(titles1:Array):Array {
			var result:Array = new Array();
			for each (var title:String in titles1) {
				result.push(_pages.getPage(Model.PERSON_NS, title));
			}
			return result;
		}
		
		override public function toTreeItem(pedigree:Boolean):Object {
			requestCache();
			if (pedigree && (_husbands.length > 0 || _wives.length > 0)) {
				return {children:new ArrayCollection(), 
							childPages:getPersonPages(_husbands).concat(getPersonPages(_wives)), page:this};
			}
			else if (!pedigree && _children.length > 0) {
				return {children:new ArrayCollection(), childPages:getPersonPages(_children), page:this};
			}
			else {
				return {page:this};
			}
		}
		
		override public function getRelatedPages():Array {
			return getPersonPages(_husbands).concat(getPersonPages(_wives)).concat(getPersonPages(_children));
		}
	}
}