package flash.standard
{
	import flash.events.IEventDispatcher;
	
	/**
	 *	内容页面接口，页面指单个swf文件
	 * @author Administrator
	 */	
	public interface IContentPage extends IEventDispatcher
	{
		/**
		 *	初使化对象. 
		 */		
		function initialize():void;
		
		/**
		 *	清理对象. 
		 */		
		function dispose():void;
	}
}