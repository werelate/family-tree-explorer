package org.werelate.fte.command
{
	import flash.events.Event;
	import mx.rpc.events.ResultEvent;
	import mx.containers.TitleWindow;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.managers.PopUpManager;
	import mx.core.Application;

	import org.werelate.fte.service.WRServices;
	import org.werelate.fte.view.CreateFamilyTreeView;
	import org.werelate.fte.view.CreateEvent;
	import flash.display.DisplayObject;
	import org.werelate.fte.model.Model;
	import mx.controls.Alert;
	import org.werelate.fte.view.AddAncestorsView;
	import org.werelate.fte.view.AddAncestorsEvent;
	import org.werelate.fte.view.ImportGedcomView;
	import org.werelate.fte.model.Page;
	import org.werelate.fte.util.StringUtils;

	public class CreateFamilyTree implements Command
	{
		private static const logger:ILogger = Log.getLogger("CreateFamilyTree");
		public static const MAX_ANCESTORS:int = 14;
		
		private var popup:TitleWindow;
		private var userName:String;
		private var fileName:String;
		private var pageTitle:String;
		private var parentsTitle:String;
		private var frameStack:Array;
		private var people:Array;
		
		public function execute():void {
			Controller.instance.setDefaultUserName();
			if (Model.instance.defaultUserName != null) {
				// pop up dialog to get tree name
				popup = new CreateFamilyTreeView();
				popup.addEventListener("close", handleClose);
				popup.addEventListener("create", handleCreate);
				PopUpManager.addPopUp(popup, DisplayObject(Application.application), true);
				PopUpManager.centerPopUp(popup);
			}
			else {
				WRServices.instance.handleError(WRServices.STATUS_NOT_LOGGED_IN, "create a new tree");
			}
		}
		
		private function handleClose(event:Event):void {
//			logger.debug("close " + event.toString());
			PopUpManager.removePopUp(popup);
		}
		
		private function handleCreate(event:CreateEvent):void {
			this.userName = Model.instance.defaultUserName;
			this.fileName = event.fileName;
//			logger.debug("create " + event.fileName);
			handleClose(event);
			WRServices.instance.createFamilyTree(userName, event.fileName, handleResult);
		}
		
		private function handleResult(event:ResultEvent):void {
//			logger.debug("handleResult " + fileName + ":" + event.result.toString());
			var status:int = event.result.@status;
			if (status != WRServices.STATUS_OK) {
				WRServices.instance.handleError(status);
			}
			else {
				Controller.instance.doFileClose();
				Controller.instance.loadContent(Model.WR_HOMEPAGE);
				Model.instance.userName = userName;
				Model.instance.treeName = fileName;
				Model.instance.selectContentPage();
				Model.instance.mainMenu.resetEnabled();
				Controller.instance.saveDefaultTreeName(userName, fileName);
				Controller.instance.cacheManager.openTreeCache(userName, fileName);

				handleEmptyTree();
			}
		}
		
		public function handleEmptyTree():void {
			// do they want to import a GEDCOM?				
			popup = new ImportGedcomView();
			popup.addEventListener("close", handleClose);
			popup.addEventListener("yes", handleImportYes);
			popup.addEventListener("no", handleImportNo);
			PopUpManager.addPopUp(popup, DisplayObject(Application.application), true);
			PopUpManager.centerPopUp(popup);
		}
		
		private function handleImportYes(event:Event):void {
			handleClose(event);
			Controller.instance.fileImport();
			Alert.show("Import your GEDCOM file using the form at the right", "Import GEDCOM");
		}

		private function handleImportNo(event:Event):void {
			handleClose(event);
         Alert.show("To add pages for your deceased relatives to your tree, select Family from the Add menu to the right", "Add People");
//			popup = new AddAncestorsView();
//			popup.addEventListener("close", handleClose);
//			popup.addEventListener("addAncestors", handleAddAncestors);
//			PopUpManager.addPopUp(popup, DisplayObject(Application.application), true);
//			PopUpManager.centerPopUp(popup);
		}
		
		private function handleAddAncestors(event:AddAncestorsEvent):void {
			handleClose(event);
			people = event.people;
			frameStack = new Array();
			frameStack.push({pf:"f", ix:1, state:0});
			addNextPage();
		}
		
		private function addNextPage():void {
			var waiting:Boolean = false;
			while (!waiting) {
				if (frameStack.length == 0) {
					// all pages added
					if (pageTitle != null) {
						bookmark(Model.FAMILY_NS, pageTitle);
					}
					Model.instance.primaryPage = Model.instance.getPrimaryPageCandidate();
					Alert.show("To add more information about a person or family, "+
						"click on one of the boxes on the left to navigate to their page, "+
						"then click on the 'Edit' button at the top of their page on the right.",
						"Pages have been created");
					break;
				}
				var frame:Object = frameStack.pop();
				if (frame.pf == "p") {
					waiting = addPerson(frame);
				}
				else {
					waiting = addFamily(frame);
				}
			}
		}
		
		// add a family page and set familyTitle
		private function addFamily(frame:Object):Boolean {
			if (frame.state == 0) {
				frameStack.push({pf:"f", ix:frame.ix, state:1});
				return addPerson({ix:frame.ix, state:0});
			}
			if (frame.state == 1) {
				frameStack.push({pf:"f", ix:frame.ix, state:2, husbandTitle:pageTitle, husbandParentsTitle:parentsTitle});
				return addPerson({ix:frame.ix+1, state:0});
			}
			if (frame.state == 2) {
				var wifeTitle:String = pageTitle;
				var wifeParentsTitle:String = parentsTitle;
				if (frame.husbandTitle != null || wifeTitle != null) {
					var familyTitle:String = 
						constructTitle(people[frame.ix].given, people[frame.ix].surname) + " and " +
						constructTitle(people[frame.ix+1].given, people[frame.ix+1].surname);
					var content:String = "<family>\n" + 
							formatFamilyMember(frame.husbandTitle, frame.husbandParentsTitle, people[frame.ix], "husband") + 
							formatFamilyMember(wifeTitle, wifeParentsTitle, people[frame.ix+1], "wife") +
							"</family>\n";
					addPage(Model.FAMILY_NS, familyTitle, content);
					return true;
				}
				else {
					pageTitle = null;
					return false;
				}
			}
			return false;
		}
		
		private function formatFamilyMember(title:String, parentFamilyTitle:String, person:Object, label:String):String {
			if (title == null) {
				return "";
			}
			return "<" + label + " title=\"" + StringUtils.escapeXml(title) + "\"" + 
				(person.given == null ? "" : " given=\"" + StringUtils.escapeXml(person.given) + "\"") + 
				(person.surname == null ? "" : " surname=\"" + StringUtils.escapeXml(person.surname) + "\"") + 
				(parentFamilyTitle == null ? "" : " child_of_family=\"" + StringUtils.escapeXml(parentFamilyTitle) + "\"") + 
				"/>\n";
		}

		// add a person page and set personTitle and parentsTitle
		// also, bookmark parent family if parent family added but person not added
		private function addPerson(frame:Object):Boolean {
			if (frame.state == 0) {
				frameStack.push({pf:"p", ix:frame.ix, state:1});
				if (frame.ix*2+1 < MAX_ANCESTORS) {
					return addFamily({ix:frame.ix*2+1, state:0});
				}
				else {
					pageTitle = null;
					return false;
				}
			}
			if (frame.state == 1) {
				parentsTitle = pageTitle;
				if (people[frame.ix].given != null || people[frame.ix].surname != null) {
					var content:String = "<person>\n" +
						"<name" + (people[frame.ix].given == null ? "" : " given=\"" + StringUtils.escapeXml(people[frame.ix].given) + "\"") +
									  (people[frame.ix].surname == null ? "" : " surname=\"" + StringUtils.escapeXml(people[frame.ix].surname) + "\"") +
						"/>\n" +
						"<gender>" + (frame.ix % 2 == 0 ? "F" : "M") + "</gender>\n" +
						(parentsTitle == null ? "" : "<child_of_family title=\"" + StringUtils.escapeXml(parentsTitle) + "\"/>\n") +
						"</person>\n";
					addPage(Model.PERSON_NS, constructTitle(people[frame.ix].given, people[frame.ix].surname), content);
					return true;
				}
				else {
					if (parentsTitle != null) {
						bookmark(Model.FAMILY_NS, parentsTitle);
					}
					pageTitle = null;
					return false;
				}
			}
			return false;
		}
		
		private function constructTitle(given:String, surname:String):String {
			if (given != null) {
				var pos:int = given.indexOf(" ");
				if (pos >= 0) {
					given = given.substr(0, pos);
				}
			}
			if (given == null && surname == null) {
				return "Unknown";
			}
			else {
				return (given == null ? "Unknown" : StringUtils.toMixedCase(given)) + " " +
				       (surname == null ? "Unknown" : StringUtils.toMixedCase(surname));
			}
		}
		
		private function addPage(ns:int, title:String, content:String):void {
//			logger.debug("addPage " + title);
			WRServices.instance.createFamilyTreePage(ns, title, content, handleAddPageResult);
		}

		private function handleAddPageResult(event:ResultEvent):void {
//			logger.debug("handleAddPageResult " + event.result.toString());
			var status:int = event.result.@status;
			if (status != WRServices.STATUS_OK) {
				pageTitle = null;
				WRServices.instance.handleError(status);
			}
			else {
				pageTitle = event.result.@title;
				var page:Page = Model.instance.pages.getPage(event.result.@ns, event.result.@title);
				page.init(event.result.@latest, event.result.@latest, 0, "", "", "", 0, true); 
			}
			addNextPage();
		}
		
		private function bookmark(ns:int, title:String):void {
			var page:Page = Model.instance.pages.getPage(ns, title);
			Controller.instance.addBookmark(page);
		}
	}
}