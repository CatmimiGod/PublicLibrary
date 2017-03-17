package flash.media
{
	import flash.events.Event;
	import flash.events.StageVideoEvent;
	import flash.events.VideoEvent;
	import flash.geom.Rectangle;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.media.StageVideo;
	import flash.net.NetStream;
	
	[Event(name="change", type="flash.events.Event")]
	
	/**
	 *	StageVideoProxy 
	 *	@author Administrator
	 */	
	public class StageVideoProxy extends Video
	{
		private var m_camera:Camera;
		private var m_stream:NetStream;
		private var stageVideo:StageVideo; 
		
		private var _index:int = 0;
		//private static var INDEX:int = 0;
		private var _status:String = VideoEvent.RENDER_STATUS_UNAVAILABLE;
		
		/**
		 *	Constructor. 
		 * @param width
		 * @param height
		 * @param index
		 */		
		public function StageVideoProxy(width:int=320, height:int=240, index:int = 0)
		{
			super(width, height);
			super.smoothing = true;
			
			this._index = index;
			
			this.addEventListener(Event.ADDED_TO_STAGE, this.onAddedToStage);
			this.addEventListener(Event.REMOVED_FROM_STAGE, this.onRemovedFromStage);
		} 
		
		/**
		 * @inhertDoc.
		 */
		override public function set x(value:Number):void
		{
			if(value != this.x)
			{
				super.x = value;
				this.layoutView();
			}
		} 
		/**
		 * @inhertDoc.
		 */
		override public function set y(value:Number):void
		{
			if(value != this.y)
			{
				super.y = value;
				this.layoutView();
			}
		} 
		
		/**
		 * @inhertDoc.
		 */
		override public function set width(value:Number):void
		{
			if(value != this.width)
			{
				super.width = value;
				this.layoutView();
			}
		} 
		
		/**
		 * @inhertDoc.
		 */
		override public function set height(value:Number):void
		{
			if(value != this.height)
			{
				super.height = value;
				this.layoutView();
			}
		} 
		
		/**
		 * @inhertDoc.
		 */
		override public function get videoHeight():int
		{
			return this.stageVideo ? this.stageVideo.videoHeight : super.videoHeight;
		} 
		
		/**
		 * @inhertDoc.
		 */
		override public function get videoWidth():int
		{
			return this.stageVideo ? this.stageVideo.videoWidth : super.videoWidth;
		} 
		
		/**
		 * @inhertDoc.
		 */
		override public function attachNetStream(p_stream:NetStream):void
		{
			if(p_stream != this.m_stream)
			{
				this.dispose();
				
				this.m_stream = p_stream;				
				this.setupStageVideo();
			}
		}
		
		/**
		 * @inhertDoc.
		 */
		override public function attachCamera(p_camera:Camera):void
		{
			if(p_camera != this.m_camera)
			{
				this.dispose();
				
				this.m_camera = p_camera;				
				//this.setupStageVideo();
				this.setupSpriteVideo();
			}
		}
		
		/**	获取视频渲染状态	*/
		public function get status():String{		return this._status;		}
		
		public function set index(value:uint):void{		_index = value;		}
		public function get index():uint{		return _index;		}
		
		/**
		 * 设置使用Video对象
		 */
		protected function setupSpriteVideo():void
		{		
			this.stageVideo = null;
			
			if(this.m_camera)	
			{
				super.attachCamera(this.m_camera);		
				return;
			}
			if(this.m_stream)	
				super.attachNetStream(this.m_stream);
			
			trace("sprite video:", this.width, this.height);
		}
		
		/**
		 * 如果支持,设置使用StageVideo对象
		 */
		protected function setupStageVideo():void
		{	
			if(!this.stage)		return;
			if(!this.m_camera && !this.m_stream ) return;
			
			if(_index < 0)
			{
				this.setupSpriteVideo();
				return;
			}
			
			try
			{
				if(!this.stageVideo && this.stage.stageVideos.length >= 1)
				{					
					this.stageVideo = this.stage.stageVideos[_index];
					this.stageVideo.addEventListener(StageVideoEvent.RENDER_STATE, onRenderStateChanged);
					this.layoutView();
					
					trace("StageVideo", _index, this.stageVideo.viewPort);
				}
				
				if(this.stageVideo)
				{
					if(this.m_camera)	
					{
						this.stageVideo["attachCamera"](this.m_camera);	
						return;
					}
					if(this.m_stream)	this.stageVideo.attachNetStream(this.m_stream);
				}
				else
				{
					this.setupSpriteVideo();
				}
			}
			catch(error:Error)
			{
				trace("StageVideoProxy setupStageVideo Error", error);
				this.setupSpriteVideo();
			}
		}
		
		/**
		 * 清理对象
		 */
		protected function dispose():void
		{	
			try
			{
				if(this.stageVideo)
				{
					this.stageVideo.viewPort = new Rectangle(this.x, this.y, 0, 0);
					this.stageVideo["attachCamera"](null);
					this.stageVideo.attachNetStream(null);					
				}
				else if(this.m_stream || this.m_camera)
				{
					super.attachCamera(null);
					super.attachNetStream(null);
					this.clear();
				}
				
				this.m_camera = null;
				this.m_stream = null;
			}
			catch(error:Error)
			{
				trace("StageVideoProxy dispose Error", error);
			}
		}	
		
		/**
		 * 设置StageVideo的绝对位置和大小
		 */
		protected function layoutView():void
		{
			if(this.stageVideo)
				this.stageVideo.viewPort = new Rectangle(this.x, this.y, this.width, this.height);
		}
		
		protected function onAddedToStage(p_event:Event):void
		{
			this.setupStageVideo();
			this.layoutView();
			this.removeEventListener(Event.ADDED_TO_STAGE, this.onAddedToStage);
		}
		
		protected function onRemovedFromStage(p_event:Event):void
		{	
			this.dispose();			
			this.removeEventListener(Event.REMOVED_FROM_STAGE, this.onRemovedFromStage);
			
			if(this.stageVideo)
			{
				this.stageVideo.removeEventListener(StageVideoEvent.RENDER_STATE, onRenderStateChanged);
				this.stageVideo = null;
			}
		}
		
		protected function onRenderStateChanged(e:StageVideoEvent):void
		{
			_status = e.status;
			trace("status:", e.status);
			
			switch(_status)
			{
				case VideoEvent.RENDER_STATUS_UNAVAILABLE: 
					this.dispose();
					this.setupStageVideo();
					break;
			}			
			
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
//		protected function onStageVideoAvailabilityChanged(p_event:Event):void
//		{
//			this.dispose();
//			this.setupStageVideo();
//		}
				
	}
}