package flash.template
{
	import flash.controller.DemoController;
	import flash.controller.GlobalKeyboardController;
	import flash.controller.KeyboardController;
	import flash.controller.NetworkClientController;
	import flash.controller.NetworkServerController;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.standard.IDemoApplication;
	import flash.standard.IKeyboardController;
	import flash.standard.INetworkController;
	import flash.system.Capabilities;
	import flash.system.System;
	import flash.utils.getDefinitionByName;
	
	/**
	 *	Demo Application Template 	PC端通用模板
	 * 	@author Huangmin
	 */	
	[SWF(frameRate="25", backgroundColor="0x000000")]
	public class DemoApplicationTemplate extends Sprite implements IDemoApplication
	{
		/**	可用语言列表 @default en,cn	*/
		public static const LANGUAGES:Vector.<String> = new <String>["en", "cn"];
		
		/**	默认语言	*/
		protected var _language:String = "cn";
		//**	是否使用多语言，默认为false	*/
		private var _multiLanuage:Boolean = false;
		
		/**	@private 配置文件路径 */		
		private var _configUrl:String;		
		/**	配置文件数据	*/
		public var configData:XML;
		
		/**	DemoController	*/
		public var demo:DemoController;
		/**	网络控制器	*/
		protected var networkController:INetworkController;		
		/**	键盘控制器	*/
		protected var keyboardController:IKeyboardController;
		
		/**	DemoName	demo名称，唯一的	*/
		public var demoName:String;
		
		/**
		 *	Demo Application Template. 
		 */		
		public function DemoApplicationTemplate(demoName:String = null)
		{
			this.demoName = demoName;
			
			XML.prettyIndent = 4;
			XML.ignoreComments = true;	
			
			if(Capabilities.playerType == "Desktop")
			{
				var Application:Class = getDefinitionByName("flash.desktop.NativeApplication") as Class;
				Application.nativeApplication.addEventListener("exiting", onRemoveFromStage);
				
				//右键隐藏/显示光标
				//启用/禁用鼠标交互
			}
			else
			{
				this.addEventListener(Event.REMOVED_FROM_STAGE, onRemoveFromStage);
			}
		}
		
		/**	加载配置文件 */		
		protected function loaderConfiguration(url:String):void
		{
			_configUrl = url;
			
			var loader:URLLoader = new URLLoader(new URLRequest(_configUrl));
			loader.addEventListener(Event.COMPLETE, onLoaderCompleteHandler, false, 0, true);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderIOErrorHandler, false, 0, true);
		}
		
		/**	@private	配置加载完成	*/
		private function onLoaderCompleteHandler(e:Event):void
		{
			e.target.removeEventListener(Event.COMPLETE, onLoaderCompleteHandler);
			e.target.removeEventListener(IOErrorEvent.IO_ERROR, onLoaderIOErrorHandler);
			
			this.configData = XML(e.target.data);
			this.parseDefaultConfig();
			
			this._configUrl = null;
		}
		
		/**	@private	配置加载错误	*/
		private function onLoaderIOErrorHandler(e:IOErrorEvent):void
		{
			e.target.removeEventListener(Event.COMPLETE, onLoaderCompleteHandler);
			e.target.removeEventListener(IOErrorEvent.IO_ERROR, onLoaderIOErrorHandler);
			
			throw new Error("配置文件加载错误，文件 " + this._configUrl + " 不存在。");
		}
		
		/**	@private	解析默认的配置数据，在initialize()之前。*/		
		private function parseDefaultConfig():void
		{
			demo = new DemoController(this);
			
			/** @internal 设置舞台属性	*/
			if(this.configData.hasOwnProperty("stage"))
				demo.parseConfig(configData.stage[0]);
			
			/**@internal */
			if(this.configData.hasOwnProperty("network"))
			{
				if(configData.network.hasOwnProperty("@enabled") && configData.network.@enabled.toLowerCase() == "true")
				{
					if(this.demoName == null && configData.network.hasOwnProperty("demoName"))
						this.demoName = configData.network.demoName.toString();
					
					var port:int = configData.network.hasOwnProperty("port") ? int(configData.network.port) : 2000;
					var address:String = configData.network.hasOwnProperty("address") ? configData.network.address : "127.0.0.1";
					
					networkController = configData.network.hasOwnProperty("localPort") ?
						new NetworkServerController(this, "0.0.0.0", int(configData.network.localPort)) :
						new NetworkClientController(this, address, port);
				}
			}
			else
			{
				networkController = new NetworkServerController(this);
			}
			
			/**	 @internal 	键盘控制器	*/
			if(this.configData.hasOwnProperty("keyboard"))
			{
				if(configData.keyboard.hasOwnProperty("@enabled") && configData.keyboard.@enabled.toLowerCase() == "true")
				{
					var hookKeyboard:Boolean = configData.keyboard.hasOwnProperty("@hookKeyboard") && configData.keyboard.@hookKeyboard.toLowerCase() == "true";
					keyboardController = hookKeyboard ? new GlobalKeyboardController(this) : new KeyboardController(this);
					keyboardController.parseConfig(configData.keyboard[0]);
				}
			}
			
			/**  @internal 	是否是多语言Demo, 如果是则设置默认显示的语言	*/
			if(configData.hasOwnProperty("content"))
			{
				if(configData.content.hasOwnProperty("@defaultLanguage"))
					_language = this.configData.content.@defaultLanguage.toLowerCase();
				
				_multiLanuage = (configData.content.hasOwnProperty("cn") && configData.content.hasOwnProperty("en")) || configData.toString().indexOf("%LANGUAGE%") != -1;
			}
			
			initialize();
		}
		
		/**	初使化程序	*/		
		protected function initialize():void
		{
			//throw new Error("抽象方法initialize，需要继承实现具体内容。");
		}
		
		/**
		 *	语言 <b>变更完成后</b> 调用；继承时调用，如果没有多语言选择，则不需要继承此方法<br />
		 * 	若想获取当前语言类型，请使用language属性获取
		 */		
		protected function languageChanged():void
		{
			//throw new Error("抽象方法languageChanged，需要继承实现具体内容。");
		}
		
		/**
		 *	设置语言.<b>此方法只用于外部调用或远程调用的语言切换接口，不可继承重写；如需继承重写请使用languageChanged方法</b><br />
		 * @param lang	语言字符简小写; 如果为空，则语言切换到上一种语言(中英文反转)
		 */		
		public final function setLanguage(lang:String = null):void
		{
			if(!_multiLanuage)
			{
				trace("setLanguage(" + lang.toLowerCase() + ") 没有多语言可选择设置。");
				return;
			}
			
			if(lang == null)
			{
				_language = _language == "en" ? "cn" : "en";
				languageChanged();
			}
			else
			{
				lang = lang.toLowerCase();
				if(_language != lang && LANGUAGES.indexOf(lang) != -1)
				{
					_language = lang;
					languageChanged();
				}
			}
		}
		
		/** 当前对象从场景移除时需处理的对象*/
		protected function onRemoveFromStage(e:Event = null):void
		{
			trace("Remove.");
			if(configData)	System.disposeXML(configData);
			if(networkController)	networkController.dispose();			
			if(keyboardController)	keyboardController.dispose();
			
			this.removeEventListener(Event.REMOVED_FROM_STAGE, onRemoveFromStage);
		}
		
		/**	获取当前显示的语言类型	*/
		public function get language():String{	return _language;	}
		
		/**	获取当前Demo是否是多语言类型	*/
		public function get multiLanguage():Boolean{		return _multiLanuage;	}
		
	}
}