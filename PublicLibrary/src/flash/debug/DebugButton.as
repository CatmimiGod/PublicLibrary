package flash.debug
{
	import flash.display.Shape;
	import flash.display.SimpleButton;
	
	/**
	 *	隐藏的按扭，用代码写的，可不用Flash绘制按扭
	 * @author Administrator
	 */	
	public final class DebugButton extends SimpleButton
	{
		public function DebugButton(width:Number, height:Number, debug:Boolean = false)
		{
			super(getShape(width, height), getShape(width, height), getShape(width, height), getShape(width, height));
			if(!debug)
				this.alpha = 0;
		}
		
		/**
		 *	获取显示对象 
		 * @param width
		 * @param height
		 * @param color
		 * @return 
		 * 
		 */		
		protected static function getShape(width:Number, height:Number, color:uint = 0x00):Shape
		{
			var s:Shape = new Shape();
			s.graphics.beginFill(color == 0x00 ? Math.random() * 0xFFFFFF : color, .3);
			s.graphics.drawRect(0, 0, width, height);
			s.graphics.endFill();
			
			return s;
		}
	}
}