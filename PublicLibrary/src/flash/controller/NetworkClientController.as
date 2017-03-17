package flash.controller
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.NetworkControllerEvent;
	import flash.events.ProgressEvent;
	import flash.net.SocketClient;
	import flash.net.URLVariables;
	import flash.standard.INetworkController;
	import flash.system.Security;
	import flash.utils.ByteArray;
	
	/**
	 *	连接或断开连接时调用 
	 * @author Administrator
	 */	
	[Event(name="change", type="flash.events.Event")]
	
	/**
	 *	客户端数据事件，可取消事件的默认行为，不执行标准指令，截取下来做其它分析
	 * 	@author Administrator
	 */	
	[Event(name="client_data", type="flash.events.NetworkControllerEvent")]

	/**
	 *	网络客户端控制器 
	 * @author Administrator
	 * @example 配置示例：
	 * <listing version="3.0">
	 * &lt;!--
	 * enabled:[必选]是否激活使用此配置功能，默认值为false
	 * port:[可选]远程服务端的端口号，默认为2000
	 * address:[可选]远程服务端地址，默认为127.0.0.1
	 * --&gt;
	 * 
	 * &lt;network enabled="true"&gt;
	 *		&lt;port&gt;2000&lt;/port&gt;
	 *		&lt;address&gt;127.0.0.1&lt;/address&gt;
	 * &lt;/network&gt;
	 * </listing>
	 */	
	public final class NetworkClientController extends EventDispatcher implements INetworkController
	{
		/**	
		 * 	是否忽略执行错误，默认为 true
		 * 	@default true	
		 */
		public var ignoreError:Boolean = true;
		
		//视图或模型对象
		private var _viewModel:Object;
		//Socket
		private var _socketClient:SocketClient;
		
		private var _bytes:ByteArray = new ByteArray();
		
		/**
		 *	 Constructor.
		 * @param viewModel
		 * @param remoteAddress
		 * @param remotePort
		 */		
		public function NetworkClientController(viewModel:Object, remoteAddress:String = "127.0.0.1", remotePort:int = 2000)
		{
			if(viewModel == null)
				throw new ArgumentError("NetworkClientController::viewModel参数不能为空");
			
			//针对Web嵌入通信，SocketServer v1.4.4
			Security.loadPolicyFile("xmlsocket://" + remoteAddress + ":" + (remotePort - 1));
			
			_viewModel = viewModel;
			
			_socketClient = new SocketClient();
			_socketClient.addEventListener(Event.CLOSE, onSocketStateChangeHandler);
			_socketClient.addEventListener(Event.CONNECT,onSocketStateChangeHandler);
			_socketClient.addEventListener(ProgressEvent.SOCKET_DATA, onClientDataEventHandler);
			
			connect(remoteAddress, remotePort);			
		}
		private function onSocketStateChangeHandler(e:Event):void
		{
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
		/**
		 *	 解析配置，见【网络控制客户标准配置】
		 * 	@param config:XML
		 * 
		 */
		public function parseConfig(config:XML):void
		{
			if(config == null)	return;	
			if(config.hasOwnProperty("@enabled") && config.@enabled.toLowerCase() != "true")	return;
			
			var port:int = config.hasOwnProperty("port") && config.port.toString() != "" ? int(config.port.toString()) : 2000;
			var address:String = config.hasOwnProperty("address") && config.address.toString() != "" ? config.address.toString() : "127.0.0.1";
		
			connect(address, port);
		}
		
		/**
		 *	 将控制器连接到指定的主机和端口。
		 * @param remoteAddress	远程主机地址
		 * @param remotePort	远程主机端口号
		 */		
		public function connect(remoteAddress:String = "127.0.0.1", remotePort:int = 2000):void
		{
			if(remoteAddress == null || remoteAddress == "")	return;
			
			//trace(_socketClient.remoteAddress, _socketClient.remotePort);
			if(_socketClient.connected)
			{
				if(_socketClient["remoteAddress"] != remoteAddress || _socketClient["remotePort"] != remotePort)
					_socketClient.close();
			}

			if(!_socketClient.connected && remoteAddress != null && remoteAddress != "null")
				_socketClient.connect(remoteAddress, remotePort);
		}
		
		/**
		 *	关闭控制器连接 
		 */		
		public function close():void
		{
			if(_socketClient.connected)
				_socketClient.close();
			
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
		/**	 表示此 网络控制对象目前是否已连接*/		
		public function get connected():Boolean{		return _socketClient && _socketClient.connected;		}
		
		/**
		 *	清理对象 
		 */		
		public function dispose():void
		{
			_socketClient.removeEventListener(Event.CLOSE, onSocketStateChangeHandler);
			_socketClient.removeEventListener(Event.CONNECT, onSocketStateChangeHandler);
			_socketClient.removeEventListener(ProgressEvent.SOCKET_DATA, onClientDataEventHandler);
			
			if(_socketClient.connected)
				_socketClient.close();
			
			_viewModel = null;
			_socketClient = null;
		}
		
		/**
		 *	发送数据 
		 * @param variables
		 */		
		public function sendURLVariables(variables:URLVariables):void
		{
			if(_socketClient && _socketClient.connected)
			{
				_socketClient.writeUTFBytes(decodeURIComponent(variables.toString()));
				_socketClient.flush();
			}
		}
		
		/**
		 *	发送数据至指定的Demo对象，与sendURLVariables一样，无差别；
		 * 
		 * @param variables
		 * @param demoName
		 */		
		public function sendToClient(variables:URLVariables, demoName:Object = null):void
		{
			if(demoName == null)
			{
				sendURLVariables(variables);
				return;
			}
			
			variables.demoName = demoName;
			sendURLVariables(variables);
		}
		
		/**
		 * 接收数据
		 * @param	e
		 */
		protected function onClientDataEventHandler(e:ProgressEvent):void
		{
			_bytes.clear();
			_socketClient.readBytes(_bytes, 0, _socketClient.bytesAvailable);
			var remoteClient:Object = _socketClient.hasOwnProperty("remoteAddress") ? {address:_socketClient["remoteAddress"], port:_socketClient["remotePort"]} : {address:null, port:0};
			
			/**
			 * @internal	可取消事件的默认行为，就是不执行viewModel的方法。
			 */
			var dataEvent:NetworkControllerEvent = new NetworkControllerEvent(NetworkControllerEvent.CLIENT_DATA, false, true, _bytes, remoteClient, "TCP", null);
			this.dispatchEvent(dataEvent);			
			if(dataEvent.isDefaultPrevented())	return;
			
			var source:String = _bytes.readUTFBytes(_bytes.bytesAvailable);			
			var variables:URLVariables = AS.decodeURLVariables(source);

			executeFunc(variables);
		}
		/**
		 *	分析执行客户端函数或方法 
		 * @param variables
		 */
		private function executeFunc(variables:URLVariables):void
		{
			/**
			 * @internal	如果命令参数有demo属性，则需要对比，没有指定demo则执行
			 */
			if(variables.hasOwnProperty("demoName") || variables.hasOwnProperty("demo"))// && (_viewModel.hasOwnProperty("demoName") || _viewModel.hasOwnProperty("demo")))
			{
				var targetDemo:String = variables.hasOwnProperty("demoName") ? variables.demoName : variables.hasOwnProperty("demo") ? variables.demo : null;
				//var modelDemo:String = _viewModel.hasOwnProperty("demoName") ? _viewModel.demoName : _viewModel.hasOwnProperty("demo") ? _viewModel.demo : null;
				var modelDemo:String = _viewModel.hasOwnProperty("demoName") ? _viewModel.demoName : null;
				
				if(targetDemo != modelDemo)	return;
			}
			
			var func:String = variables.hasOwnProperty("func") ? variables.func : variables.hasOwnProperty("funcName") ? variables.funcName : null;
			if(func == null || func == "")	return;
			
			var args:String = variables.hasOwnProperty("args") ? variables.args : null;
			var model:Object = variables.hasOwnProperty("packages") ? variables.packages : _viewModel;
			
			AS.callProperty(model, func, args, ignoreError);
		}
		
		
		/**
		 *	跟踪或输出错误 
		 * 	@param message
		 */		
		protected function traceError(message:String):void
		{
			trace(message);
			
			if(!ignoreError)	
				throw new Error(message);
		}
	}
}