package flash.template
{
	import flash.controller.NetworkClientController;
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;
	import flash.display.ConfigWindow;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	
	/**
	 *	Demo Controller Template	移动端网络控制通用模板 
	 * @author Administrator
	 */	
	public class DemoControllerTemplate extends MovieClip
	{
		/**	DemoName 控制目标的Demo名称	*/
		public var demoName:String;
		/** 配置窗口		*/
		protected var configWindow:ConfigWindow;
		/**	网络控制器	*/
		protected var networkController:NetworkClientController;
		
		/**
		 *	Constructor. 
		 */	
		public function DemoControllerTemplate(demoName:String = null)
		{
			this.demoName = demoName;	
			
			networkController = new NetworkClientController(this, null);
			configWindow = new ConfigWindow(this, this.networkController);	
			
			initialize();
		}
		
		/**
		 *	initialize. <br />
		 * 	setting stage property and native applicate some properties
		 */		
		protected function initialize():void
		{
			/**
			 * @internal
			 * 避免左右或上下留空边，移动端添加缩放,因为华为PAD都有虚拟按键条
			 */
			stage.align = StageAlign.TOP_LEFT;
			//stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.scaleMode = StageScaleMode.EXACT_FIT;
			stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			
			/**
			 * @internal
			 * 如果需要退出后断开连接添加以下代码
			 */
			NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
			NativeApplication.nativeApplication.addEventListener(Event.ACTIVATE, onNativeApplicationEventHandler);
			NativeApplication.nativeApplication.addEventListener(Event.DEACTIVATE, onNativeApplicationEventHandler);
		}
		
		/**
		 *	设置语言 
		 * @param lang
		 */		
		public function setLanguage(lang:String = null):void
		{
		}
		
		/**
		 *	连接Demo对象，留作Server端调用的接口
		 * @param address
		 * @param port
		 */		
		public function connect(address:String, port:int):void
		{
			if(networkController == null)	return;
			
			if(networkController.connected)
				networkController.close();
			
			networkController.connect(address, port);
		}
		
		/**
		 * 	NativeApplication events handler
		 * 	@param e
		 */
		protected function onNativeApplicationEventHandler(e:Event):void
		{
			switch(e.type)
			{
				case Event.ACTIVATE:
					//还原窗体时，重新连接服务器
					if(networkController && !networkController.connected)
						networkController.connect(configWindow.address, configWindow.port);
					break;
				
				case Event.DEACTIVATE:
					//最小化时，断开连接
					if(networkController && networkController.connected)
						networkController.close();
					break;
			}
		}
		
	}
}