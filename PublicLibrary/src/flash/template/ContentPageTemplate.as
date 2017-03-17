package flash.template
{
	import flash.events.Event;
	import flash.standard.IContentPage;
	import flash.display.MovieClip;
	
	/**
	 *	内容页面模版，作参考用，也可以继承此类(针对配置属性cache为true的内容页面，但建议都参考此类)
	 * 	@author Administrator
	 */	
	public class ContentPageTemplate extends MovieClip implements IContentPage
	{
		/**
		 *	Constructor. 
		 */		
		public function ContentPageTemplate()
		{
			this.addEventListener(Event.ADDED_TO_STAGE, onAddedToStageHandler, false, 0, true);
		}
		private function onAddedToStageHandler(e:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStageHandler);
			this.addEventListener(Event.REMOVED_FROM_STAGE, onRemoveFromStageHandler, false, 0, true);
			
			//add to stage
			initialize();
		}
		private function onRemoveFromStageHandler(e:Event):void
		{
			this.removeEventListener(Event.REMOVED_FROM_STAGE, onRemoveFromStageHandler);
			
			//remote from stage
			dispose();
		}
		
		/**
		 *	初使化. 
		 */		
		public function initialize():void
		{
			// do some other thing ......
			throw new Error("抽象方法initialize，需要继承实现具体内容。");
		}
		
		/**
		 *	清理对象. 
		 */
		public function dispose():void
		{			
			// do some other thing ......
			throw new Error("抽象方法dispose，需要继承实现具体内容。");
		}
		
	}
}