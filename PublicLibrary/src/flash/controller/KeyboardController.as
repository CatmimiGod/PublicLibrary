package flash.controller
{
	import flash.events.KeyboardEvent;
	import flash.standard.IKeyboardController;
	import flash.system.Capabilities;
	import flash.system.System;
	import flash.utils.getDefinitionByName;

	/**
	 *	本地键盘控制器 
	 * @author Administrator
	 */	
	public final class KeyboardController implements IKeyboardController
	{
		/**	
		 * 	是否忽略执行错误，默认为 true
		 * 	@default true	
		 */
		public var ignoreError:Boolean = true;
		
		//配置
		private var _config:XML;
		//显示对象
		private var _model:Object;
		
		
		/**
		 *	Constructor.	键盘控制器 
		 * 
		 * @param model	视图对象
		 * @param config	键盘控制配置
		 * 
		 * <listing version="3.0">
		 *  //键盘控制
		 *	var keyboardController:KeyboardController = new KeyboardController(this, _config.keyboard[0]);
		 *	keyboardController.addKeyItem("E", "demo.exit");
		 * </listing>
		 */		
		public function KeyboardController(model:Object, config:XML = null)
		{
			if(model == null)
				throw new ArgumentError("KeyboardController model参数不能为空。");
			
			_model = model;
			parseConfig(config);
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
		 * &lt;keyboard enabled="true" hookKeyboard="false" listenerKeyUp="true" listenerKeyDown="false" lockEsc="false"&gt;
		 *	 &lt;key type="keyUp" name="L" code="76" func="setLanguage" args="cn" /&gt;
		 * &lt;/keyboard&gt;
		 * </listing>
		 */			
		public function parseConfig(config:XML):void
		{
			if(config == null || _config != null)		return;
			
			if(config.hasOwnProperty("@enabled") && config.@enabled.toLowerCase() != "true")	return;			
			_config = config.copy();
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
			//trace(_config.toXMLString());			
			if(_config.hasOwnProperty("@enabled") && _config.@enabled.toString().toLowerCase() != "true")		return;
			
			/**
			 * @internal	默认是监听keyUp事件
			 */
			var listenerKeyUp:Boolean = _config.@listenerKeyUp.toLowerCase() == "true";
			var listenerKeyDown:Boolean = _config.@listenerKeyDown.toLowerCase() == "true"; 
			
			/**
			 * @internal	如果是桌面程序，优先监听应用程序
			 */
			if(Capabilities.playerType == "Desktop")
			{
				var Application:Class = getDefinitionByName("flash.desktop.NativeApplication") as Class;
				
				if(listenerKeyUp)
					Application.nativeApplication.addEventListener(KeyboardEvent.KEY_UP, onKeyboardEventHandler, false, 0, true);
				if(listenerKeyDown)
					Application.nativeApplication.addEventListener(KeyboardEvent.KEY_DOWN, onKeyboardEventHandler, false, 0, true);
			}
			else
			{
				if(listenerKeyUp)
					_model.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyboardEventHandler, false, 0, true);
				if(listenerKeyDown)
					_model.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyboardEventHandler, false, 0, true);
			}
		}
		
		/**
		 *	清理。清理后请将此对象设为null 
		 */		
		public function dispose():void
		{
			if(_config == null)		return;
			
			var listenerKeyUp:Boolean = _config.@listenerKeyUp.toLowerCase() == "true";
			var listenerKeyDown:Boolean = _config.@listenerKeyDown.toLowerCase() == "true"; 
			
			if(Capabilities.playerType == "Desktop")
			{
				var Application:Class = getDefinitionByName("flash.desktop.NativeApplication") as Class;
				
				if(listenerKeyUp)
					Application.nativeApplication.removeEventListener(KeyboardEvent.KEY_UP, onKeyboardEventHandler);
				if(listenerKeyDown)
					Application.nativeApplication.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyboardEventHandler);
			}
			else
			{
				if(listenerKeyUp)
					_model.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyboardEventHandler);
				if(listenerKeyDown)
					_model.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyboardEventHandler);
			}
			
			System.disposeXML(_config);
			
			_model = null;
			_config = null;
		}
		
		/**
		 * 添加键盘控制配置项
		 * 
		 * @param name 需要监听的键字符
		 * @param func
		 * @param args
		 * @param eventType
		 */
		public function addKeyItem(name:String, func:String, args:String = null, eventType:String = KeyboardEvent.KEY_UP):void
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
			//trace(_config.toXMLString());
		}
		
		/**
		 *  @private
		 * 	键盘事件处理
		 */
		private function onKeyboardEventHandler(e:KeyboardEvent):void
		{
			if(_config.hasOwnProperty("@lockEsc") && _config.@lockEsc.toLowerCase() == "true")
				if(e.keyCode == 27)		e.preventDefault();
			
			trace("KeyCode:", e.keyCode, String.fromCharCode(e.keyCode), e.type);
			var key:XMLList = _config.children().(@code == e.keyCode).(@type == e.type);
			
			if(key.length() == 1)
				executeFunc(key[0]);
		}
		
		/**
		 *	执行函数或方法 
		 * @param key	键盘配置项
		 */		
		private function executeFunc(key:XML):void
		{
			if(key == null)		return;
			
			trace(key.toXMLString());
			var func:String = key.hasOwnProperty("@func") ? key.@func : key.hasOwnProperty("@funcName") ? key.@funcName : null;
			if(func == null || func == "")	return;
			
			var args:String = key.hasOwnProperty("@args") ? key.@args : null;
			args = args != null && args.length > 0 ? args : null; 
			
			//executeFuncName(_model, func, args, ignoreError);
			AS.callProperty(_model, func, args, ignoreError);
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