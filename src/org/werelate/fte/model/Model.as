package org.werelate.fte.model
{
	import flash.events.Event;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import flash.events.EventDispatcher;
	import mx.collections.IList;
	import org.werelate.fte.util.Utils;
	import flash.net.SharedObject;
	import org.werelate.fte.command.CacheManager;
	import mx.utils.StringUtil;
	import org.werelate.fte.util.StringUtils;
	import mx.rpc.events.ResultEvent;
	import org.werelate.fte.service.WRServices;
	import mx.core.Application;
	import mx.controls.Alert;
	
	public class Model extends EventDispatcher // implements IHistoryManagerClient
	{
		public static var WR_HOST:String;
		public static var WR_INDEX_URL:String;
		public static var WR_WIKI_PATH:String;
		public static var WR_HOMEPAGE:String;

		private static const logger:ILogger = Log.getLogger("Model");
		public static const INDEX_LABEL:String = "tip";
		
		public static const SPECIAL_NS:int = -1;
		public static const SPECIAL_NSSTR:String = "Special";
		public static const MAIN_NS:int = 0;
		public static const MAIN_NSSTR:String = "";
		public static const USER_NS:int = 2;
		public static const USER_NSSTR:String = "User";
		public static const PROJECT_NS:int = 4;
		public static const PROJECT_NSSTR:String = "WeRelate";
		public static const IMAGE_NS:int = 6;
		public static const IMAGE_NSSTR:String = "Image";
		public static const HELP_NS:int = 12;
		public static const HELP_NSSTR:String = "Help";
		public static const CATEGORY_NS:int = 14;
		public static const CATEGORY_NSSTR:String = "Category";
		public static const GIVENNAME_NS:int = 100;
		public static const GIVENNAME_NSSTR:String = "Givenname";
		public static const SURNAME_NS:int = 102;
		public static const SURNAME_NSSTR:String = "Surname";
		public static const SOURCE_NS:int = 104;
		public static const SOURCE_NSSTR:String = "Source";
		public static const PLACE_NS:int = 106;
		public static const PLACE_NSSTR:String = "Place";
		public static const PERSON_NS:int = 108;
		public static const PERSON_NSSTR:String = "Person";
		public static const FAMILY_NS:int = 110;
		public static const FAMILY_NSSTR:String = "Family";
		public static const MYSOURCE_NS:int = 112;
		public static const MYSOURCE_NSSTR:String = "MySource";
		public static const MAIN_TALK_NS:int = 1;
		public static const MAIN_TALK_NSSTR:String = "Talk";
		public static const USER_TALK_NS:int = 3;
		public static const USER_TALK_NSSTR:String = "User talk";
		public static const PROJECT_TALK_NS:int = 5;
		public static const PROJECT_TALK_NSSTR:String = "WeRelate talk";
		public static const IMAGE_TALK_NS:int = 7;
		public static const IMAGE_TALK_NSSTR:String = "Image talk";
		public static const HELP_TALK_NS:int = 13;
		public static const HELP_TALK_NSSTR:String = "Help talk";
		public static const CATEGORY_TALK_NS:int = 15;
		public static const CATEGORY_TALK_NSSTR:String = "Category talk";
		public static const GIVENNAME_TALK_NS:int = 101;
		public static const GIVENNAME_TALK_NSSTR:String = "Givenname talk";
		public static const SURNAME_TALK_NS:int = 103;
		public static const SURNAME_TALK_NSSTR:String = "Surname talk";
		public static const SOURCE_TALK_NS:int = 105;
		public static const SOURCE_TALK_NSSTR:String = "Source talk";
		public static const PLACE_TALK_NS:int = 107;
		public static const PLACE_TALK_NSSTR:String = "Place talk";
		public static const PERSON_TALK_NS:int = 109;
		public static const PERSON_TALK_NSSTR:String = "Person talk";
		public static const FAMILY_TALK_NS:int = 111;
		public static const FAMILY_TALK_NSSTR:String = "Family talk";
		public static const MYSOURCE_TALK_NS:int = 113;
		public static const MYSOURCE_TALK_NSSTR:String = "MySource talk";
		
		public static const HOURGLASS_TAB:int = 0;
		public static const ANCESTORS_TAB:int = 1;
		public static const DESCENDANTS_TAB:int = 2;
		public static const INDEX_TAB:int = 3;
//		public static const CHANGED_PAGES_TAB:int = 4;
		
      public static const ordinanceMap:Object = 
      	{BAPL:"Baptism", ENDL:"Endowment", SLGC:"Seal to Parents", SLGS:"Seal to Spouse"};
      			
		/** Reference to singleton instance of this class. */
		private static var _instance:Model;
		
		public var allNamespaces:Array = [ 
					{label:PERSON_NSSTR, ns:PERSON_NS}, 
               {label:FAMILY_NSSTR, ns:FAMILY_NS}, 
               {label:SOURCE_NSSTR, ns:SOURCE_NS},
               {label:MYSOURCE_NSSTR, ns:MYSOURCE_NS}, 
               {label:IMAGE_NSSTR, ns:IMAGE_NS},
					{label:MAIN_NSSTR, ns:MAIN_NS}, 
               {label:USER_NSSTR, ns:USER_NS},
               {label:PLACE_NSSTR, ns:PLACE_NS}, 
               {label:GIVENNAME_NSSTR, ns:GIVENNAME_NS},
               {label:SURNAME_NSSTR, ns:SURNAME_NS}, 
               {label:CATEGORY_NSSTR, ns:CATEGORY_NS},
               {label:HELP_NSSTR, ns:HELP_NS},
               {label:PROJECT_NSSTR, ns:PROJECT_NS},
               {label:SPECIAL_NSSTR, ns:SPECIAL_NS},
					{label:PERSON_TALK_NSSTR, ns:PERSON_TALK_NS}, 
               {label:FAMILY_TALK_NSSTR, ns:FAMILY_TALK_NS}, 
               {label:SOURCE_TALK_NSSTR, ns:SOURCE_TALK_NS},
               {label:MYSOURCE_TALK_NSSTR, ns:MYSOURCE_TALK_NS}, 
               {label:IMAGE_TALK_NSSTR, ns:IMAGE_TALK_NS},
					{label:MAIN_TALK_NSSTR, ns:MAIN_TALK_NS}, 
               {label:USER_TALK_NSSTR, ns:USER_TALK_NS},
               {label:PLACE_TALK_NSSTR, ns:PLACE_TALK_NS}, 
               {label:GIVENNAME_TALK_NSSTR, ns:GIVENNAME_TALK_NS},
               {label:SURNAME_TALK_NSSTR, ns:SURNAME_TALK_NS}, 
               {label:CATEGORY_TALK_NSSTR, ns:CATEGORY_TALK_NS},
               {label:HELP_TALK_NSSTR, ns:HELP_TALK_NS},
               {label:PROJECT_TALK_NSSTR, ns:PROJECT_TALK_NS}
               ];
		[Bindable]
		public var gotoNamespaces:Array = [ 
					{label:PERSON_NSSTR, ns:PERSON_NS}, 
               {label:FAMILY_NSSTR, ns:FAMILY_NS}, 
               {label:IMAGE_NSSTR, ns:IMAGE_NS},
               {label:SOURCE_NSSTR, ns:SOURCE_NS},
               {label:MYSOURCE_NSSTR, ns:MYSOURCE_NS}, 
					{label:"(article)", ns:MAIN_NS}, 
               {label:USER_NSSTR, ns:USER_NS},
               {label:PLACE_NSSTR, ns:PLACE_NS}, 
               {label:GIVENNAME_NSSTR, ns:GIVENNAME_NS},
               {label:SURNAME_NSSTR, ns:SURNAME_NS}, 
               {label:CATEGORY_NSSTR, ns:CATEGORY_NS},
               {label:HELP_NSSTR, ns:HELP_NS},
               {label:PROJECT_NSSTR, ns:PROJECT_NS},
               {label:SPECIAL_NSSTR, ns:SPECIAL_NS} 
               ];
      [Bindable]
		public var selectableNamespaces:Array = 
			[PERSON_NS, FAMILY_NS, SOURCE_NS, MYSOURCE_NS, IMAGE_NS, MAIN_NS, USER_NS, GIVENNAME_NS, SURNAME_NS, PLACE_NS,
			 PERSON_TALK_NS, FAMILY_TALK_NS, SOURCE_TALK_NS, MYSOURCE_TALK_NS, IMAGE_TALK_NS, MAIN_TALK_NS, USER_TALK_NS, GIVENNAME_TALK_NS, SURNAME_TALK_NS, PLACE_TALK_NS
			];
		[Bindable]
		public var indexNamespaces:Array = [ 
					{label:"All pages", ns:-1},
					{label:"People", ns:PERSON_NS}, 
               {label:"Families", ns:FAMILY_NS}, 
               {label:"Images", ns:IMAGE_NS},
               {label:"Sources", ns:SOURCE_NS},
               {label:"MySources", ns:MYSOURCE_NS},
               {label:"Places", ns:PLACE_NS},
               {label:"Given names", ns:GIVENNAME_NS},
               {label:"Surnames", ns:SURNAME_NS},
               {label:"Articles", ns:MAIN_NS},
               {label:"User pages", ns:USER_NS}
               ];
						            
		[Bindable]
		public var status:Status;
		[Bindable]
		public var mainMenu:MainMenu;
		[Bindable]
		public var pages:Pages;
		[Bindable]
		public var contentURL:String;
		public var suspendViewUpdate:Boolean;
		public var alertErrors:Boolean;
		private var _defaultUserName:String;
		private var _userName:String;
		private var _treeName:String;
		private var _selectedPage:Page;
		private var _selectedTab:int;
		// used in Tree and hourglass views
		private var _primaryPage:Page;
		// used in Index view
		private var _selectedNamespace:int;
		private var _findText:String;
		private var _findTokens:Array;
		// used in hourglass view
		private var _hgAncGenerations:int;
		private var _hgDescGenerations:int;
		private var _hgTreeDirection:int;
		private var _hgFontSize:int;
		// changed pages view
//		public var selectedChangedPages:Array;

		public function Model()
		{
		   _instance = this;
		   suspendViewUpdate = false;
		   alertErrors = true;
		   _defaultUserName = null;
		   _userName = null;
		   contentURL = null;
		   pages = new Pages();
		   status = new Status();
		   mainMenu = new MainMenu();
			_hgAncGenerations = 3;
			_hgDescGenerations = 1;
			_hgTreeDirection = 0;
			_hgFontSize = 16;
		   clearTree();
//			HistoryManager.register(this);
		   dispatchEvent(new Event("instanceChanged"));
		   dispatchEvent(new Event("defaultUserNameChanged"));
		   dispatchEvent(new Event("userNameChanged"));
			dispatchEvent(new Event("hgAncGenerationsChanged"));
			dispatchEvent(new Event("hgDescGenerationsChanged"));
			dispatchEvent(new Event("hgTreeDirectionChanged"));
			dispatchEvent(new Event("hgFontSizeChanged"));
		}
		
		public function init():void {
//			logger.info("host="+Application.application.parameters.host);
			if (Application.application.parameters.host.length > 0) {
				WR_HOST = "http://" + Application.application.parameters.host;
			}
			else {
				WR_HOST = 'http://www.werelate.org';
			}
			WR_INDEX_URL = WR_HOST + "/w/index.php";
			WR_WIKI_PATH = WR_HOST + "/wiki/";
			WR_HOMEPAGE = WR_HOST + "/wiki/WeRelate:Family Tree Explorer";
		}
		
		public function clearTree():void {
		   treeName = null;
		   userName = null;
			pages.clearAll();
			selectedPage = null;
			primaryPage = null;
			selectedTab = HOURGLASS_TAB;
			selectedNamespace = -1;
			findText = "";
//		   selectedChangedPages = new Array();
		}
		
		[Bindable("instanceChanged")]
		public static function get instance():Model
		{
		    return _instance;
		}
			
//		public function saveState():Object {
//		}
		
//		public function loadState(state:Object):void {
//		}

		private function getSettingsKey(userName:String, treeName:String):String {
			return CacheManager.getCacheKey("settings-" + userName + "-" + treeName);
		}
		
		private function getPrimaryFromTitle(title:String):Page {
			var page:Page = pages.getPage(Utils.getNsFromTitleNs(title), Utils.getTitleFromTitleNs(title));
			if (page.ns == Model.PERSON_NS || page.ns == Model.FAMILY_NS) {
				return page;
			}
			return null;
		}
		
		public function loadSettings(defaultPageTitle:String, primaryPageTitle:String):void {
			if (userName != null && treeName != null) {
				_selectedPage = null;
				primaryPage = null;
				
				var settingsPrimaryPage:Page = null;
				var so:SharedObject = SharedObject.getLocal(getSettingsKey(this.userName, this.treeName), "/");
				if (so.data.savedSettings == "true") {
//					if (so.data.selectedPageTitle != null && so.data.selectedPageNs != null) {
//						var page:Page = pages.getPage(so.data.selectedPageNs, so.data.selectedPageTitle);
//						if (page.isInTree) {
//							_selectedPage = page;
//							dispatchEvent(new Event("selectedPageChanged"));
//						}
//					}
					if (so.data.primaryPageTitle != null) {
						if (so.data.primaryPageNs == null) {
							so.data.primaryPageNs = Model.PERSON_NS;
						}
						var page:Page = pages.getPage(so.data.primaryPageNs, so.data.primaryPageTitle);
						if (page.isInTree) {
							settingsPrimaryPage = page;
						}
					}
					if (so.data.hgAncGenerations != null) {
//logger.warn("load hgAncGenerations=" + _hgAncGenerations);
						_hgAncGenerations = so.data.hgAncGenerations;
					}
					if (so.data.hgDescGenerations != null) {
						_hgDescGenerations = so.data.hgDescGenerations;
//logger.warn("load hgDescGenerations=" + _hgDescGenerations);
					}
					if (so.data.hgTreeDirection != null) {
						_hgTreeDirection = so.data.hgTreeDirection;
					}
					if (so.data.hgFontSize != null) {
						_hgFontSize = so.data.hgFontSize;
					}
					dispatchEvent(new Event("hgAncGenerationsChanged"));
					dispatchEvent(new Event("hgDescGenerationsChanged"));
					dispatchEvent(new Event("hgTreeDirectionChanged"));
					dispatchEvent(new Event("hgFontSizeChanged"));
				}
				
				// the priority is default, primary, in settings
				if (defaultPageTitle != null && defaultPageTitle.length > 0) {
					primaryPage = getPrimaryFromTitle(defaultPageTitle);
				}
				if (primaryPage == null && primaryPageTitle != null && primaryPageTitle.length > 0) {
					primaryPage = getPrimaryFromTitle(primaryPageTitle);
				}
				if (primaryPage == null && settingsPrimaryPage != null) {
					primaryPage = settingsPrimaryPage;
				}
//				if (primaryPage == null) {
//					primaryPage = getPrimaryPageCandidate();
//				}
				// default selected page to primary page if not set from settings
				if (_selectedPage == null && primaryPage != null) {
					selectedPage = primaryPage;
				}
			}
		}
		
		public function copySettings(newUserName:String, newTreeName:String):void {
			var so:SharedObject = SharedObject.getLocal(getSettingsKey(this.userName, this.treeName), "/");
			if (so.data.savedSettings == "true") {
				saveSettings(newUserName, newTreeName);
			}
			savePrimaryPage(newUserName, newTreeName);
		}
		
		private function saveSettings(userName:String = null, treeName:String = null):void {
			if (userName == null) {
				userName = this.userName;
			}
			if (treeName == null) {
				treeName = this.treeName;
			}
			if (userName != null && treeName != null) {
				var so:SharedObject = SharedObject.getLocal(getSettingsKey(userName, treeName), "/");
				so.data.savedSettings = "true";
//				if (selectedPage != null) {
//					so.data.selectedPageTitle = selectedPage.title;
//					so.data.selectedPageNs = selectedPage.ns;
//				}
				if (primaryPage != null) {
					so.data.primaryPageTitle = primaryPage.title;
					so.data.primaryPageNs = primaryPage.ns;
				}
				so.data.hgAncGenerations = hgAncGenerations;
//logger.warn("save hgAncGenerations=" + hgAncGenerations);
				so.data.hgDescGenerations = hgDescGenerations;
//logger.warn("save hgDescGenerations=" + hgDescGenerations);
				so.data.hgTreeDirection = hgTreeDirection;
				so.data.hgFontSize = hgFontSize;
				so.flush();
			}
		}
		
		private function savePrimaryPage(userName:String = null, treeName:String = null):void {
			if (userName == null) {
				userName = this.userName;
			}
			if (treeName == null) {
				treeName = this.treeName;
			}
			if (userName != null && treeName != null && primaryPage != null && primaryPage.title.length > 0) {
				WRServices.instance.savePrimaryPage(userName, treeName, 
																Utils.getMainNs(primaryPage.ns), primaryPage.title, 
																savePrimaryPageResultHandler);
			}
		}
		
		private function savePrimaryPageResultHandler(event:ResultEvent):void {
//			logger.debug("SavePrimaryPage result " + event.result.toString());
			var status:int = event.result.@status;
			if (status != WRServices.STATUS_OK) {
				WRServices.instance.handleError(status);
			}
		}
		
		public function getPrimaryPageCandidate():Page {
			for each (var page:Page in pages.allPages) {
				if (page.isInTree && page.isBookmarked) {
					return page;
					break;
				}
			}
//			for each (page in pages.allPages) {
//				if (page.isInTree && mainMenu.getMakePrimaryEnabled(page)) {
//					return page;
//					break;
//				}
//			}
			return null;
		}
		
		public function getContentPage():Page {
			if (Utils.isWeRelatePage(contentURL)) {
				var titleNs:String = Utils.getTitleNsFromUrl(contentURL);
				var title:String = Utils.getTitleFromTitleNs(titleNs);
				var ns:int = Utils.getNsFromTitleNs(titleNs);
				return pages.getPage(ns, title);
			}
			return null;
		}
		
		public function selectContentPage():void {
			if (treeName == null || !Utils.isSelectable(contentURL)) {
				_selectedPage = null;
				dispatchEvent(new Event("selectedPageChanged"));
			} 
			else {
				var page:Page = getContentPage();
				selectedPage = page;
			}
		}
		
		[Bindable("defaultUserNameChanged")]
		public function get defaultUserName():String {
			return _defaultUserName;
		}
		
		public function set defaultUserName(userName:String):void {
			_defaultUserName = userName;
//logger.warn("set defaultUserName=" + userName);
			dispatchEvent(new Event("defaultUserNameChanged"));
			status.setMessage("defaultuser", "User: " + (userName == null ? "(Not logged in)" : userName));
		}
		
		[Bindable("userNameChanged")]
		public function get userName():String {
			return _userName;
		}
		
		public function set userName(userName:String):void {
			_userName = userName;
			dispatchEvent(new Event("userNameChanged"));
//			status.setMessage("user", "User: " + (userName == null ? "(Not logged in)" : userName));
		}
		
		[Bindable("treeNameChanged")]
		public function get treeName():String {
			return _treeName;
		}

		public function set treeName(treeName:String):void {
			_treeName = treeName;
			dispatchEvent(new Event("treeNameChanged"));
			status.setMessage("tree", (treeName == null ? "" : "User: " + userName + " Tree: " + treeName));
		}
		
		[Bindable("selectedTabChanged")]
		public function get selectedTab():int {
			return _selectedTab;
		}
		
		public function set selectedTab(tab:int):void {
			if ((tab == HOURGLASS_TAB || tab == ANCESTORS_TAB || tab == DESCENDANTS_TAB) &&
				 Model.instance.primaryPage == null && Model.instance.pages.indexPages.length > 0) {
				Alert.show("Please select a Person or Family to be the \"root\"\n"+
							  "of the tree. Do this by returning to the index view and\n"+
							  "right-clicking on the Person or Family you want\n"+
							  "and selecting 'Make Primary'.",
							  "Select the Primary Person or Family");
			}
			_selectedTab = tab;
			dispatchEvent(new Event("selectedTabChanged"));
		}

		[Bindable("selectedPageChanged")]
		public function get selectedPage():Page {
			return _selectedPage;
		}
		
		public function set selectedPage(page:Page):void {
			if (page != _selectedPage) {
				_selectedPage = page;
				pages.makeSelected(_selectedPage);
				dispatchEvent(new Event("selectedPageChanged"));
				if (primaryPage == null) {
					primaryPage = page;
				}
//				saveSettings();
			}
		}
		
		[Bindable("primaryPageChanged")]
		public function get primaryPage():Page {
			return _primaryPage;
		}		
		
		public function set primaryPage(page:Page):void {
			if (treeName == null || page == null) {
				_primaryPage = null;
			} 
			else if (mainMenu.getMakePrimaryEnabled(page)) {
				_primaryPage = page;
				saveSettings();
				savePrimaryPage();
				if (selectedPage == null) {
					selectedPage = page;
				}
			}
			dispatchEvent(new Event("primaryPageChanged"));
			// notify primary page changed before updating pages
			pages.makePrimary(_primaryPage);
		}
		
		[Bindable("selectedNamespaceChanged")]
		public function get selectedNamespace():int {
			return _selectedNamespace;
		}
		
		// ns is -1 to select all namespaces
		public function set selectedNamespace(ns:int):void {
			_selectedNamespace = ns;
			pages.computeIndexPages(true);
			dispatchEvent(new Event("selectedNamespaceChanged"));
		}
		
		[Bindable("findTextChanged")]
		public function get findText():String {
			return _findText;
		}
		
		public function set findText(text:String):void {
			text = StringUtil.trim(text.replace(/"/g, ""));
			_findText = text;
			if (text.length == 0) {
				_findTokens = new Array();
			}
			else {
				var romanizedText:String = StringUtils.romanize(text.toLowerCase());
//				logger.info("findText " + romanizedText);
				_findTokens = romanizedText.split(/\s+/);
			}
			pages.computeIndexPages(false);
			dispatchEvent(new Event("findTextChanged"));
		}
		
		public function get findTokens():Array {
			return _findTokens;
		}
		
		[Bindable("hgAncGenerationsChanged")]
		public function get hgAncGenerations():int {
			return _hgAncGenerations;
		}
		
		public function set hgAncGenerations(gen:int):void {
			_hgAncGenerations = gen;
			dispatchEvent(new Event("hgAncGenerationsChanged"));
			// notify generations changed before updating pages
//logger.warn("hgAncGenerations compute");
			pages.computeHourglassPages(true);
			saveSettings();
		}

		[Bindable("hgDescGenerationsChanged")]
		public function get hgDescGenerations():int {
			return _hgDescGenerations;
		}
		
		public function set hgDescGenerations(gen:int):void {
			_hgDescGenerations = gen;
			dispatchEvent(new Event("hgDescGenerationsChanged"));
			// notify generations changed before updating pages
//logger.warn("hgDescGenerations compute");
			pages.computeHourglassPages(true);
			saveSettings();
		}

		[Bindable("hgTreeDirectionChanged")]
		public function get hgTreeDirection():int {
			return _hgTreeDirection;
		}
		
		public function set hgTreeDirection(dir:int):void {
			_hgTreeDirection = dir;
			dispatchEvent(new Event("hgTreeDirectionChanged"));
			saveSettings();
		}

		[Bindable("hgFontSizeChanged")]
		public function get hgFontSize():int {
			return _hgFontSize;
		}
		
		public function set hgFontSize(size:int):void {
			_hgFontSize = size;
			dispatchEvent(new Event("hgFontSizeChanged"));
			saveSettings();
		}

	}
}