package flash.template
{
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	
	[Event(name="complete", type="flash.events.Event")]
	
	/**
	 *	"第三方"显示对象资源库 
	 * 
	 * 	PS:这个类好像没什么鸟用，可以自己在主类里写个Loader也行
	 * 
	 * 	@author Administrator
	 */	
	public final class LoaderLibrary extends EventDispatcher
	{
		//private var _loaderInfo:LoaderInfo;
		
		/**
		 *	 Constructor.
		 * 	@param swfUrl	资源库文件，swf文件
		 */		
		public function LoaderLibrary(swfUrl:String)
		{
			if(swfUrl != null)
			{
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderCompleteEventHandler, false, 0, true);
				
				/**
				 * @internal
				 * 这里加载到的是当前应用域，所以下面获取也是当前应用域
				 * 如果使用自定义域，则使用注释的代码
				 */				
				loader.load(new URLRequest(swfUrl), new LoaderContext(false, ApplicationDomain.currentDomain));
			}
		}
		
		//loader event handler
		private function onLoaderCompleteEventHandler(e:Event):void
		{
			trace("Library Loader Complete .... ");
			
			//_loaderInfo = e.target as LoaderInfo;
			//(e.target as LoaderInfo).loader.unloadAndStop();
			e.target.removeEventListener(Event.COMPLETE, onLoaderCompleteEventHandler);
			
			this.dispatchEvent(new Event(Event.COMPLETE));
		}
		
		/**
		 *	获取资源库连接显示对象 
		 * @param linkName
		 * @return 
		 */		
		public function getLibraryLink(linkName:String):*
		{
			//return new (_loaderInfo.applicationDomain.getDefinition(linkName) as Class)();
			return new (ApplicationDomain.currentDomain.getDefinition(linkName) as Class)();
		}
	}
}