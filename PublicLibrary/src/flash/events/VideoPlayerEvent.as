package flash.events
{
	
	/**
	 * VideoPlayer 节点事件 
	 * @author Administrator
	 */	
	public class VideoPlayerEvent extends Event
	{
		public static const CUE_POINT:String = "cue_point";
		
		public static const UPDATE:String = "video_update";
		
		public static const COMPLETE:String = "video_complete";
		
		public static const STATE_CHANGE:String = "state_change";
		
		/**
		 *	视频ID 
		 */		
		public var videoID:int;
		
		/**
		 *	视频当前位置 
		 */		
		public var position:Number;
		
		/**
		 *	提示点位置 
		 */		
		public var cuePoint:Number;
		
		/**
		 *	提示点ID 
		 */		
		public var cuePointID:int;
		
		/**
		 *	Constructor. 
		 * @param type
		 * @param bubbles
		 * @param cancelable
		 * @param cuePoint
		 * @param cuePointID
		 * @param position
		 * @param videoID
		 */		
		public function VideoPlayerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, cuePoint:Number = 0, cuePointID:int = -1, position:Number = 0, videoID:int = -1)
		{
			this.cuePoint = cuePoint;
			this.cuePointID = cuePointID;
			
			this.position = position;
			this.videoID = videoID;
			
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			return new VideoPlayerEvent(type, bubbles, cancelable);
		}
		
		override public function toString():String
		{
			return super.formatToString("VideoPlayerEvent", type, bubbles, cancelable, cuePoint, position, videoID);
		}
	}
}