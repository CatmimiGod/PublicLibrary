package flash.ext
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.Socket;
	import flash.utils.setTimeout;

	/**
	 *	C# WebBrowserController 控制对象
	 * 	@author Administrator
	 */	
	public final class WebBrowserController
	{
		private var _port:int;
		private var _address:String;
		
		private var _socket:Socket;
		
		private var _queue:Vector.<String>
		private var _stateInfo:Object;
		
		/**
		 *	 
		 * @param port 浏览器窗体端口号
		 */		
		public function WebBrowserController(port:int = 2020, address:String = "127.0.0.1")
		{
			_port = port;
			_address = address;
			
			_queue = new Vector.<String>();		_queue.push("getState");
			_stateInfo = {visible:"true", readyState:""};
			
			_socket = new Socket(_address, _port);
			_socket.addEventListener(Event.CLOSE, onSocketEventHandler);
			_socket.addEventListener(Event.CONNECT, onSocketEventHandler);
			_socket.addEventListener(IOErrorEvent.IO_ERROR, onSocketEventHandler);
			_socket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketEventHandler);
		}
		
		private function onSocketEventHandler(e:Event):void
		{
			//trace(e.type);
			switch(e.type)
			{
				case Event.CLOSE:
				case IOErrorEvent.IO_ERROR:
					//trace("VideoPlayer Connect...", e.type);
					setTimeout(_socket.connect, 500, _address, _port);
					break;
				
				case Event.CONNECT:
					sendQueues();
					break;
				
				case ProgressEvent.SOCKET_DATA:
					analyseData(_socket.readUTFBytes(_socket.bytesAvailable));
					break;
			}
		}
		/**	分析接收的数据	*/
		protected function analyseData(value:String):void
		{
			//trace(value);
			var data:Array = value.split(";");
			var len:int = data.length;
			
			var obj:Array;
			var prop:String;
			
			for(var i:int = 0; i < len; i ++)
			{
				if(data[i].indexOf(":") == -1)	break;
				
				obj = data[i].split(":");
				prop = obj[0];
				
				if(!_stateInfo.hasOwnProperty(prop))
					break;
				
				switch(prop)
				{
					case "visible":
					case "readyState":
						_stateInfo[prop] = obj[1];
						break;
				}
			}
			
			//sendData("getState");
		}
		
		/**	发送失败的命令，重新排队发送	*/
		protected function sendQueues():void
		{
			if(_queue.length == 0)	return;
			trace("sendQueues...");
			
			var queue:Vector.<String> = _queue.concat();
			var count:int = queue.length;
			
			_queue = new Vector.<String>();
			for(var i:int = count - 1; i >= 0; i --)
			{
				trace(queue[i]);
				//sendData(queue[i]);
				setTimeout(sendData, 100 * i, queue[i]);
				queue.splice(i, 1);
			}
		}
		
		/**	发送URL变量数据 	 @param value	 */		
		protected function sendData(value:String):void
		{
			if(_socket == null)		return;
			
			if(_socket.connected)
			{
				_socket.writeUTFBytes(value);
				_socket.flush();
			}
			else
			{
				_queue.unshift(value);
			}
		}
		
		/**	关闭视频窗体并清理对象内存	*/
		public function dispose():void
		{
			sendData("dispose");
			
			_queue = null;
			_stateInfo = null;
			
			_socket.removeEventListener(Event.CLOSE, onSocketEventHandler);
			_socket.removeEventListener(Event.CONNECT, onSocketEventHandler);
			_socket.removeEventListener(IOErrorEvent.IO_ERROR, onSocketEventHandler);
			_socket.removeEventListener(ProgressEvent.SOCKET_DATA, onSocketEventHandler);
			
			if(_socket.connected)	_socket.close();
			_socket = null;
		}
		
		/**
		 * 设置窗体尺寸大小
		 * @param size 0,0,800,600(x,y,w,h)
		 */
		public function setSize(size:String):void{	sendData("setSize:" + size);	}
		
		/**
		 *	设置URL地址 
		 * @param url
		 */		
		public function setURL(url:String):void{		sendData("setURL:" + url);		}
		
		/**	后退	*/
		public function goBack():void{ 	sendData("goBack");		}
		
		/** 前进	*/
		public function goForward():void{		sendData("goForward");	}
		
		/**	刷新	*/
		public function refresh():void{	sendData("refresh");		}
		
		/**	停止	*/
		public function stop():void{		sendData("stop");		}
		
		/**
		 *	页面缩放比例，只支持IE内核的浏览器
		 * @param value	原比例为100
		 */
		public function zoom(value:int = 100):void{	sendData("zoom:" + value);		}
		
		/**	窗体置后	*/
		public function windowToBack():void{	sendData("windowToBack");		}
		
		/**	窗体置前	*/
		public function windowToFront():void{		sendData("windowToFront");	}
		
		/**	窗体是否可见	*/
		public function get visible():Boolean{		return _stateInfo.visible == "true";	}
		public function set visible(value:Boolean):void
		{
			sendData("visible:" + value.toString());
		}
		
		//public function get debug():Boolean{		return "";	}
		public function set debug(value:Boolean):void
		{
			sendData("debug:" + value.toString());
		}
		
		
		
		
	}
}