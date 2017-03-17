package flash.controller
{
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.MouseEvent;
	import flash.system.Capabilities;
	import flash.ui.Mouse;
	import flash.utils.setTimeout;

	/**
	 *	Demo Controller 
	 * @author Administrator
	 */	
	public final class DemoController
	{
		private var _demo:Sprite;
		private var _mouseHide:Boolean = false;
		
		/**
		 *	 Constructor.
		 * 	@param demo
		 */		
		public function DemoController(demo:Sprite, stageConfig:XML = null)
		{
			_demo = demo;
			parseConfig(stageConfig);
		}
		
		/**
		 *	解析场景配置 
		 * @param value
		 */		
		public function parseConfig(stageConfig:XML):void
		{
			if(_demo == null || stageConfig == null)	return;
			
			/** @internal	是否可用鼠标进行场景交互	
			if(stageConfig.hasOwnProperty("@mouseEnabled"))
				_demo.mouseEnabled = _demo.mouseChildren = stageConfig.@mouseEnabled == "true";
			*/
			
			/** @internal	是否隐藏鼠标光标	*/
			if(stageConfig.hasOwnProperty("@mouseHide") && stageConfig.@mouseHide == "true")
			{
				Mouse.hide();
				
				_mouseHide = true;
				_demo.mouseEnabled = _demo.mouseChildren = false;
			}
			
			/** @internal	是否隐藏鼠标光标	*/
			if(stageConfig.hasOwnProperty("@hideMouse") && stageConfig.@hideMouse == "true")
			{
				Mouse.hide();
				
				_mouseHide = true;
				_demo.mouseEnabled = _demo.mouseChildren = false;
			}
			
			/** @internal 是否全屏锁定	*/
			if(Capabilities.playerType != "ActiveX" && Capabilities.playerType != "PlugIn" && stageConfig.hasOwnProperty("displayState") && stageConfig.displayState.toString().indexOf("fullScreen") != -1)
			{
				if(stageConfig.displayState.hasOwnProperty("@lock") && stageConfig.displayState.@lock == "true")
				{
					_demo.stage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreenEventHandler);
				}
			}
			
			/** @internal	程序位置X	*/
			if(stageConfig.hasOwnProperty("@x"))
			{
				_demo.stage.nativeWindow.x = Number(stageConfig.@x);
			}
			
			/** @internal	程序位置Y	*/
			if(stageConfig.hasOwnProperty("@y"))
			{
				_demo.stage.nativeWindow.y = Number(stageConfig.@y);
			}
			
			/**	 @internal 遍历属性	*/
			for each(var node:XML in stageConfig.children())
			{
				var prop:String = node.localName();
				if(prop != null)
				{
					if(prop == "displayState")
						_demo.stage[prop] = Capabilities.playerType == "ActiveX" || Capabilities.playerType == "PlugIn" ? StageDisplayState.NORMAL : stageConfig[prop]; 
					else
						_demo.stage[prop] = stageConfig[prop];
				}
			}
			
			if(Capabilities.playerType == "Desktop")
			{
				_demo.stage.addEventListener(MouseEvent.RIGHT_CLICK, onMouseRightEventHandler);
			}
		}
		
		/**	右键切换鼠标显示或隐藏	*/
		private function onMouseRightEventHandler(e:MouseEvent):void
		{
			_mouseHide = !_mouseHide;
			
			_mouseHide ? Mouse.hide() : Mouse.show();
			_demo.mouseEnabled = _demo.mouseChildren = !_mouseHide;
		}
		
		/**	 @private 	窗口尺寸调整事件*/		
		private function onFullScreenEventHandler(e:Event):void
		{
			setTimeout(fullScreenInteractive, 10);
		}
		private function fullScreenInteractive():void
		{
			if(_demo.stage.displayState != StageDisplayState.FULL_SCREEN_INTERACTIVE)
				_demo.stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
		}
	
		
		/**
		 *	Demo启动文件 
		 * @param filePath
		 */		
		public function startup(filePath:String):void
		{
			
		}
		
		/**	
		 * 退出演示程序，此方法只针对Window系统
		 */	
		public function exit():void
		{
			DemoUtils.exit();
		}
		
		/**	
		 * 重启演示程序，此方法只针对Window系统，且项目文件中有/modules/process.exe模块
		 */		
		public function restart():void
		{
			DemoUtils.restart();
		}
		
		/**
		 *	关机 
		 */		
		public function shutdown(args:String = "-r||-s"):void
		{
			
		}
		
	}
}