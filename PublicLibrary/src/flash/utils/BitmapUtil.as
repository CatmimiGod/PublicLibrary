package flash.utils
{
	import flash.display.BitmapData;
	import flash.display.IBitmapDrawable;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	/**
	 *	
	 *	@author Huangmin
	 *	@date	2013-5-2
	 */
	public class BitmapUtil
	{
	
		/**
		 * 	判断某一位置是否是完全透明 
		 * 	
		 * 	@param targetBmpd:BitmapData	位图数据
		 * 	@param point:Point
		 * 	
		 * 	@return Boolean
		 */                
		public static function isAlpha(targetBmpd:BitmapData, point:Point):Boolean
		{
			if(targetBmpd != null)
			{
				var color:uint = targetBmpd.getPixel32(point.x, point.y);
				//右移24位以取到透明通道的值
				var alpha:uint = color >> 24;
				
				return alpha != 0;
			}
			
			return false;
		}
		
		/**
		 * 	截取显示对象指定区域的图,返回BitmapData类型.
		 * 	@param source:IBitmapDrawable
		 * 	@param rectangle:Rectangel	需要截取的区域
		 * 
		 * 	@return BitmapData
		 */
		public static function getRectangelBitmapDate(source:IBitmapDrawable, rectangle:Rectangle):BitmapData
		{
			var bmpd:BitmapData = new BitmapData(rectangle.width, rectangle.height, true, 0x00000000);
			bmpd.draw(source, new Matrix(1, 0, 0, 1, -rectangle.x, -rectangle.y), null, null, new Rectangle(0, 0, rectangle.width, rectangle.height), true);
			bmpd.lock();
			
			return bmpd;
		}
		
	}
}