package org.werelate.fte.view
{
	import mx.controls.Button;
	import mx.containers.Canvas;
	import flash.events.MouseEvent;
	import flash.events.EventDispatcher;
	import mx.controls.Text;
	import mx.controls.LinkButton;
import mx.effects.IEffectInstance;
import mx.logging.ILogger;
	import mx.logging.Log;
	import flash.events.Event;

	import org.werelate.fte.model.Page;
	import org.werelate.fte.model.Model;
	import org.werelate.fte.model.PersonPage;
	import mx.controls.ToolTip;
	import mx.effects.easing.Back;
	import mx.core.Application;
	import mx.effects.EffectInstance;

	public class HourglassButton extends Canvas
	{
		private static const logger:ILogger = Log.getLogger("HourglassButton");

		public static const MALE_COLOR:int = 0xCAD2FF;
		public static const FEMALE_COLOR:int = 0xFFDDDD;
		public static const UNKNOWN_COLOR:int = 0xCCCCCC;
		public static const FAMILY_COLOR:int = 0xDDFFDD;
		public static const OVER_COLOR:int = 0xF6F6F6;
		public static const DOWN_COLOR:int = 0xFFFFFF;
		public static const BORDER_COLOR:int = 0xAAAAAA; // 0xAAB3B3;
		public static const TEXT_COLOR:int = 0x000000;
		public static const INDENT_FACTOR:Number = 0.5;
		public static const PRIMARY_THICKNESS:int = 1;
//		public static const PRIMARY_COLOR:int = 0x404040;
		public static const SELECTED_THICKNESS:int = 2;
		public static const SELECTED_BORDER_COLOR:int = 0x404040;
//		public static const SELECTED_COLOR:int = 0x7FCEFF;
		
		private var xPct:Number;
		private var yPct:Number;
		public var widthPct:Number;
		private var heightPct:Number;
		public var xIndent:int;
		private var yIndent:int;
		private var text:Text;
//		private var toolTip:ToolTip;
		private var _page:Page;
		private var _isPrimary:Boolean;
		private var _isSelected:Boolean;
		private var _baseFontSize:int;
		private var _fontSizeDelta:int;
		private var _radius:int;
		private var _numEffects:int;
		
		public function HourglassButton(page:Page, x:Number, y:Number, width:Number, height:Number, 
													fontSizeDelta:int, xIndent:int, yIndent:int, radius:int) {
			super();
			this.xPct = x;
			this.yPct = y;
			this.widthPct = width;
			this.heightPct = height;
			this.xIndent = xIndent;
			this.yIndent = yIndent;
			this._page = page;
			this._isPrimary = false;
			this._isSelected = false;
			this._baseFontSize = 0;
			this._fontSizeDelta = fontSizeDelta;
			this._radius = radius;
			this.buttonMode = true;
			this.mouseChildren = false;
			this._numEffects = 0;

			this.text = new Text();
			this.text.text = page.tip;
			_page.addEventListener("tipChanged", updatePageHandler);
			_page.addEventListener("titleChanged", updatePageHandler);
			_page.addEventListener("summaryChanged", updatePageHandler);
			_page.addEventListener("isInTreeChanged", updateBackgroundHandler);
			_page.addEventListener("genderChanged", updateBackgroundHandler);
			this.text.setStyle('verticalCenter', 0);
			this.text.setStyle('textAlign', 'center');
			this.text.setStyle('color', TEXT_COLOR);
//			this.setStyle('borderStyle', 'solid');
//			this.setStyle('backgroundColor', defaultColor);
			this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			this.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			this.addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
			this.addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
			this.addChild(this.text);
		
			this.toolTip = page.summary;
		}
		
		public function get fontSizeDelta():int {
			return this._fontSizeDelta;
		}
		
		public function set fontSizeDelta(fontSizeDelta:int):void {
			this._fontSizeDelta = fontSizeDelta;
			text.setStyle('fontSize', this._baseFontSize + this._fontSizeDelta);
		}
		
		public function get baseFontSize():int {
			return this._baseFontSize;
		}
		
		public function set baseFontSize(baseFontSize:int):void {
			this._baseFontSize = baseFontSize;
			text.setStyle('fontSize', this._baseFontSize + this._fontSizeDelta);
		}
		
		public function get page():Page {
			return _page;
		}

		private function updatePageHandler(event:Event):void {		
			this.text.text = _page.tip;
			this.toolTip = _page.summary;
		}
		
		private function updateBackgroundHandler(event:Event):void {		
			updateBackground(defaultColor);
		}
		
		private function mouseDown(event:MouseEvent):void {
			updateBackground(DOWN_COLOR);
//			this.setStyle('backgroundColor', DOWN_COLOR);
		}
		
		private function mouseUp(event:MouseEvent):void {
			updateBackground(OVER_COLOR);
//			this.setStyle('backgroundColor', OVER_COLOR);
			
		}
		
		private function mouseOver(event:MouseEvent):void {
			updateBackground(OVER_COLOR);
//			this.setStyle('backgroundColor', OVER_COLOR);
		}
		
		private function mouseOut(event:MouseEvent):void {
			updateBackground(defaultColor);
//			this.setStyle('backgroundColor', defaultColor);
		}
		
		public function get isPrimary():Boolean {
			return _isPrimary;
		}
		
		public function set isPrimary(isPrimary:Boolean):void {
			if (_isPrimary != isPrimary) {
				_isPrimary = isPrimary;
				updateBackground(defaultColor);
			}
		}
		
		public function get isSelected():Boolean {
			return _isSelected;
		}
		
		public function set isSelected(isSelected:Boolean):void {
			if (_isSelected != isSelected) {
				_isSelected = isSelected;
				updateBackground(defaultColor);
			}
		}
		
		override public function set width(width:Number):void {
//			eraseBackground();
			super.width = width;
			this.text.width = this.width - this.borderWidth * 2;
			this.text.maxWidth = this.width - this.borderWidth * 2;
			updateBackground(defaultColor);
		}
		
		override public function set height(height:Number):void {
//			eraseBackground();
			super.height = height;
			this.text.maxHeight = this.height - this.borderWidth * 2;
			updateBackground(defaultColor);
		}
		
		override public function set alpha(alpha:Number):void {
			super.alpha = alpha;
			if (this.text != null) {
				if (alpha < 0.75) {
					this.text.visible = false;
				}
				else {
					this.text.visible = true;
				}
			}
		}
		
		private function get defaultColor():int {
//			if (_isSelected) {
//				return DOWN_COLOR;
//			}
//			else 
			if (_page.isInTree) {
				if (_page.ns == Model.FAMILY_NS) {
					return FAMILY_COLOR;
				}
				else if (PersonPage(_page).gender == "M") {
					return MALE_COLOR;
				}
				else if (PersonPage(_page).gender == "F") {
					return FEMALE_COLOR;
				}
			}
			return UNKNOWN_COLOR;
		}
		
		public function update(canvas:Canvas, baseFontSize:int):void {
			updateSize(canvas, baseFontSize);
		}
		
		public function copySize(btn:HourglassButton):void {
			this.xPct = btn.xPct;
			this.yPct = btn.yPct;
			this.widthPct = btn.widthPct;
			this.heightPct = btn.heightPct;
			this.xIndent = btn.xIndent;
			this.yIndent = btn.yIndent;
			this._baseFontSize = btn._baseFontSize;
			this._radius = btn._radius;
		}
		
		private function updateSize(canvas:Canvas, baseFontSize:int):void {
//			eraseBackground();
			this.x = canvas.width * this.xPct + this.xIndent * INDENT_FACTOR;
			this.y = canvas.height * this.yPct + this.yIndent * INDENT_FACTOR;
			this.width = canvas.width * this.widthPct - this.xIndent * INDENT_FACTOR * 2;
			this.height = canvas.height * this.heightPct - this.yIndent * INDENT_FACTOR * 2;
			this.baseFontSize = baseFontSize;
			updateBackground(defaultColor);
		}
		
//		public function redraw():void {
//			updateBackground(defaultColor);
//		}
		
		public function get borderWidth():int {
			if (_isSelected) {
				return SELECTED_THICKNESS;
			}
			else if (_isPrimary) {
				return PRIMARY_THICKNESS;
			}
			else {
				return 1;
			}
		}
		
		public function get borderColor():int {
			if (_isSelected) {
				return SELECTED_BORDER_COLOR;
			}
			else if (_isPrimary) {
				return SELECTED_BORDER_COLOR;
			}
			else {
				return BORDER_COLOR;
			}
		}
		
//		private function eraseBackground():void {
//			this.graphics.clear();
//		}
		
		private function updateBackground(color:int):void {
			this.graphics.clear();
      	this.drawRoundRect(0, 0, this.width, this.height, this._radius, 
      								this.borderColor, 1.0, null, null, null, 
					      		{x: this.borderWidth, y: this.borderWidth, 
					      		 w: this.width - this.borderWidth * 2, h: this.height - this.borderWidth * 2, 
					      		 r: this._radius});
      	this.drawRoundRect(this.borderWidth, this.borderWidth, 
      							 this.width - this.borderWidth * 2, this.height - this.borderWidth * 2, 
      							 this._radius, color, 1.0);
		}
		
		// ??? Are these functions really needed?
		override public function effectStarted(effectInst:IEffectInstance):void {
			super.effectStarted(effectInst);
			_numEffects++;
		}
		
		override public function effectFinished(effectInst:IEffectInstance):void {
			super.effectFinished(effectInst);
			_numEffects--;
		}
		
		override public function endEffectsStarted():void {
			if (_numEffects > 0 && this.parent != null) {
				super.endEffectsStarted();
			}
		}
	}
}
