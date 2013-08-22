package org.werelate.fte.model
{
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import org.werelate.fte.util.Utils;
	import org.werelate.fte.util.StringUtils;
	import org.werelate.fte.command.CacheManager;
	import org.werelate.fte.command.Controller;
	
	public class Page extends EventDispatcher
	{
		protected static const logger:ILogger = Log.getLogger("Page");
		protected static const BOOKMARK_FLAG:int = 1;
		protected static const GEDCOM_DEFAULT_FLAG:int = 2;

		protected var _pages:Pages;
		protected var _title:String;
		protected var _ns:int;
		protected var _oldid:int;
		protected var _latest:int
		protected var _flags:int;
		protected var _isInTree:Boolean;
		protected var _isCached:Boolean;
//		protected var _lastmodUser:String;
//		protected var _lastmodDate:String;
//		protected var _lastmodComment:String;
		protected var _text:String;
		protected var _data:String;
		protected var _dataVersion:int;
		protected var _cacheVersion:int;
		protected var _cacheDataVersion:int;
		
		public var hasBeenChanged:Boolean;
		private var _inRequest:Boolean;

		public function Page(pages:Pages, ns:int, title:String) {
			_pages = pages;
			_ns = ns;
			_title = title;
			_oldid = 0;
			_latest = 0;
			_flags = 0;
			_dataVersion = 0;
			_isInTree = false;
			_isCached = false;
			_inRequest = false;
//			_lastmodUser = "";
//			_lastmodDate = "";
//			_lastmodComment = "";
			hasBeenChanged = false;
			_text = "";
			_data = "";
			_cacheVersion = 0;
			_cacheDataVersion = 0;
			dispatchEvent(new Event("summaryChanged"));
			dispatchEvent(new Event("tipChanged"));
			dispatchEvent(new Event("titleChanged"));
			dispatchEvent(new Event("nsChanged"));
			dispatchEvent(new Event("nsTitleChanged"));
			dispatchEvent(new Event("isInTreeChanged"));
			dispatchEvent(new Event("isCachedChanged"));
//			dispatchEvent(new Event("isCurrentChanged"));
			dispatchEvent(new Event("isBookmarkedChanged"));
		}
		
		public function init(oldid:int, latest:int, dataVersion:int, lastmodUser:String, lastmodDate:String, lastmodComment:String, 
									flags:int, isInTree:Boolean):void {
			_oldid = oldid;
			_latest = latest;
			_dataVersion = dataVersion;
			_flags = flags;
			_isInTree = isInTree;
//			_lastmodUser = lastmodUser;
//			_lastmodDate = lastmodDate;
//			_lastmodComment = lastmodComment;
			dispatchEvent(new Event("summaryChanged"));
			dispatchEvent(new Event("tipChanged"));
			dispatchEvent(new Event("isInTreeChanged"));
//			dispatchEvent(new Event("isCurrentChanged"));
			dispatchEvent(new Event("isBookmarkedChanged"));
			pageChanged();
		}
		
		protected function pageChanged():void {
			this._pages.pageChanged(this);
		}

		public function requestCache():void {
			if (_isInTree && !_isCached && !_inRequest) {
				_inRequest = true;
				Controller.instance.cacheManager.cachePage(this);
				_inRequest = false;
			}
		}
		
		[Bindable("summaryChanged")]
		public function get summary():String {
			requestCache();
			if (!isInTree) {
				return nsTitle + "\n(not in tree)";
			}
//			else if (!isCurrent) {
//				return nsTitle + "\n"+lastmodMsg;
//			}
			else if (!isCached) {
				return nsTitle + "\n(waiting to be cached)";
			}
			else {
				return nsTitle;
			}
		}
		
		[Bindable("nsTitleChanged")]
		public function get nsTitle():String {
			return (ns == Model.MAIN_NS ? "" : (Utils.getNsString(ns) + ":")) + title;
		}
		
		[Bindable("tipChanged")]
		public function get tip():String {
			requestCache();
			if (!isInTree) {
				return nsTitle + " (not in tree)";
			}
//			else if (!isCurrent) {
//				return nsTitle + " " + lastmodMsg;
//			}
			else if (!isCached) {
				return nsTitle + " (waiting to be cached)";
			}
			else {
				return nsTitle;
			}
		}
		
		private function setCached(isCached:Boolean):void {
			if (_isCached != isCached) {
				_isCached = isCached;
				dispatchEvent(new Event("isCachedChanged"));
				dispatchEvent(new Event("summaryChanged"));
				dispatchEvent(new Event("tipChanged"));
			}
		}
		
		public function setFields(text:String, data:String):Array {
			_text = text;
			_data = dataVersion == 0 ? "" : data;
			setCached(true);
			hasBeenChanged = false;
			pageChanged();
			return new Array();
		}
		
		[Bindable("isCachedChanged")]
		public function get isCached():Boolean {
			return _isCached;
		}		
		
		public function set isCached(isCached:Boolean):void {
			setCached(isCached);
			pageChanged();
		}

		public function isCacheCurrent():Boolean {
			return (_cacheVersion == latest) && (_cacheDataVersion == dataVersion);
		}
		
		public function get cacheVersion():int {
			return _cacheVersion;
		}
		public function set cacheVersion(cacheVersion:int):void {
			_cacheVersion = cacheVersion;
		}
		
		public function get cacheDataVersion():int {
			return _cacheDataVersion;
		}
		public function set cacheDataVersion(cacheDataVersion:int):void {
			_cacheDataVersion = cacheDataVersion;
		}
		
//		public function get lastmodMsg():String {
//			if (_lastmodUser.length == 0) {
//				return "";
//			}
//			else {
//				return "(last modfied by " + _lastmodUser + " on " + _lastmodDate + 
//								(_lastmodComment.length > 0 ? ": " + _lastmodComment : "") + ")";
//			}
//		}
		
//		public function setLastmod(user:String, date:String, comment:String):void {
//			_lastmodUser = user;
//			_lastmodDate = date;
//			_lastmodComment = comment;
//			dispatchEvent(new Event("summaryChanged"));
//			dispatchEvent(new Event("tipChanged"));
//		}

		[Bindable("titleChanged")]
		public function get title():String {
			return _title;
		}
		
		public function set title(title:String):void {
			_title = title;
			dispatchEvent(new Event("titleChanged"));
			dispatchEvent(new Event("summaryChanged"));
			dispatchEvent(new Event("tipChanged"));
			dispatchEvent(new Event("nsTitleChanged"));
		}

		[Bindable("nsChanged")]
		public function get ns():int {
			return _ns;
		}
		
		public function set ns(ns:int):void {
			_ns = ns;
			dispatchEvent(new Event("nsChanged"));
			dispatchEvent(new Event("summaryChanged"));
			dispatchEvent(new Event("tipChanged"));
			dispatchEvent(new Event("nsTitleChanged"));
		}
		
		public function get isTalkPage():Boolean {
			return Utils.getTalkNs(ns) == ns;
		}
		
		public function get dataVersion():int {
			return _dataVersion;
		}
		
		public function set dataVersion(dataVersion:int):void {
			_dataVersion = dataVersion;
		}
		
		public function get oldid():int {
			return _oldid;
		}

		public function set oldid(oldid:int):void {
			if (_oldid != oldid) {
				_oldid = oldid;
//				dispatchEvent(new Event("isCurrentChanged"));
				dispatchEvent(new Event("summaryChanged"));
				dispatchEvent(new Event("tipChanged"));
				pageChanged();
			}
		}
		
//		[Bindable("isCurrentChanged")]
//		public function get isCurrent():Boolean {
//			return oldid == latest;
//		}		
		
		public function get latest():int {
			return _latest;
		}

		public function updateLatest(revid:int):Boolean {
			if (revid > latest) {
//				logger.warn("updateLatest " + title + " " + revid);
				latest = revid;
				return true;
			}
			return false;
		}
		
		public function set latest(latest:int):void {
			if (_latest != latest) {
//				logger.warn("setLatest " + title + " " + latest);
				_latest = latest;
//				dispatchEvent(new Event("isCurrentChanged"));
				dispatchEvent(new Event("summaryChanged"));
				dispatchEvent(new Event("tipChanged"));
				pageChanged();
			}
		}
		
		[Bindable("isInTreeChanged")]
		public function get isInTree():Boolean {
			return _isInTree;
		}
		
		public function set isInTree(isInTree:Boolean):void {
			if (_isInTree != isInTree) {
				_isInTree = isInTree;
				dispatchEvent(new Event("isInTreeChanged"));
				dispatchEvent(new Event("summaryChanged"));
				dispatchEvent(new Event("tipChanged"));
				pageChanged();
			}
		}		
		
		[Bindable("isBookmarkedChanged")]
		public function get isBookmarked():Boolean {
			return (_flags & BOOKMARK_FLAG) == BOOKMARK_FLAG;
		}
		
		public function set isBookmarked(isBookmarked:Boolean):void {
			if (isBookmarked) {
				_flags |= BOOKMARK_FLAG;
			}
			else {
				_flags &= ~BOOKMARK_FLAG;
			}
			dispatchEvent(new Event("isBookmarkedChanged"));
			pageChanged();
		}
		
		public function get isGedcomDefault():Boolean {
			return (_flags & GEDCOM_DEFAULT_FLAG) == GEDCOM_DEFAULT_FLAG;
		}
		
		public function set flags(flags:int):void {
			_flags = flags;
			dispatchEvent(new Event("isBookmarkedChanged"));
		}
		
		public function isSelectable():Boolean {
			return Utils.isSelectableNs(ns);
		}
		
		public function get ordinanceSummary():String {
			if (_data.length == 0) {
				return "";
			}
			var result:String = "";
			var xml:XML = dataAsXML;
			for each (var ordinance:XML in xml.children()) {
				var name:String = Model.ordinanceMap[ordinance.name()];
				if (name) {
					var templePlace:String = TempleCodes.getTemple(ordinance.@temple).place;
					result += name + ": " + ordinance.@date + " " + templePlace + "\n";
				}
			}
			return result;
		}
		
		public function get data():String {
			return _data;
		}
		
		public function get dataAsXML():XML {
//			logger.info("dataAsXML " + _data);
			if (_data.length > 0) {
				return new XML(_data);
			}
			else {
				return new XML("<data/>");
			}
		}
		
		public function updateOrdinances(ordinances:XMLList):void {
			var xml:XML = dataAsXML;
			delete xml.BAPL;
			delete xml.ENDL;
			delete xml.SLGC;
			delete xml.SLGS;
			for each (var ordinance:XML in ordinances) {
				if (ordinance.children().length() > 0 || ordinance.attributes().length() > 0) {
					xml.appendChild(ordinance);
				}
			}
			if (xml.children().length() == 0) {
				_data = "";
			}
			else {
				_data = xml.toXMLString();
			}
//			logger.debug("updateOrdinances " + data);
		}
		
		public function matches(tokens:Array):Boolean {
			if (tokens.length == 0) {
				return true;
			}
			var stdTitle:String = StringUtils.romanize(title.toLowerCase());
			var stdData:String = StringUtils.romanize(_data.toLowerCase());
			var stdText:String = StringUtils.romanize(_text.toLowerCase());
			for each (var token:String in tokens) {
				if (stdTitle.indexOf(token) < 0 && 
					 stdText.indexOf(token) < 0 &&
					 stdData.indexOf(token) < 0) {
					return false;
				}
			}
			return true;
		}
		
		public function toTreeItem(pedigree:Boolean):Object {
			// override 
			return null;
		}
		
		public function getRelatedPages():Array {
			return new Array();
		}
		
		public function getRelatedPageInTree():Page {
			for each (var page:Page in getRelatedPages()) {
//				logger.warn("related page " + page.title + (page.isInTree ? " yes" : " no"));
				if (page.isInTree) {
					return page;
				}
			}
			return null;
		}
	}
}