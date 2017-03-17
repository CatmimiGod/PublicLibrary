package flash.standard
{
	import flash.events.IEventDispatcher;
	
	/**
	 *	控制UI接口，指控制Demo的独立swf文件UI
	 * @author Administrator
	 */	
	public interface IControlUI extends IEventDispatcher
	{
		/**
		 *	设置控制对象 
		 * 	@param viewModel
		 */		
		function setTarget(viewModel:Object):void;
				
		/**
		 *	设置控制UI的显示语言 
		 * 	@param lang
		 */		
		function setLanguage(lang:String):void;
	}
}