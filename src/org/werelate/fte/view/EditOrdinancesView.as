package org.werelate.fte.view
{
	import mx.containers.TitleWindow;
	import mx.collections.ArrayCollection;
	import mx.events.DataGridEvent;
	import mx.controls.TextInput;
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	public class EditOrdinancesView extends TitleWindow
	{
		private static const logger:ILogger = Log.getLogger("EditOrdinancesView");

		public function init(xml:XML):void {
			// override
		}

		protected function getSources(sources:XMLList):ArrayCollection {
			var result:ArrayCollection = new ArrayCollection();
			var i:int = 0;
			for each (var source:XML in sources) {
				result.addItem({title:source.@title, text:source.@text});
				i++;
			}
			while (i < 2) {
				result.addItem({title:"", text:""});
				i++;
			}
			return result;
		}
		
		private function empty(s:String):Boolean {
			return (s == null || s.length == 0);
		}
		
		protected function updateOrdinance(ordinance:XML, temple:Object, sources:ArrayCollection):void {
			ordinance.@temple = temple.code;
			if (empty(ordinance.@date)) delete ordinance.@date;
			if (empty(ordinance.@temple)) delete ordinance.@temple;
			if (empty(ordinance.@place)) delete ordinance.@place;
			if (empty(ordinance.@stat)) delete ordinance.@stat;
			if (empty(ordinance.@statdate)) delete ordinance.@statdate;
			delete ordinance.source_citation;
			for each (var source:Object in sources) {
				if (source.title || source.text) {
				   var sourceXML:XML = new XML("<source_citation/>");
				   if (!empty(source.title)) sourceXML.@title = source.title;
				   if (!empty(source.text)) sourceXML.@text = source.text;
				   ordinance.appendChild(sourceXML);
				}
			}
		}
		
		protected function updateSource(sources:ArrayCollection, event:DataGridEvent):void {
			var value:String = TextInput(event.currentTarget.itemEditorInstance).text;

	    	if (event.columnIndex == 0) {
	    		sources.getItemAt(event.rowIndex).title = value;
	    	}
	    	else {
	    		sources.getItemAt(event.rowIndex).text = value;
	    	}
		}

		protected function getTemplePlace(temple:Object):String {
			if (empty(temple.code)) {
				return "Select";
			}
			return temple.place;
		}
	}
}