package flash.standard
{
	import flash.events.IEventDispatcher;
	
	/**
	 *	内容页面列表接口，指多个显示文件集合
	 * @author Administrator
	 */	
	public interface IContentPagesList extends IEventDispatcher
	{
		
		/**
		 *	加载指定的页面 
		 * 	@param index
		 */		
		function loadPage(index:int):void;
		
		/**
		 *	下一页 
		 */		
		function nextPage():void;
		
		/**
		 *	上一页 
		 */		
		function prevPage():void;
		
		/**
		 *	总页面长度 
		 * @return 
		 */		
		function get length():uint;
		
		/**
		 *	当前面页索引 
		 * @return 
		 */		
		function get selectedIndex():int;
		
	}
}