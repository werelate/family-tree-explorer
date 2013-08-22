package org.werelate.fte.service
{
	import mx.rpc.http.HTTPService;
	import mx.rpc.IResponder;
	import mx.rpc.events.FaultEvent;
	import org.werelate.fte.model.Model;
	import mx.rpc.events.ResultEvent;
	
	public class Service
	{
		private var url:String;
		private var params:Object;
		private var faultHandler:Function;
		private var resultHandler:Function;
		private var isGet:Boolean;
		
		public function Service(url:String, params:Object, faultHandler:Function, 
										resultHandler:Function, isGet:Boolean = true) {
			this.url = url;
			this.params = params;
			this.faultHandler = faultHandler;
			this.resultHandler = resultHandler;
			this.isGet = isGet;
		}
		
		public function asyncExecute(statusMessage:String = null):void {
			var httpService:HTTPService = new HTTPService();
			httpService.url = url;
			httpService.request = params;
			httpService.resultFormat = "e4x";
			if (!isGet) {
				httpService.method = "POST";
			}
			httpService.addEventListener("fault", myFaultHandler);
			httpService.addEventListener("result", myResultHandler);
			if (statusMessage != null) {
				Model.instance.status.setMessage("service", statusMessage);
			}
			httpService.send();
		}
		
		public function syncExecute():void {
			var ms:ModalService = new ModalService(url, params, faultHandler, resultHandler, isGet);
			ms.send();
		}
		
		private function myFaultHandler(event:FaultEvent):void {
			Model.instance.status.setMessage("service", "");
			faultHandler(event);
		}
		
		private function myResultHandler(event:ResultEvent):void {
			Model.instance.status.setMessage("service", "");
			resultHandler(event);
		}
	}
}