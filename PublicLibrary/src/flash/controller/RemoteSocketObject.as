package flash.controller
{
	import flash.net.DatagramSocket;
	import flash.net.Socket;
	import flash.utils.ByteArray;

	/**
	 *	远程客户端对象 
	 * @author Administrator
	 */	
	internal final class RemoteSocketObject
	{
		public var demoName:String;

		private var _type:String;
		private var _socket:Object;
		
		
		/**
		 *	Constructor. 
		 */		
		public function RemoteSocketObject(socket:Object)
		{
			if(socket == null)	return;
			
			_type = socket is Socket ? "TCP" : socket is DatagramSocket ? "UDP" : "NONE";
			if(_type == "NONE")
				throw new ArgumentError("socket客户端对象错误。");
			
			_socket = socket;
		}
		
		/**
		 *	清理远程客户端对象 
		 */		
		public function dispose():void
		{
			if(_type == "TCP" && _socket.connected)
				_socket.close();
			
			_type = null;
			_socket = null;			
			demoName = null;
		}
		
		/**
		 *	获取数据 
		 * @return 
		 */		
		public function getData():String
		{
			var data:String;
			
			if(type == "TCP")
			{
				if(_socket.connected)
					data = _socket.readUTFBytes(_socket.bytesAvailable);
			}
			else
			{
				data = _socket.data.readUTFBytes(_socket.data.bytesAvailable);
			}
			
			return data;
		}
		
		/**
		 *	发送数据 
		 * @param variables
		 */		
		public function send(data:String):void
		{
			if(_type == "TCP")
			{
				_socket.writeUTFBytes(data);
				_socket.flush();
			}
			else
			{
				var bytes:ByteArray = new ByteArray();
				bytes.writeUTFBytes(data);
				
				_socket.send(bytes, 0, 0, address, port);
			}
		}
		
		/**
		 *	远程客户端类型 
		 * @return 返回TCP或UDP
		 */		
		public function get type():String{	return _type;		}
		
		/**
		 *	远程客户端端口 
		 * @return 
		 */		
		public function get port():int
		{	
			if(_socket == null)		return -1;			
			var tp:int = _type == "TCP" ? _socket.remotePort : _socket.srcPort;
			
			return tp;
		}
		
		/**
		 *	远程客户端地址 
		 * @return 
		 */		
		public function get address():String
		{		
			if(_socket == null)		return  null;			
			var td:String = _type == "TCP" ? _socket.remoteAddress : _socket.srcAddress;
			
			return td;		
		}
		
	}
}