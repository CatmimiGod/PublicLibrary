package flash.ext
{
	/**
	 *	视频状态常量 
	 * @author Administrator
	 */	
	public class VideoPlayerState
	{
		
		/**
		 *	未知状态 
		 */		
		public static const UNDEFINED:uint = 0x00;
		
		/**
		 *	停止状态 
		 */		
		public static const STOPPED:uint = 0x01;
		
		/**
		 *	暂停状态 
		 */		
		public static const PAUSED:uint  = 0x02;
		
		/**
		 *	播放状态 
		 */		
		public static const PLAYING:int = 0x03;
		
		/**
		 *	快进状态 
		 */		
		public static const SCANFORWARD:uint = 0x04;
		
		/**
		 *	快退状态 
		 */		
		public static const SCANREVERSE:uint = 0x05;
		
		/**
		 * 缓冲状态
		 */		
		public static const BUFFERING:uint = 0x06;
		
		/**
		 *	 等待状态
		 */		
		public static const WAITING:uint = 0x07;
		
		/**
		 * 媒体结束状态
		 */		
		public static const MEDIA_ENDED:uint = 0x08;
		
		/**
		 *	过渡状态 
		 */		
		public static const TRANSITIONING:uint = 0x09;
		
		/**
		 *	准备状态
		 */		
		public static const READY:uint = 0x10;
		
		/**
		 *	重新连接状态 
		 */		
		public static const RECONNECTION:uint = 0x11;
		
		/**
		 *	最后或持续状态 
		 */		
		public static const LAST:uint = 0x12;
		
	}
}