package flash.controller
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.events.ProgressEvent;
	import flash.net.Socket;
	import flash.standard.IKeyboardController;
	import flash.utils.setTimeout;
	
	/**
	 *	全局键盘控制 
	 * 	@author Administrator
	 */	
	public class GlobalKeyboardController implements IKeyboardController
	{
		/**	
		 * 	是否忽略执行错误，默认为 true
		 * 	@default true	
		 */
		public var ignoreError:Boolean = false;
		
		private var _port:int;
		private var _address:String;
		private var _socket:Socket;
		
		private var _model:Object;
		private var _config:XML;
		private var _enabled:Boolean;
		
		/**
		 * 	Constructor.
		 * 
		 * @param model
		 * @param config
		 * @param port
		 * @param address
		 * 
		 */
		public function GlobalKeyboardController(model:Object, config:XML = null, port:int = 2012, address:String = "127.0.0.1")
		{
			if(model == null)
				throw new ArgumentError("GlobalKeyboardController model参数不能为空。");
			
			_port = port;
			_model = model;
			_config = config;
			_address = address;
			
			_socket = new Socket(_address, _port);
			_socket.addEventListener(Event.CLOSE, onSocketEventHandler);
			_socket.addEventListener(Event.CONNECT, onSocketEventHandler);
			_socket.addEventListener(IOErrorEvent.IO_ERROR, onSocketEventHandler);
			_socket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketEventHandler);
		}
		
		private var arr:Array;
		private var array:Array;
		private var source:String;
		
		private function onSocketEventHandler(e:Event):void
		{
			switch(e.type)
			{
				case Event.CLOSE:
				case IOErrorEvent.IO_ERROR:
					trace("Repeat Connect...", e.type);
					setTimeout(_socket.connect, 500, _address, _port);
					break;
				
				case Event.CONNECT:
					break;
				
				case ProgressEvent.SOCKET_DATA:
					if(!_enabled)	return;
					
					var data:Object = {};
					source = _socket.readUTFBytes(_socket.bytesAvailable);
					
					array = source.split("&");
					
					for(var i:int = 0; i < array.length; i ++)
					{
						if(array[i].indexOf("=") == -1)	continue;
						arr = array[i].split("=");
						
						if(arr.length != 2)	continue;
						data[arr[0]] = arr[1];
					}
					
					analyseData(data);
					break;
			}
		}
		protected function analyseData(data:Object):void
		{
			if(data.hasOwnProperty("keyType") && data.hasOwnProperty("keyValue"))
			{
				var key:XMLList = _config.children().(@code == data.keyValue).(@type == data.keyType);
				
				if(key.length() != 1)	return;
				var func:String = key.hasOwnProperty("@func") ? key.@func : key.hasOwnProperty("@funcName") ? key.@funcName : null;
				if(func == null || func == "")	return;
					
				var args:String = key.hasOwnProperty("@args") ? key.@args : null;
				args = args != null && args.length > 0 ? args : null; 
				
				AS.callProperty(_model, func, args, ignoreError);
			}
		}
		
		/**
		 *	 解析配置，见【键盘控制标准配置】
		 * 	@param config:XML
		 * 
		 * @example 配置示例：
		 * <listing version="3.0">
		 * &lt;!--
		 * enabled:[必选]是否激活使用此配置功能，默认值为false
		 * hookKeyboard:[可选]是否使用监听全局键盘控制，默认值为false。此属性用于GlobalKeyboardController类
		 * listenerKeyUp:[可选]是否监听键盘释放，默认为true
		 * listenerKeyDown:[可选]是否监听键盘按下，默认为false
		 * lockFullScreen:[可选]是否锁定全屏，只用AIR桌面程序用效，默认为false。设为true后，按Esc键程序不会退出全屏，需要按Alt+F4退出程序
		 * type:[可选]监听按键事件类型，值为keyUp或keyDown，默认为keyUp
		 * name:[可选]键盘键名，name与code使用其一
		 * code:[可选]键盘键值，name与code使用其一
		 * func:[必选]程序需要执行的函数或属性
		 * args:[可选]函数或属性的值
		 * --&gt;
		 * 
		 * &lt;keyboard enabled="true" hookKeyboard="false" listenerKeyUp="true" listenerKeyDown="false" lockFullScreen="false"&gt;
		 *	 &lt;key type="keyUp" name="L" code="76" func="setLanguage" args="cn" /&gt;
		 * &lt;/keyboard&gt;
		 * 
		 * </listing>
		 */			
		public function parseConfig(config:XML):void
		{
			if(config == null || _config != null)		return;
			
			_config = config.copy();
			_enabled = _config.hasOwnProperty("@enabled") && _config.@enabled.toLowerCase() == "true";			
			
			/**
			 * @internal	还原输出标准配置
			 */
			var len:int = _config.children().length();
			if(!_config.hasOwnProperty("@listenerKeyUp"))		_config.@listenerKeyUp = "true";
			if(!_config.hasOwnProperty("@listenerKeyDown"))	_config.@listenerKeyDown = "false";
			
			for(var i:int = len - 1; i >= 0; i --)
			{
				var key:XML = _config.children()[i];
				
				//检查func属性
				var func:String = key.hasOwnProperty("@func") ? key.@func : key.hasOwnProperty("@funcName") ? key.@funcName : null;
				if(func == null || func == "")
				{
					delete _config.children()[i];
					continue;
				}
				
				//默认为KeyUp事件
				if(!key.hasOwnProperty("@type"))	key.@type = KeyboardEvent.KEY_UP;
				
				if(key.hasOwnProperty("@name"))
				{
					key.@name = key.@name.toUpperCase();
					var code:uint = Keyboard.name2Code(key.@name);
					if(code != 0)
						key.@code = code;
					else
					{
						delete _config.children()[i];
						continue;
					}
				}
				
				if(!key.hasOwnProperty("@code"))
					delete _config.children()[i];
			}
		}

		/**
		 * 添加键盘控制配置项
		 * 
		 * @param name 需要监听的键字符
		 * @param func
		 * @param args
		 * @param eventType
		 */
		public function addKeyItem(name:String, func:String, args:String=null, eventType:String=KeyboardEvent.KEY_UP):void
		{
			if(name.length > 1 || func == null || func == "")
				throw new ArgumentError("addKeyItem 参数错误，char长度应为1，func参数不能为null.");
			
			name = name.toUpperCase();
			var code:uint = Keyboard.name2Code(name);
			if(code == 0)
			{
				traceError("addKeyItem 暂时不支持的键名：" + name + "，键值：" + code);
				return;
			}
			
			if(_config == null)
			{
				var config:XML = <keyboard enabled="true" listenerKeyUp="true" listenerKeyDown="false"></keyboard>;
				config.appendChild(<key type={eventType} code={code} name={name} func={func} args={args} />);
				
				parseConfig(config);
				return;
			}
			
			_config.appendChild(<key type={eventType} code={code} name={name} func={func} args={args} />);
		}
		
		/**
		 *	清理对象
		 */
		public function dispose():void
		{
			_socket.removeEventListener(Event.CLOSE, onSocketEventHandler);
			_socket.removeEventListener(Event.CONNECT, onSocketEventHandler);
			_socket.removeEventListener(IOErrorEvent.IO_ERROR, onSocketEventHandler);
			_socket.removeEventListener(ProgressEvent.SOCKET_DATA, onSocketEventHandler);
			
			if(_socket.connected)
				_socket.close();
			
			_model = null;
			_config = null;
		}
		
		/**
		 *	跟踪或输出错误 
		 * 	@param message
		 */		
		protected function traceError(message:String):void
		{
			if(ignoreError)	
				trace(message);
			else
				throw new Error(message);
		}
		
	}
}