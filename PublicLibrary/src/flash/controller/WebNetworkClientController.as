package flash.controller
{
	import com.worlize.websocket.WebSocket;
	import com.worlize.websocket.WebSocketErrorEvent;
	import com.worlize.websocket.WebSocketEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;

	/**
	 *	连接或断开连接时调用 
	 * @author Administrator
	 */	
	[Event(name="change", type="flash.events.Event")]
	
	/**
	 * 未完成的WebSocket控制类
	 */
	public class WebNetworkClientController extends EventDispatcher
	{
		/**	
		 * 	错误警告模式。默认会忽略错误格式的数据命令，及方法名称错误并不执函数或方法。<br />
		 * 	如果值为 true，则会弹出错误信息
		 * 	@default false	
		 */
		public var errorWarningMode:Boolean = false;
		
		//视图或模型对象
		private var _viewModel:Object;
		
		private var _webSocket:WebSocket;
		
		public function WebNetworkClientController(viewModel:Object, uri:String,origin:String,protocols:*=null,timeout:uint=10000)
		{
			if(viewModel == null)
				throw new ArgumentError("NetworkClientController::viewModel参数不能为空");
			
			_viewModel = viewModel;
			connect(uri,origin,protocols,timeout);
		}
		
		/**
		 * 
		 */
		public function connect(uri:String,origin:String,protocols:*=null,timeout:uint=10000):void
		{
			if(_webSocket != null && _webSocket.connected)
			{
				close();
			}
			
			_webSocket = new WebSocket(uri,origin,protocols,timeout);
			addEvent(_webSocket);
			_webSocket.connect();
		}
		
		/**
		 *	 解析配置，见【网络控制客户标准配置】
		 * 	@param config:XML
		 */
		public function parseConfig(config:XML):void
		{
			if(config == null)	return;			
			if(config.hasOwnProperty("@enabled") && config.@enabled.toLowerCase() != "true")	return;
			
			var uri:String = config.hasOwnProperty("uri") && config.uri.toString() != "" ? String(config.uri.toString()) : "ws://127.0.0.1:3000";
			var origin:String = config.hasOwnProperty("origin") && config.origin.toString() != "" ? config.origin.toString() : "*";
			var protocols:* = config.hasOwnProperty("protocols") && config.protocols.toString() != "" ? config.protocols.toString() : null;
			var timeout:uint = config.hasOwnProperty("timeout") && config.timeout.toString() != "" ? uint(config.timeout.toString()) : 10000;
			
			connect(uri, origin,protocols,timeout);
		}
		
		/**
		 * 
		 */
		protected function addEvent(ws:WebSocket):void
		{
			ws.addEventListener( WebSocketEvent.OPEN, onConnectedHandler);
			ws.addEventListener( WebSocketEvent.CLOSED, onCloseHandler );
			ws.addEventListener( WebSocketEvent.MESSAGE, onMessageHandler );
			ws.addEventListener( WebSocketErrorEvent.CONNECTION_FAIL, onErrorHandler );
			ws.addEventListener( IOErrorEvent.IO_ERROR, onIoErrorHandler );
		}
		
		/**
		 * 
		 */
		protected function removeEvent(ws:WebSocket):void
		{
			ws.removeEventListener( WebSocketEvent.OPEN, onConnectedHandler);
			ws.removeEventListener( WebSocketEvent.CLOSED, onCloseHandler );
			ws.removeEventListener( WebSocketEvent.MESSAGE, onMessageHandler );
			ws.removeEventListener( WebSocketErrorEvent.CONNECTION_FAIL, onErrorHandler );
			ws.removeEventListener( IOErrorEvent.IO_ERROR, onIoErrorHandler );
		}
		
		/**
		 * 
		 */
		protected function onConnectedHandler(e:WebSocketEvent):void
		{
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
		/**
		 * 
		 */
		protected function onCloseHandler(e:WebSocketEvent):void
		{
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
		/**
		 * 
		 */
		protected function onMessageHandler(e:WebSocketEvent):void
		{
			var byt:ByteArray = e.message.binaryData;
			var source:String = byt.readUTFBytes(byt.bytesAvailable);			
			
			var variables:URLVariables = new URLVariables();
			try
			{
				variables.decode(source);
			}
			catch(e:Error)
			{
				traceError("NetworkClientController::URLVariables << " + source + " >> 解析错误。");
			}
			
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
			if(variables.hasOwnProperty("demoName") || variables.hasOwnProperty("demo"))
			{
				var targetDemo:String = variables.hasOwnProperty("demoName") ? variables.demoName : variables.hasOwnProperty("demo") ? variables.demo : null;
				var modelDemo:String = _viewModel.hasOwnProperty("demoName") ? _viewModel.demoName : null;
				
				if(targetDemo != modelDemo)	return;
			}
			
			var func:String = variables.hasOwnProperty("func") ? variables.func : variables.hasOwnProperty("funcName") ? variables.funcName : null;
			if(func == null || func == "")	return;
			
			var args:String = variables.hasOwnProperty("args") ? variables.args : null;
			//executeFuncName(_viewModel, func, args, errorWarningMode);
			AS.callProperty(_viewModel, func, args, errorWarningMode);
		}
		
		/**
		 * 
		 */
		protected function onErrorHandler(e:WebSocketErrorEvent):void
		{
			
		}
		
		/**
		 * 
		 */
		protected function onIoErrorHandler(e:IOErrorEvent):void
		{
			
		}
		
		/**
		 * 
		 */
		public function close():void
		{
			removeEvent(_webSocket);
			_webSocket.close();
		}
		
		/**
		 *	清理对象 
		 */		
		public function dispose():void
		{
			close();
		}
		
		/**
		 *	跟踪或输出错误 
		 * 	@param message
		 */		
		protected function traceError(message:String):void
		{
			trace(message);
			
			if(errorWarningMode)	
				throw new Error(message);
		}
	}
}