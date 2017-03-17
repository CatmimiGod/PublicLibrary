package flash.utils
{
	/**
	 *	将一个基本数据类型转为另一个基本数据类型 
	 * @author Administrator
	 * 
	 */	
	public class Convert
	{
		
		/**
		 *	转为Boolean 
		 * @param value
		 * @return 
		 */		
		public static function toBoolean(value:Object):Boolean
		{
			var boo:Boolean = false;
			if(value is String)
			{
				
			}
			
			return boo;
		}
		
		public static function toNumber(value:Object):Number
		{
			return 0.0;
		}
		
		public static function toInt(value:Object):int
		{
			return 0;
		}
		
		public static function toUint(value:Object):uint
		{
			return 0;
		}
	}
}