package flash.display
{
	import flash.display.NativeWindow;
	import flash.events.Event;
	
	/**
	 * 
	 *  始终显示在其他窗口前面的窗口容器对象，此窗口透明无边框且永远置顶
	 * 	@author Administrator
	 * 
	 * @example 示例:
	 * <listing version="3.0">
	 * 
	 * var exitBtn:MovieClip = new ExitButtonMovieClip() as MovieClip;	//库中的显示对象
	 * exitBtn.addEventListener(MouseEvent.CLICK, onMouseClickHandler);
	 * exitBtn.name = "exitBtn";
	 * 
	 * private function onMouseClickHandler(e:MouseEvent):void
	 * {
	 * 		var tn:String = e.target.name;
	 * 		trace(tn);
	 * }
	 *  
	 * exitWindowButton = new NativeWindowContainers(this);
	 * exitWindowButton.y = 200;
	 * exitWindowButton.stage.addChild(exitBtn);	//将显示对象添加到窗口中
	 * exitWindowButton.activate();
	 * 
	 * </listing>
	 * 
	 */	
	public class NativeWindowContainers extends NativeWindow
	{
		/**	模型对象，或是顶级窗口的显示对象	*/
		protected var model:Object;
		
		/**
		 * Constructor.
		 * 
		 * @param model 模型对象，或是顶级窗口的显示对象
		 * @param content 此窗口是的显示对象，可为空，使用 NativeWindowContainers.stage.addChild(content) 添加显示对象;
		 */
		public function NativeWindowContainers(model:Object, content:Sprite = null)
		{
			//init Options
			var initOptions:NativeWindowInitOptions = new NativeWindowInitOptions();
			initOptions.systemChrome = "none";
			initOptions.transparent = true;
			initOptions.type = "utility";
			super(initOptions);	
			
			initializeWindows();
			
			if(content != null)
				this.stage.addChild(content);
			
			this.model = model;
			//主窗口关闭时，关闭exitWindowButton窗口
			if(model != null && model.hasOwnProperty("stage"))
			{
				model.stage.nativeWindow.addEventListener(Event.CLOSING, onModelWindowClosingHandler, false, 0, true);
				model.stage.nativeWindow.addEventListener(Event.ACTIVATE, onNativeWindowEventHandler, false, 0, true);
				model.stage.nativeWindow.addEventListener(Event.DEACTIVATE, onNativeWindowEventHandler, false, 0, true);
			}
		}
		
		/**
		 *	initialize windows
		 */
		private function initializeWindows():void
		{
			this.x = 0;
			this.y = 0;
			this.visible = true;
			this.alwaysInFront = true;
			this.title = "Native Window Containers";
			
			this.stage.align = StageAlign.TOP_LEFT;
			this.stage.showDefaultContextMenu = true;
			this.stage.scaleMode = StageScaleMode.NO_SCALE;
			
			this.addEventListener(Event.CLOSING, onNativeWindowEventHandler);
			this.addEventListener(Event.ACTIVATE, onNativeWindowEventHandler);
			this.addEventListener(Event.DEACTIVATE, onNativeWindowEventHandler);
		}
		
		/**
		 *	Native window event handler.
		 */
		private function onNativeWindowEventHandler(e:Event):void
		{
			//trace(e.type);
			switch(e.type)
			{
				case Event.ACTIVATE:
				case Event.DEACTIVATE:
					//窗口没有被关闭&&窗口可见
					if(!this.closed && this.visible)
					{
						this.alwaysInFront = true;
						this.orderToFront();
					}
					break;
				
				case Event.CLOSING:
					e.preventDefault();		//取消窗口关闭
					break;
			}
		}
		
		private function onModelWindowClosingHandler(e:Event):void
		{
			this.close();
		}
	}
}