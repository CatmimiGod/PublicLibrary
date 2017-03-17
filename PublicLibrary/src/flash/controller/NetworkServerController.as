package flash.controller
{
	import flash.events.DatagramSocketDataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.NetworkControllerEvent;
	import flash.events.ProgressEvent;
	import flash.events.ServerSocketConnectEvent;
	import flash.net.DatagramSocket;
	import flash.net.NetworkUtils;
	import flash.net.ServerSocket;
	import flash.net.Socket;
	import flash.net.URLVariables;
	import flash.standard.INetworkController;
	import flash.utils.ByteArray;
	
	/**
	 *	运行日志记录事件 
	 */	
	[Event(name="logger", type="flash.events.NetworkControllerEvent")]
	
	/**
	 *	有客户端连接成功是发生 
	 */	
	[Event(name="add_client", type="flash.events.NetworkControllerEvent")]
	
	/**
	 *	有客户端断开时发生 
	 */	
	[Event(name="remove_client", type="flash.events.NetworkControllerEvent")]
	
	/**
	 *  有客户端连接或中断时发生
	 */
	[Event(name="client_change", type="flash.events.NetworkControllerEvent")]
	
	/**
	 *	客户端数据事件，可取消事件的默认行为，不执行标准指令，截取下来做其它分析
	 */
	[Event(name="client_data", type="flash.events.NetworkControllerEvent")]
	
	/**
	 * 网络控制器服务端
	 * @author Administrator
	 * @playerversion AIR 2
	 */	
	public class NetworkServerController extends EventDispatcher implements INetworkController
	{
		public static const TCP:String = "TCP";
		public static const UDP:String = "UDP";
		
		/** TCP	Socket 集合	*/
		protected var clients:Vector.<Socket>;
		/**	TCP Socket	*/
		protected var serverSocket:ServerSocket;
		/**	UDP Socket	*/
		protected var datagramSocket:DatagramSocket;
		
		/**	视图或模型对象	*/
		public var viewModel:Object = null;
		
		/**	自动广播数据	*/
		public var enabledBroadcast:Boolean = false;
		
		/**	
		 * 	是否忽略执行错误，默认为 true
		 * 	@default true	
		 */
		public var ignoreError:Boolean = true;		
		
		private var _bytes:ByteArray;
		
		/**
		 * Socket服务端
		 * @param viewModel
		 * @param localAddress
		 * @param localPort
		 * 
		 */
		public function NetworkServerController(viewModel:Object = null, localAddress:String = "0.0.0.0", localPort:int = 2000)
		{
			this.viewModel = viewModel;
			//NetworkUtils.analyseAvailableInterface();
			//<cross-domain-policy><allow-access-from domain="*" to-ports="*" /></cross-domain-policy>
			
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
			
			//UDP
			datagramSocket = new DatagramSocket();
			datagramSocket.addEventListener(DatagramSocketDataEvent.DATA, onDatagramSocketDataEventHandler);
			try
			{
				datagramSocket.bind(localPort);
				datagramSocket.receive();
			}
			catch(e:Error)
			{
				throw new Error("NetworkServerController启动失败，请检查UDP端口 " + localPort + " 是否被占用.");
			}
			
			_bytes = new ByteArray();
			clients = new Vector.<Socket>();
		}
		
		/**
		 * 	@param config
		 */		
		public function parseConfig(config:XML):void
		{
			if(config == null)	return;	
			if(config.hasOwnProperty("@enabled") && config.@enabled.toLowerCase() != "true")	return;
			
			var localPort:int = config.hasOwnProperty("localPort") && config.localPort.toString() != "" ? int(config.localPort.toString()) : 2000;
			var localAddress:String = config.hasOwnProperty("localAddress") && config.localAddress.toString() != "" ? config.localAddress.toString() : "0.0.0.0";
			
			//do some thing...
		}
				
		/**
		 *	关闭网络控制器服务并停止侦听连接。
		 *  关闭的网络控制器无法重新打开服务。需应创建一个新的 NetworkServerController 实例。
		 */		
		public function dispose():void
		{
			serverSocket.removeEventListener(Event.CLOSE, onServerCloseEventHandler);
			serverSocket.removeEventListener(ServerSocketConnectEvent.CONNECT, onServerConnectEventHandler);
			datagramSocket.removeEventListener(DatagramSocketDataEvent.DATA, onDatagramSocketDataEventHandler);
			
			for(var i:int = 0; i < clients.length; i ++)
				clients[i].close();
			
			_bytes.clear();
			_bytes = null;
			
			clients = null;
			viewModel = null;
			
			datagramSocket.close();
			datagramSocket = null;
			
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
		//UDP Socket 数据事件
		private function onDatagramSocketDataEventHandler(e:DatagramSocketDataEvent):void
		{
			parseClientData(e);
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
		 *	 发送数据至指定的客户端 
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
			
			if(client is Socket && client.connected)	//tcp
			{
				client.writeBytes(_bytes);
				client.flush();
			}
			else if(client is String)	//192.168.1.100:3000
			{
				for(var i:int = 0; i < clients.length; i ++)
				{
					var addr:String = clients[i].remoteAddress + ":" + clients[i].remotePort;
					if(addr.indexOf(client.toString()) != -1)
					{
						clients[i].writeBytes(_bytes);
						clients[i].flush();
					}
				}
			}
			else if(client.hasOwnProperty("srcAddress") && client.hasOwnProperty("srcPort"))		//udp
			{
				datagramSocket.send(_bytes, 0, 0, client.srcAddress, client.srcPort);
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
			
			_bytes.clear();
			var clientInfo:String;
			var type:String = client is Socket ? TCP : UDP;
			
			if(type == TCP)
			{
				client.readBytes(_bytes, 0, client.bytesAvailable);
				clientInfo = client.remoteAddress + ":" + client.remotePort;
			}
			else
			{
				_bytes = client.data;
				clientInfo = client.srcAddress + ":" + client.srcPort;
			}
			
			/**
			 * @internal	可取消事件的默认行为，就是不执行viewModel的方法。
			 */
			var dataEvent:NetworkControllerEvent = new NetworkControllerEvent(NetworkControllerEvent.CLIENT_DATA, false, true, _bytes, client, type, null);
			this.dispatchEvent(dataEvent);			
			if(dataEvent.isDefaultPrevented())	return;
			
			//读取分析数据
			var variables:URLVariables;
			var source:String = _bytes.readUTFBytes(_bytes.bytesAvailable);
			
			//logs event
			var logs:String = "客户端(" + type + ") " + clientInfo + " 发送数据：\r" + source;
			this.dispatchEvent(new NetworkControllerEvent(NetworkControllerEvent.LOGGER, false, false, source, client, type, logs));
			
			try
			{
				//variables.decode(source);
				variables = AS.decodeURLVariables(source);
			}
			catch(error:Error)
			{
				sendToClient(new URLVariables("funcName=serverReturnResult&args=please send url variables&code=0x01"), client);
				
				//logs event
				logs = "客户端(" + type + ") " + clientInfo + " 数据格式错误，源 [" + source + "] 参数必须是包含名称/值对的 URL 编码的查询字符串.";
				this.dispatchEvent(new NetworkControllerEvent(NetworkControllerEvent.LOGGER, false, false, source, client, type, logs));
				return;
			}
			
			parseURLVariables(variables, client);
		}
		
		
		/**
		 *	解析系统变量，系统执行方法或函数
		 * 	@param variables
		 */		
		protected function parseURLVariables(variables:URLVariables, client:Object):void
		{
			var func:String = variables.hasOwnProperty("funcName") ? variables.funcName : variables.hasOwnProperty("func") ? variables.func : null;
			if(func == null || func == "")	return;
			
			var modelDemoName:String = null;
			if(viewModel != null)	
				modelDemoName = viewModel.hasOwnProperty("demoName") ? viewModel.demoName : null;
			
			//将数据发送到指定的客户端
			if(variables.hasOwnProperty("to"))
			{
				var to:String = variables.to;
				delete variables.to;
				
				sendToClient(variables, to);
				return;
			}
			
			switch(func)
			{
				/*
				 * @internal
				 * 获取Demo配置
				 * getDemo(demoName:String = null):DemoConfig
				 */
				case "getDemo":
					if(client == null)	return;
					
					var config:URLVariables = new URLVariables();					
					var remoteAddress:String = client is Socket ? client.remoteAddress : client.srcAddress;
					var localAddress:String = NetworkUtils.getAddress(remoteAddress);
					
					/**
					 * @internal	
					 */
					if(variables.hasOwnProperty("args") && variables.args.toLowerCase() != "null")
					{
						if(variables.args == modelDemoName)
							config.decode("address=" + localAddress + "&port=" + serverSocket.localPort + "&demoName=" + modelDemoName);
					}
					else
					{
						config.decode("address=" + localAddress + "&port=" + serverSocket.localPort + (modelDemoName != null ? "&demoName=" + modelDemoName : ""));
					}
					
					sendToClient(config, client);
					break;
				
				case "getClients":
					break;
				
				case "setDemoName":
					break;
				
				default:
					if(enabledBroadcast)
						broadcast(variables, client);
					
					if(variables.hasOwnProperty("demoName") || variables.hasOwnProperty("demo"))
					{
						var targetDemo:String = variables.hasOwnProperty("demoName") ? variables.demoName : variables.hasOwnProperty("demo") ? variables.demo : null;
						if(targetDemo != modelDemoName)	return;
					}
					
					var args:String = variables.hasOwnProperty("args") ? variables.args : null;
					var model:Object = variables.hasOwnProperty("packages") ? variables.packages : viewModel;
					
					AS.callProperty(model, func, args, ignoreError);
			}
		}
		
		private function broadcast(variables:URLVariables, client:Object):void
		{
			_bytes.clear();
			_bytes.writeUTFBytes(decodeURIComponent(variables.toString()));
			
			for(var i:int = 0; i < clients.length; i ++)
			{
				if(clients[i] != client && clients[i].connected)
				{
					clients[i].writeBytes(_bytes);
					clients[i].flush();
				}
			}
		}
		
		public function getClients():Vector.<Socket>{	return clients;		}
		
		/**
		 *	跟踪或输出错误 
		 * @param message
		 */		
		protected function traceError(message:String):void
		{
			trace(message);
			this.dispatchEvent(new NetworkControllerEvent(NetworkControllerEvent.LOGGER, false, false, null, null, "none", message));
			if(!ignoreError)	throw new Error(message);
		}
		
		
	}
}