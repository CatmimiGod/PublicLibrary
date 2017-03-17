package flash.standard
{
	import flash.events.IEventDispatcher;
	
	/**
	 *	页面场景列表，指单个swf文件中有多个场景或子页面
	 * @author Administrator
	 */	
	public interface IPageScenesList extends IEventDispatcher
	{
		/**
		 *	跳到指定的场景 
		 * @param index
		 */		
		function gotoScene(index:int):void;
		
		/**
		 *	下一个场景 
		 */		
		function nextScene():void;
		
		/**
		 *	上一个场景 
		 */		
		function prevScene():void;
		
		/**
		 *	总场景数 
		 * 	@return 
		 */		
		function get length():uint;
		
		/**
		 *	当前场景索引 
		 * 	@return 
		 */
		function get selectedIndex():int;
	}
}