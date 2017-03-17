package flash.display
{
	import flash.controller.NetworkClientController;
	import flash.debug.TextButton;
	import flash.events.DatagramSocketDataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.net.NetworkUtils;
	import flash.net.SOCookie;
	import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	import be.aboutme.nativeExtensions.udp.UDPSocket;
	
	[Event(name="close", type="flash.events.Event")]

	/**
	 *	Demo 控制端UI 移动端UI
	 * @author Administrator
	 */	
	public class ConfigWindow extends EventDispatcher
	{
		private var _txt0:TextField;
		private var _txt1:TextField;
		
		private var _window:Sprite;
		private var _owner:Object;
		
		private var _udp:UDPSocket;
		private var _localAddress:String;
		//private var _udp:DatagramSocket;
		
		private var _cookieName:String;
		private var _regexp:RegExp =  /(^(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[0-9]{1,2})(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[0-9]{1,2})){3}$)|(^(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[0-9]{1,2})(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[0-9]{1,2})){3}:\d{4,7}$)/g;
		
		private var _tft:TextFormat = new TextFormat("微软雅黑", 45, 0x000000);
		
		public var networkController:NetworkClientController;
		
		/**
		 *	Constructor. 
		 */		
		public function ConfigWindow(owner:Object, networkController:NetworkClientController = null)
		{
			_owner = owner;
			NetworkUtils.analyseAvailableInterface();
			
			this.networkController = networkController;
			if(this.networkController)
				this.networkController.addEventListener(Event.CHANGE, onNetworkChangeHandler);
			
			_localAddress = NetworkUtils.getAddress();
			_cookieName = _owner.hasOwnProperty("demoName") && _owner.demoName != null ? _owner.demoName : "Demo_config";
			
			initUI();
		}
		protected function initUI():void
		{
			var sw:Number = 1920;
			var sh:Number = 1080;
			
			_window = new Sprite();
			_window.graphics.beginFill(0x666666, .8);
			_window.graphics.drawRect(0, 0, sw, sh);
			_window.graphics.endFill();
			
			var tf1:TextField = getTextField("Configuration", 650, 88, 65);
			tf1.x = tf1.y = 100;
			_window.addChild(tf1);
			var tf2:TextField = getTextField("Remote Address:", 500, 55, 45);
			tf2.x = tf1.x
			tf2.y = tf1.y + tf1.height + 100;
			_window.addChild(tf2);
			
			_txt0 = getTextField("Local Address:", tf1.width, 35, 22);
			_txt0.y = tf1.y + tf1.height;
			_txt0.x = tf1.x + tf1.width - _txt0.width;
			_window.addChild(_txt0);
			
			_txt1 = getTextField("127.0.0.1", 700, tf2.height, int(_tft.size), true);
			_txt1.name = "text_address";
			_txt1.x = tf2.x + tf2.width + 5;
			_txt1.y = tf2.y;
			_txt1.addEventListener(MouseEvent.CLICK, onMouseClickHandler);
			_window.addChild(_txt1);
			
			var btn_ok:TextButton = new TextButton("OK");
			btn_ok.name = "ok";
			btn_ok.x = _txt1.x + _txt1.width + 30;
			btn_ok.y = _txt1.y;
			btn_ok.height = _txt1.height;
			btn_ok.textFormat = new TextFormat("微软雅黑", 30, 0x000000);
			btn_ok.addEventListener(MouseEvent.CLICK, onMouseClickHandler);
			_window.addChild(btn_ok);
			
			if(_owner.hasOwnProperty("demoName") && _owner.demoName != null && Capabilities.os.toLowerCase().indexOf("iphone") == -1)
			{
				var btn_refresh:TextButton = new TextButton("Refresh");
				btn_refresh.name = "refresh";
				btn_refresh.x = btn_ok.x + btn_ok.width + 30;
				btn_refresh.y = btn_ok.y;
				btn_refresh.height = btn_ok.height;
				btn_refresh.textFormat = new TextFormat("微软雅黑", 30, 0x000000);
				btn_refresh.addEventListener(MouseEvent.CLICK, onMouseClickHandler);
				_window.addChild(btn_refresh);
			}
			else
			{
				btn_ok.width = 250;
			}
			
			_window.width = _owner.stage.stageWidth;
			_window.height = _owner.stage.stageHeight;
			_owner.addChildAt(_window, _owner.numChildren - 1);

			//SOCookie.clearCookie(_cookieName);			
			_txt0.text = "Local Address:" + (_localAddress == null ? "null" : _localAddress) + " Connected:false";
			if(_localAddress != null)
				_txt1.text = _localAddress.substr(0, _localAddress.lastIndexOf(".") + 1);
			
			if(SOCookie.getCookieSize(_cookieName) > 0)
			{
				_txt1.text = SOCookie.getCookie(_cookieName, "address").toString();
				if(networkController)
				{
					trace("_localAddress", _localAddress);
					networkController.connect(address, port);
					_txt0.text = "Local Address:" + (_localAddress == null ? "null" : _localAddress) + " Connected:" + networkController.connected;
				}
				
				close();
			}
			else	
			{
				show();
				
				if(_owner.hasOwnProperty("demoName") && _owner.demoName != null)
					getRemoteDemoConfig();
			}
		}
		private function onNetworkChangeHandler(e:Event):void
		{
			_txt0.text = "Local Address:" + (_localAddress == null ? "null" : _localAddress) + " Connected:" + networkController.connected;
		}
		private function onMouseClickHandler(e:MouseEvent):void
		{
			switch(e.target.name)
			{
				case "ok":
					_regexp.lastIndex = 0;
					var test:Boolean = _regexp.test(_txt1.text);
					
					_tft.color = test ? 0x000000 : 0xFF0000;						
					_txt1.setTextFormat(_tft);
					_txt1.defaultTextFormat = _tft;
					
					if(test)
						close();
					break;
				
				case "refresh":
					getRemoteDemoConfig();
					break;
				
				case "text_address":
					_tft.color = 0x000000;
					_txt1.setTextFormat(_tft);
					_txt1.defaultTextFormat = _tft;
					break;
			}
		}
		
		/**
		 *	获取远程Demo配置
		 */		
		public function getRemoteDemoConfig():void
		{
			var udpPort:int = port == 0 ? 2000 : port;
			var addrHeader:String = _localAddress.indexOf("192.168.") == 0 ? _localAddress.substr(0, _localAddress.lastIndexOf(".") + 1) : address.substr(0, address.lastIndexOf(".") + 1);
			
			if(_udp == null)
			{
				_udp = new UDPSocket();
				_udp.receive();
				_udp.addEventListener(DatagramSocketDataEvent.DATA, onDatagramSocketDataHandler, false, 0, true);
			}
			
			var bytes:ByteArray = new ByteArray();
			bytes.writeUTFBytes("func=getDemo");
			if(_owner.hasOwnProperty("demoName") && _owner.demoName != null)
				bytes.writeUTFBytes("&args=" + _owner.demoName);
			
			trace("udp broadcast.");
			if(Capabilities.os.toLowerCase().indexOf("iphone") == -1)
			{
				_udp.send(bytes, addrHeader + "255", udpPort);
			}
			else
			{
				for(var i:int = 1; i < 255; i ++)
					setTimeout(_udp.send, i * 10, bytes, addrHeader + i.toString(), udpPort);
			}
		}
		private function onDatagramSocketDataHandler(e:DatagramSocketDataEvent):void
		{
			trace(e.srcAddress, e.srcPort);		
			
			setTimeout(disposeUDP, 500);
			_txt1.text = e.srcAddress + (e.srcPort != 2000 ? ":" + e.srcPort : "");		//默认端口不显示
		}
		private function disposeUDP():void
		{
			if(_udp != null)
			{
				_udp.close();
				_udp.removeEventListener(DatagramSocketDataEvent.DATA, onDatagramSocketDataHandler);
				_udp = null;
			}
			
			close();
		}
		
		/**
		 *	显示窗口 
		 */		
		public function show():void
		{
			_owner.setChildIndex(_window, _owner.numChildren - 1);
			
			_window.visible = true;
			_window.mouseEnabled = true;
			_window.mouseChildren = true;
			
			//trace(networkController.connected);
			if(networkController)
				_txt0.text = "Local Address:" + (_localAddress == null ? "null" : _localAddress) + " Connected:" + networkController.connected;
		}
		
		/**
		 *	关闭窗口 
		 */		
		public function close():void
		{
			_window.visible = false;
			_window.mouseEnabled = false;
			_window.mouseChildren = false;
			
			SOCookie.setCookie(_cookieName, "address", _txt1.text);
			
			var closeEvent:Event = new Event(Event.CLOSE, false, true);
			this.dispatchEvent(closeEvent);
			if(closeEvent.isDefaultPrevented())	return;
			
			if(networkController)
			{
				networkController.connect(address, port);
				_txt0.text = "Local Address:" + (_localAddress == null ? "null" : _localAddress) + " Connected:" + networkController.connected;
			}
		}
		
		/**
		 *	获取远程地址 
		 * @return 
		 */		
		public function get address():String
		{
			var addr:String = _txt1.text.indexOf(":") == -1 ? _txt1.text : _txt1.text.split(":")[0];	
			_regexp.lastIndex = 0;
			addr = _regexp.test(addr) ? addr : null;
			
			return 	addr;
		}
		
		/**
		 *	获取远程控制端口 
		 *	@return 
		 */		
		public function get port():int
		{
			return _txt1.text.indexOf(":") == -1 ? 2000 : int(_txt1.text.split(":")[1]);
		}
		
		/**
		 *	获取远程文件端口 
		 * 	@return 
		 */		
		public function get filePort():int{		return 8086;		}
	
		/**
		 *	获取输入文本框 
		 * 	@return 
		 */		
		protected static function getTextField(txt:String, width:int, height:int, size:int = 22, background:Boolean = false):TextField
		{
			var tft:TextFormat = new TextFormat("微软雅黑", size, background ? 0x000000 : 0xFFFFFF);
			tft.align = "right";
			
			var textField:TextField = new TextField();
			textField.width = width;
			textField.height = height;
			//textField.border = true;
			textField.selectable = false;
			if(background)
			{
				tft.align = "left";
				textField.type = "input";
				textField.background = true;
				textField.backgroundColor = 0xFFFFFF;
				textField.selectable = true;
				textField.restrict = "0-9.:";
				textField.maxChars = 22;
			}
			textField.defaultTextFormat = tft;
			textField.setTextFormat(tft);
			textField.text = txt;
			
			return textField;
		}
		
	}
}