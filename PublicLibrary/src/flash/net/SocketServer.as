package flash.net
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.NetworkControllerEvent;
	import flash.events.ProgressEvent;
	import flash.events.ServerSocketConnectEvent;
	import flash.net.ServerSocket;
	import flash.net.Socket;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	
	[Event(name="logger", type="flash.events.NetworkControllerEvent")]
	
	[Event(name="add_client", type="flash.events.NetworkControllerEvent")]
	
	[Event(name="remove_client", type="flash.events.NetworkControllerEvent")]
	
	[Event(name="client_change", type="flash.events.NetworkControllerEvent")]
	
	[Event(name="client_data", type="flash.events.NetworkControllerEvent")]
	
	/**
	 * 网络控制器服务端
	 * @author Administrator
	 * @playerversion AIR 2
	 */	
	public class SocketServer extends EventDispatcher
	{
		public static const TCP:String = "TCP";
		public static const UDP:String = "UDP";
		
		/** TCP	Socket 集合	*/
		protected var clients:Vector.<Socket>;
		/**	TCP Socket	*/
		protected var serverSocket:ServerSocket;
		
		/**	
		 * 	错误警告模式。默认会忽略错误格式的数据命令，及方法名称错误并不执函数或方法。<br />
		 * 	如果值为 true，则会弹出错误信息
		 * 	@default false	
		 */
		public var errorWarningMode:Boolean = false;		
		
		private var _bytes:ByteArray;
		
		/**
		 *	Socket服务端
		 * 	@param localPort	本地端口
		 */
		public function SocketServer(localPort:int = 2000)
		{
			//TCP
			serverSocket = new ServerSocket();
			serverSocket.addEventListener(Event.CLOSE, onServerCloseEventHandler);
			serverSocket.addEventListener(ServerSocketConnectEvent.CONNECT, onServerConnectEventHandler);
			try
			{
				serverSocket.bind(localPort);
				serverSocket.listen();
			}
			catch(e:Error)
			{
				throw new Error("NetworkServerController启动失败，请检查TCP端口 " + localPort + " 是否被占用.");
			}
			
			_bytes = new ByteArray();
			clients = new Vector.<Socket>();
		}
		
		/**
		 *	关闭网络控制器服务并停止侦听连接。
		 *  关闭的网络控制器无法重新打开服务。需应创建一个新的 NetworkServerController 实例。
		 */		
		public function dispose():void
		{
			serverSocket.removeEventListener(Event.CLOSE, onServerCloseEventHandler);
			serverSocket.removeEventListener(ServerSocketConnectEvent.CONNECT, onServerConnectEventHandler);
			
			_bytes.clear();
			_bytes = null;
			clients = null;
			
			serverSocket.close();
			serverSocket = null;
		}
		
		//系统关闭ServerSocket时处理
		private function onServerCloseEventHandler(e:Event):void
		{
			dispose();
			throw new Error("操作系统关闭了NetworkServerController网络控制器.");
		}
		//TCP Socket 连接事件处理
		private function onServerConnectEventHandler(e:ServerSocketConnectEvent):void
		{
			addTCPSocket(e.socket);
		}
		//client socket close event handler.
		private function onSocketCloseEventHandler(e:Event):void
		{
			removeTCPSocket(e.target as Socket);
		}
		//client socket data event handler.
		private function onSocketDataEventHandler(e:ProgressEvent):void
		{
			//analyseSocketData(e.target as Socket);
			parseClientData(e.target as Socket);
		}
		/**
		 *	添加TCP Socket对象 
		 * @param sock
		 */		
		protected function addTCPSocket(sock:Socket):void
		{
			//LOG Event
			var logs:String = "客户端(TCP) " + sock.remoteAddress + ":" + sock.remotePort + " 连接成功"
			this.dispatchEvent(new NetworkControllerEvent(NetworkControllerEvent.LOGGER, false, false, null, sock, TCP, logs));
			
			clients.push(sock);			
			sock.addEventListener(Event.CLOSE, onSocketCloseEventHandler, false, 0, true);
			sock.addEventListener(ProgressEvent.SOCKET_DATA, onSocketDataEventHandler, false, 0, true);
			
			//add client event
			this.dispatchEvent(new NetworkControllerEvent(NetworkControllerEvent.ADD_CLIENT, false, false, null, sock, TCP, null));
			this.dispatchEvent(new NetworkControllerEvent(NetworkControllerEvent.CLIENT_CHANGE, false, false, null, sock, TCP, null));
		}
		/**
		 *	移除TCP Socket对象 
		 * 	@param sock
		 */		
		protected function removeTCPSocket(sock:Socket):void
		{
			//LOG Event
			var logs:String = "客户端 (TCP)" + sock.remoteAddress + ":" + sock.remotePort + " 断开连接"
			this.dispatchEvent(new NetworkControllerEvent(NetworkControllerEvent.LOGGER, false, false, null, sock, TCP, logs));
			
			var startIndex:int = clients.indexOf(sock);
			if(startIndex == -1)	return;
			
			clients.splice(startIndex, 1);			
			sock.removeEventListener(Event.CLOSE, onSocketCloseEventHandler);
			sock.removeEventListener(ProgressEvent.SOCKET_DATA, onSocketDataEventHandler);
			
			//remove client event
			this.dispatchEvent(new NetworkControllerEvent(NetworkControllerEvent.REMOVE_CLIENT, false, false, null, sock, TCP, null));
			this.dispatchEvent(new NetworkControllerEvent(NetworkControllerEvent.CLIENT_CHANGE, false, false, null, sock, TCP, null));
		}
		
		/**
		 *	 广播发送数据至所有在线TCP客户端 
		 * 
		 * @param variables
		 */
		public function sendURLVariables(variables:URLVariables):void
		{
			if(variables == null)		return;
			
			_bytes.clear();
			_bytes.writeUTFBytes(decodeURIComponent(variables.toString()));
			
			for(var i:int = 0; i < clients.length; i ++)
			{
				if(clients[i].connected)
				{
					clients[i].writeBytes(_bytes);
					clients[i].flush();
				}
			}
		}
		
		/**
		 *	 广播发送数据至所有在线TCP客户端 
		 * 
		 * @param variables
		 */
		public function sendByteArray(bytes:ByteArray):void
		{
			if(bytes == null)	return;
			
			for(var i:int = 0; i < clients.length; i ++)
			{
				if(clients[i].connected)
				{
					clients[i].writeBytes(bytes);
					clients[i].flush();
				}
			}
		}
		
		/**
		 *	 发送数据至客户端 
		 * 
		 * @param variables
		 * @param client	客户端对象为TCP类型或UDP({srcAddress:127.0.0.1, srcPort:1234})，客户端为空则将信息发送至所有TCP对象
		 */
		public function sendToClient(variables:URLVariables, client:Object = null):void
		{
			if(variables == null)		return;
			
			if(client == null)
			{
				sendURLVariables(variables);
				return;
			}
			
			_bytes.clear();
			_bytes.writeUTFBytes(decodeURIComponent(variables.toString()));
			
			if(client is Socket && client.connected)
			{
				client.writeBytes(_bytes);
				client.flush();
			}
			else
			{
				throw new ArgumentError("sendToClient client对象错误");
			}
		}
		
		
		/**
		 *	解析客户端数据 
		 * 	@param client
		 */		
		protected function parseClientData(client:Object):void
		{
			if(client == null)	return;
			
			var source:String;
			var clientInfo:String;
			var variables:URLVariables;
			var type:String = client is Socket ? TCP : UDP;
			
			if(type == TCP)
			{
				source = client.readUTFBytes(client.bytesAvailable);
				clientInfo = client.remoteAddress + ":" + client.remotePort;
			}
			else
			{
				source = client.data.readUTFBytes(client.data.bytesAvailable);
				clientInfo = client.srcAddress + ":" + client.srcPort;
			}
			
			//logs event
			var logs:String = "客户端(" + type + ") " + clientInfo + " 发送数据：\r" + source;
			this.dispatchEvent(new NetworkControllerEvent(NetworkControllerEvent.LOGGER, false, false, source, client, type, logs));
			
			/**
			 * @internal	可取消事件的默认行为，就是不执行viewModel的方法。
			 */
			var dataEvent:NetworkControllerEvent = new NetworkControllerEvent(NetworkControllerEvent.CLIENT_DATA, false, true, source, client, type, null);
			this.dispatchEvent(dataEvent);			
			if(dataEvent.isDefaultPrevented())	return;
			/*
			try
			{
				variables = new URLVariables(source);
			}
			catch(error:Error)
			{
				sendToClient(new URLVariables("funcName=serverReturnResult&args=please send url variables&code=0x01"), client);
				
				//logs event
				logs = "客户端(" + type + ") " + clientInfo + " 数据格式错误，源 [" + source + "] 参数必须是包含名称/值对的 URL 编码的查询字符串.";
				this.dispatchEvent(new NetworkControllerEvent(NetworkControllerEvent.LOGGER, false, false, source, client, type, logs));
				return;
			}
			*/
		}
		
		/**
		 *	跟踪或输出错误 
		 * @param message
		 */		
		protected function traceError(message:String):void
		{
			trace(message);
			this.dispatchEvent(new NetworkControllerEvent(NetworkControllerEvent.LOGGER, false, false, null, null, "none", message));
			if(errorWarningMode)	throw new Error(message);
		}
		
		public function getClients():Vector.<Socket>
		{
			return clients;
		}
	}
}


