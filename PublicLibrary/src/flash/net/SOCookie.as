package flash.net
{
	/**
	 *	SharedObject Cookie 
	 * @author Huangmin
	 */	
	public class SOCookie
	{
		/**
		 * 设置Cookie数据.
		 * @param name:String	Cookie名称
		 * @param property:String	值所对应的属性
		 * @param value:String	值
		 */		
		public static function setCookie(name:String, property:String, value:Object):void
		{
			if(name == null || property == null)
				throw new ArgumentError("Cookie name和property不能为空.");
			
			var so:SharedObject = SharedObject.getLocal(name, "/");
			so.data[property] = value;
			so.flush();
		}
		
		/**
		 * 获取Cookie数据.
		 * @param name:String	Cookie名称
		 * @param property:String	值所对应的属性,如果设为null，将返回so.data对象
		 * @return 返回属性所对应的值
		 */		
		public static function getCookie(name:String, property:String = null):Object
		{
			if(name == null)
				throw new ArgumentError("Cookie name不能为空.");
			
			var so:SharedObject = SharedObject.getLocal(name, "/");
			
			return property == null ? so.data : so.data[property];
		}
		
		/**
		 * 清除Cookie数据
		 * @param name:String	Cookie名称
		 */		
		public static function clearCookie(name:String):void
		{
			if(name == null)
				throw new ArgumentError("Cookie name不能为空.");
			
			var so:SharedObject = SharedObject.getLocal(name, "/");
			so.clear();
		}
		
		/**
		 *	获取Cookie大小 
		 * @param name:String	Cookie名称
		 * @return 返回Cookie大小
		 */		
		public static function getCookieSize(name:String):uint
		{
			if(name == null)
				throw new ArgumentError("Cookie name不能为空.");
			
			var so:SharedObject = SharedObject.getLocal(name, "/");
			return so.size;
		}
	}
}