package flash.standard
{
	import flash.events.IEventDispatcher;

	/**
	 *	Flash Demo应用程序 
	 * 	@author Administrator
	 */	
	public interface IDemoApplication extends IEventDispatcher
	{
		/**
		 *	设置语言.
		 * <b>此方法只用于外部调用或远程调用的语言切换接口</b><br />
		 * @param lang	语言字符简小写; 如果为空，则语言切换到上一种语言(中英文反转)
		 */
		function setLanguage(lang:String = null):void;
		
		/**
		 *	获取Demo语言类型 
		 * 	@return 
		 */		
		function get language():String;
	}
}