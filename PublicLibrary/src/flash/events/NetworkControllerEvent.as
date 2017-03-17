package flash.events
{
	/**
	 *	Network Controller Events
	 * @author Administrator
	 */	
	public class NetworkControllerEvent extends Event
	{
		public static const LOGGER:String = "logger";
		
		public static const ADD_CLIENT:String = "add_client";
		public static const REMOVE_CLIENT:String = "remove_client";
		public static const CLIENT_CHANGE:String = "client_change";
		
		public static const CLIENT_DATA:String = "client_data";
		
		public var data:Object = null;
		public var client:Object = null;
		public var clientType:String = "none";
		public var logs:String = null;
		
		/**
		 *	Constructor. 网络控制器事件 
		 * @param type
		 * @param bubbles
		 * @param cancelable
		 * @param data
		 * @param client
		 * @param clientType
		 * @param logs
		 */		
		public function NetworkControllerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, data:Object = null, client:Object = null, clientType:String = "none", logs:String = null)
		{
			super(type, bubbles, cancelable);
			
			this.logs = logs;
			this.data = data;
			this.client = client;
			this.clientType = clientType;
		}
		
		/**
		 *	@inheritDoc. 
		 */		
		override public function clone():Event
		{
			return new NetworkControllerEvent(type, bubbles, cancelable);
		}
		
		/**
		 *	@inheritDoc. 
		 */	
		override public function toString():String
		{
			return super.formatToString("NetworkControllerEvent");
		}
	}
}