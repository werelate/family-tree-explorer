package org.werelate.fte.model
{
	import flash.events.Event;
	import mx.utils.StringUtil;
	import mx.collections.ArrayCollection;
	import org.werelate.fte.util.Utils;
	import org.werelate.fte.util.DateUtils;
	
	public class PersonPage extends Page
	{
		private var _name:String;
		private var _given:String;
		private var _surname:String;
//		private var _surnameGiven:String;
		private var _nameSortKey:String;
		private var _birth:String;
//		private var _birthSortKey:String;
		private var _death:String;
//		private var _deathSortKey:String;
		private var _birthdate:String;
		private var _deathdate:String;
		private var _gender:String;
		private var _childOfFamilies:Array;
		private var _spouseOfFamilies:Array;
		
		public function PersonPage(pages:Pages, title:String) {
			super(pages, Model.PERSON_NS, title);
			_name = "";
			_given = "";
			_surname = "";
//			_surnameGiven = "";
			_nameSortKey = "";
			_birth = "";
//			_birthSortKey = "";
			_death = "";
//			_deathSortKey = "";
			_birthdate = "";
			_deathdate = "";
			_gender = "";
			_childOfFamilies = new Array();
			_spouseOfFamilies = new Array();
			setNameSortKey(new Event("titleChanged"));
			super.addEventListener("titleChanged", setNameSortKey);
			dispatchEvent(new Event("summaryChanged"));
			dispatchEvent(new Event("tipChanged"));
			dispatchEvent(new Event("nameChanged"));
			dispatchEvent(new Event("givenChanged"));
			dispatchEvent(new Event("surnameChanged"));
//			dispatchEvent(new Event("surnameGivenChanged"));
			dispatchEvent(new Event("birthChanged"));
//			dispatchEvent(new Event("birthSortKeyChanged"));
			dispatchEvent(new Event("deathChanged"));
//			dispatchEvent(new Event("deathSortKeyChanged"));
			dispatchEvent(new Event("genderChanged"));
			dispatchEvent(new Event("childOfFamiliesChanged"));
			dispatchEvent(new Event("spouseOfFamiliesChanged"));
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
					"\n" + name + "\n" + 
					(_birth ? "b. " + _birth : "") + "\n" + 
					(_death ? "d. " + _death : "") + "\n";
					ordinanceSummary;
//					(isCurrent ? "" : lastmodMsg);
			}
		}
		
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
				return name + (_birthdate ? "  b. " + _birthdate : "") + (_deathdate ? "  d. " + _deathdate : "");
//						+ (isCurrent ? "" : ""); // " "+lastmodMsg);
			}
		}

		[Bindable("nameChanged")]	
		public function get name():String {
			requestCache();
			return _name;
		}
		
		[Bindable("givenChanged")]	
		public function get given():String {
			requestCache();
			return _given;
		}
		
		[Bindable("surnameChanged")]	
		public function get surname():String {
			requestCache();
			return _surname;
		}
		
//		[Bindable("surnameGivenChanged")]	
//		public function get surnameGiven():String {
//			return _surnameGiven;
//		}
		
		[Bindable("nameSortKeyChanged")]	
		public function get nameSortKey():String {
			return _nameSortKey;
		}
		
		private function setNameSortKey(event:Event):void {
			var pieces:Array = title.split(/\s+/);
			if (pieces.length > 1) {
				_nameSortKey = '';
				for (var i:int = 1; i < pieces.length-1; i++) {
					_nameSortKey += String(pieces[i]).toLowerCase() + " ";
				}
				_nameSortKey += String(pieces[0]).toLowerCase();
			}
			else {
				_nameSortKey = " " + title.toLowerCase();
			}
			dispatchEvent(new Event("nameSortKeyChanged"));
		}
		
		[Bindable("birthChanged")]	
		public function get birth():String {
			requestCache();
			return _birth;
		}
		
//		[Bindable("birthSortKeyChanged")]	
//		public function get birthSortKey():String {
//			requestCache();
//			return _birthSortKey;
//		}
		
		[Bindable("deathChanged")]	
		public function get death():String {
			requestCache();
			return _death;
		}

//		[Bindable("deathSortKeyChanged")]	
//		public function get deathSortKey():String {
//			requestCache();
//			return _deathSortKey;
//		}

		[Bindable("genderChanged")]	
		public function get gender():String {
			requestCache();
			return _gender;
		}
		
		[Bindable("childOfFamiliesChanged")]	
		public function get childOfFamilies():Array {
			requestCache();
			return _childOfFamilies;
		}
		
		[Bindable("spouseOfFamiliesChanged")]	
		public function get spouseOfFamilies():Array {
			requestCache();
			return _spouseOfFamilies;
		}
		
		public static function getDatePlace(xml:XML, eventType:String):String {
			var date:String = xml.event_fact.(@type == eventType).@date;
			var place:String = xml.event_fact.(@type == eventType).@place;
			var barPos:int = place.indexOf("|");
			if (barPos >= 0) {
				place = place.substr(barPos+1);
			}
			if (date.length > 0 && place.length > 0) {
				return date + ", " + place;
			}
			else {
				return date + place;
			}
		}
		
		private static function setFamilies(xmlList:XMLList, families:Array):void {
			families.length = 0;
			for each (var family:XML in xmlList) {
				families.push(String(family.@title));
			}
		}
		
		private function addChangedPages(oldTitles:Array, newTitles:Array, changedPages:Array):void {
			var titles:Array = Utils.arraySetDiff(oldTitles, newTitles);
			for each (var title:String in titles) {
				changedPages.push(_pages.getPage(Model.FAMILY_NS, title));
			}
		}

		override public function setFields(text:String, data:String):Array {
			var changedPages:Array = new Array();
//			logger.debug("Person setFields " + text);
			var start:int = text.indexOf("<person>");
			if (start >= 0) {
				var end:int = text.indexOf("</person>", start);
				if (end >= 0) {
					var xml:XML = XML(text.substring(start, end + "</person>".length + 1));
					_name = StringUtil.trim(xml.name.@title_prefix + " " + xml.name.@given + " " + 
													xml.name.@surname + " " + xml.name.@title_suffix);
					_given = xml.name.@given;
					_surname = xml.name.@surname;
//					_surnameGiven = StringUtil.trim(_surname + ", " + _given + " " + xml.name.@title_suffix);
					_birth = getDatePlace(xml, "Birth");
					_death = getDatePlace(xml, "Death");
					_birthdate = xml.event_fact.(@type == "Birth").@date;
					_deathdate = xml.event_fact.(@type == "Death").@date;
//					_birthSortKey = DateUtils.getDateSortKey(_birthdate);
//					logger.debug("Person setFields date=" + _birthdate + " key=" + _birthSortKey);
//					_deathSortKey = DateUtils.getDateSortKey(_deathdate);
//					logger.debug("Person setFields date=" + _deathdate + " key=" + _deathSortKey);
					_gender = xml.gender;

					// construct related pages from WLH
					if (hasBeenChanged && !isCached) {
						for each (var p:Page in _pages) {
							if (p is FamilyPage) {
								if (FamilyPage(p).husbands.indexOf(this.title) >= 0 ||
									 FamilyPage(p).wives.indexOf(this.title) >= 0) {
									_spouseOfFamilies.push(p.title);
								}
								if (FamilyPage(p).children.indexOf(this.title) >= 0) {
									_childOfFamilies.push(p.title);
								}
							}
						}
					}

					var oldTitles:Array;
					if (hasBeenChanged) {
						oldTitles = _childOfFamilies.slice();
					} 
					setFamilies(xml.child_of_family, _childOfFamilies);
					if (hasBeenChanged) {
						addChangedPages(oldTitles, _childOfFamilies, changedPages);
					}

					if (hasBeenChanged) {
						oldTitles = _spouseOfFamilies.slice();
					}
					setFamilies(xml.spouse_of_family, _spouseOfFamilies);
					if (hasBeenChanged) {
						addChangedPages(oldTitles, _spouseOfFamilies, changedPages);
					}
					
//					logger.debug("Person setFields2 " + _name + ":" + _birth + ":" + _death + ":" + _gender);
					dispatchEvent(new Event("summaryChanged"));
					dispatchEvent(new Event("tipChanged"));
					dispatchEvent(new Event("nameChanged"));
					dispatchEvent(new Event("givenChanged"));
					dispatchEvent(new Event("surnameChanged"));
//					dispatchEvent(new Event("surnameGivenChanged"));
					dispatchEvent(new Event("birthChanged"));
//					dispatchEvent(new Event("birthSortKeyChanged"));
					dispatchEvent(new Event("deathChanged"));
//					dispatchEvent(new Event("deathSortKeyChanged"));
					dispatchEvent(new Event("genderChanged"));
					dispatchEvent(new Event("childOfFamiliesChanged"));
					dispatchEvent(new Event("spouseOfFamiliesChanged"));
				}
			}
			super.setFields(text, data);
			return changedPages;
		}
		
		private function getFamilyPages(titles:Array):Array {
			var result:Array = new Array();
			for each (var title:String in titles) {
				result.push(_pages.getPage(Model.FAMILY_NS, title));
			}
			return result;
		}
		
		override public function toTreeItem(pedigree:Boolean):Object {
			requestCache();
			if (pedigree && _childOfFamilies.length > 0) {
				return {children:new ArrayCollection(), childPages:getFamilyPages(_childOfFamilies), page:this};
			}
			else if (!pedigree && _spouseOfFamilies.length > 0) {
				return {children:new ArrayCollection(), childPages:getFamilyPages(_spouseOfFamilies), page:this};
			}
			else {
				return {page:this};
			}
		}

		override public function getRelatedPages():Array {
			return getFamilyPages(_childOfFamilies).concat(getFamilyPages(_spouseOfFamilies));
		}
	}
}
