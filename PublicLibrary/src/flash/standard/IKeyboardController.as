package flash.standard
{
	import flash.events.KeyboardEvent;
	//import flash.events.IEventDispatcher;
	
	/**
	 * 键盘控制接口
	 */
	public interface IKeyboardController// extends IEventDispatcher
	{
		/**
		 *	 解析配置，见【键盘控制标准配置】
		 * 	@param config:XML
		 */		
		function parseConfig(config:XML):void;
		
		/**
		 * 添加键盘控制配置项
		 * 
		 * @param name 需要监听的键字符
		 * @param func
		 * @param args
		 * @param eventType
		 */
		function addKeyItem(name:String, func:String, args:String = null, eventType:String = KeyboardEvent.KEY_UP):void;
		
		/**
		 *	清理对象
		 */	
		function dispose():void;
	}
}