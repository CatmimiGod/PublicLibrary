package flash.standard
{
	import flash.events.IEventDispatcher;
	import flash.net.URLVariables;

	/**
	 *	网络控制对象接口 
	 * @author Administrator
	 */	
	public interface INetworkController extends IEventDispatcher
	{
		/**
		 *	清理对象 
		 */		
		function dispose():void;
			
		/**
		 *	解析配置 
		 * 	@param config
		 */		
		function parseConfig(config:XML):void;
		
		/**
		 *	广播URLVariables数据 
		 * 	@param variables
		 */		
		function sendURLVariables(variables:URLVariables):void;
			
		/**
		 *	将 URLVariables数据发送至指定的客户端，或demo对象
		 * 
		 * @param variables
		 * @param client
		 */		
		function sendToClient(variables:URLVariables, client:Object = null):void;
		
	}
}