package org.werelate.fte.service
{
	import mx.rpc.http.HTTPService;
	import mx.core.Application;
	import mx.managers.PopUpManager;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.events.FaultEvent;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import org.werelate.fte.view.PleaseWait;
	import flash.net.URLLoader;
	import flash.net.URLVariables;
	import flash.net.URLRequest;
	import flash.net.URLLoaderDataFormat;
	import flash.events.ProgressEvent;
	import flash.events.IOErrorEvent;
	import flash.events.HTTPStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.FileReference;
	import flash.events.DataEvent;
	import mx.controls.Alert;
	import flash.net.URLRequestMethod;
	
	public class ModalService
	{
		private static const logger:ILogger = Log.getLogger("ModalService");

		private var cancelled:Boolean;
		private var loader:URLLoader;
		private var request:URLRequest;
		private var faultHandler:Function;
		private var resultHandler:Function;
		private var popup:PleaseWait;
		
		public function ModalService(url:String, params:Object, faultHandler:Function, 
												resultHandler:Function, isGet:Boolean = true) {
			cancelled = false;
			request = new URLRequest(url);
			var vars:URLVariables = new URLVariables();
			for (var key:String in params) {
				vars[key] = params[key];
			}
			request.data = vars;
			request.method = isGet ? URLRequestMethod.GET : URLRequestMethod.POST;
			
			this.faultHandler = faultHandler;
			this.resultHandler = resultHandler;

			// create the popup
			popup = new PleaseWait();
			// set the popup click handler to the cancel function
			popup.addEventListener("close", handleClose);
			// show the popup
			PopUpManager.addPopUp(popup, DisplayObject(Application.application), true);
			PopUpManager.centerPopUp(popup);
		}
		
		public function send():void {
			loader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.addEventListener(IOErrorEvent.IO_ERROR, handleFault);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleFault);
			loader.addEventListener(ProgressEvent.PROGRESS, handleProgress);
			loader.addEventListener(Event.COMPLETE, handleLoaderComplete);
			// send the service
			loader.load(request);
		}
		
//		public function uploadFile(fileReference:FileReference):void {
//			fileReference.addEventListener(IOErrorEvent.IO_ERROR, handleFault);
//			fileReference.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleFault);
//			fileReference.addEventListener(ProgressEvent.PROGRESS, handleProgress);
//			fileReference.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, handleUploadCompleteData);
//			fileReference.addEventListener(Event.COMPLETE, handleUploadComplete);
//			// upload the file
//			try
//			{
//				fileReference.upload(request);
//			}
//			catch (error:Error)
//			{
//				Alert.show("Unable to upload file");
//				handleClose(new Event("close"));
//			}
//		}
		
		private function handleClose(event:Event):void {
			cancelled = true;
			PopUpManager.removePopUp(popup);
//			logger.debug("close " + event.toString());
		}
		
		private function handleFault(event:Event):void {
			Alert.show("fault");
			if (!cancelled) {
//				logger.debug("fault " + event.toString());
				var faultEvent:FaultEvent = new FaultEvent(event.type, event.bubbles, event.cancelable);
				faultHandler(faultEvent);
				handleClose(new Event("close"));
			}
		}
		
		private function handleLoaderComplete(event:Event):void {
			if (!cancelled) {
//				logger.debug("handleLoaderComplete event=" + event.toString() + " data=" + loader.data);
				// make the URLLoader event look like an HTTPService event
				var resultEvent:ResultEvent = new ResultEvent(event.type, event.bubbles, event.cancelable, new XML(loader.data));
				resultHandler(resultEvent);
				handleClose(new Event("close"));
			}
		}

//		private function handleUploadComplete(event:Event):void {
//			if (!cancelled) {
//				logger.debug("handleUploadComplete");
//				handleClose(new Event("close"));
//			}
//		}		
		
//		private function handleUploadCompleteData(event:DataEvent):void {
//			// handleUploadComplete is called first, so don't check !cancelled (this shouldn't be called then anyway)
//			logger.("handleUploadCompleteData " + event.toString());
//			var resultEvent:ResultEvent = new ResultEvent(event.type, event.bubbles, event.cancelable, new XML(event.data));
//			resultHandler(resultEvent);
//		}
		
		private function handleProgress(event:ProgressEvent):void {
			if (!cancelled) {
				popup.setProgress(event.bytesLoaded, event.bytesTotal);
			}
		}
	}
}