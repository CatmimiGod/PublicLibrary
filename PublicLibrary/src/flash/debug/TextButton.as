package flash.debug
{
	import flash.display.Shape;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	/**
	 *	扁平化带文字的按扭 
	 * @author Administrator
	 */	
	public class TextButton extends SimpleButton
	{
		private var _upState:ButtonState;
		private var _downState:ButtonState;
		
		private var _label:String = "Label";
		private var _textFormat:TextFormat;
		
		/**
		 *	文本按扭 
		 * @param text
		 * @param color
		 */		
		public function TextButton(text:String = "Label", color:uint = 0x33CCFF)
		{
			_label = text;
			
			_upState = new ButtonState(_label, color, .8);
			_downState = new ButtonState(_label, color, .6);
			
			super(_upState, _upState, _downState, _upState);
		}
		
		/**
		 *	Label 
		 * @return 
		 */		
		public function get label():String{		return _label;		}
		public function set label(value:String):void
		{
			if(_label == value)	return;
			
			_label = value;
			_upState.label = _downState.label = _label;
		}
		
		/**
		 *	TextFormat 文本格式
		 * @return 
		 */	
		public function get textFormat():TextFormat{		return _textFormat;		}
		public function set textFormat(value:TextFormat):void
		{
			if(_textFormat == value)		return;
			
			_textFormat = value;
			_upState.textFormat = _downState.textFormat = _textFormat;
		}
	}
}


import flash.display.Shape;
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormat;

/**
 *	 Simple Button State Class
 * @author Administrator
 */
class ButtonState extends Sprite
{
	private var _label:String;
	private var _shape:Shape;
	private var _textFiled:TextField;
	private var _textFormat:TextFormat;
	
	private var _width:int = 150;
	private var _height:int = 60;
	
	//字体实际大小与字体高的比例
	private static const SCALE:Number = 0.689;
	
	/**
	 *	Simple Button State Class
	 * @param label
	 * @param color
	 * @param alpha
	 */	
	public function ButtonState(label:String = "Label", color:uint = 0x00FF00, alpha:Number = .5)
	{
		_label = label;
		
		_shape = new Shape();
		_shape.graphics.beginFill(color, alpha);
		_shape.graphics.drawRect(0, 0, _width, _height);
		_shape.graphics.endFill();
		this.addChild(_shape);
		
		_textFiled = new TextField();
		_textFiled.mouseEnabled = false;
		//_textFiled.border = true;
		_textFiled.multiline = false;
		_textFiled.width = _width - 1;
		_textFiled.height = _height * .5;
		_textFiled.y = height * 0.25 + 2;
		
		var tft:TextFormat = new TextFormat("微软雅黑", _textFiled.height * SCALE, 0x000000);
		tft.align = "center";
		_textFiled.defaultTextFormat = tft;
		_textFiled.setTextFormat(tft);
		
		_textFiled.text = _label;
		this.addChild(_textFiled);
	}
	
	/**
	 *	Label 
	 * @return 
	 */	
	public function get label():String{		return _label;		}
	public function set label(value:String):void
	{
		if(_label == value)	return;
		
		_label = value;
		_textFiled.text = _label;
	}
	
	/**
	 *	TextFormat 
	 * @return 
	 */	
	public function get textFormat():TextFormat{		return _textFormat;		}
	public function set textFormat(value:TextFormat):void
	{
		if(value == null)	return;
		
		_textFormat = value;
		var size:Number = Number(_textFormat.size);
		var height:Number = size / SCALE;
		
		height = height >= this.height ? this.height : height;
		
		_textFiled.y = (this.height - height) * 0.5 + 2;
		_textFiled.height = height;
		
		_textFiled.defaultTextFormat = _textFormat;
		_textFiled.setTextFormat(_textFormat);
	}
	
}