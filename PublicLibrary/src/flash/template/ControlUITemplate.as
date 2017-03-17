package flash.template
{
	import flash.display.MovieClip;
	import flash.standard.IControlUI;
	
	/**
	 *	控制UI页面模版，作参考用，也可以继承此类
	 * 	@author Administrator
	 */		
	public class ControlUITemplate extends MovieClip implements IControlUI
	{
		/**	视频图或模型对象	*/
		protected var viewModel:Object;
		
		/**
		 *	Constructor. 
		 */		
		public function ControlUITemplate()
		{
			
		}
		
		/**
		 *	设置控制目标 
		 * 	@param model
		 */		
		public final function setTarget(viewModel:Object):void
		{
			this.viewModel = viewModel;
		}
	
		/**
		 *	语言切换 ，继承实现此方法 
		 * 	@param lang
		 */		
		public function setLanguage(lang:String):void
		{
			if(this.viewModel == null)		return;
			
			// do some other thing ......
		}
		
	}
}