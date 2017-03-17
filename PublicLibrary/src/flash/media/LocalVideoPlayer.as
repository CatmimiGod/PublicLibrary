package flash.media
{	
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.events.VideoPlayerEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.Timer;
	
	[Event(name="complete", type="flash.events.Event")]
	
	[Event(name="progress", type="flash.events.ProgressEvent")]
	
	[Event(name="cue_point", type="flash.events.VideoPlayerEvent")]	
	
	[Event(name="state_change", type="flash.events.VideoPlayerEvent")]
	
	[Event(name="video_complete", type="flash.events.VideoPlayerEvent")]	
	
	/**
	 * 轻量级本地视频播放器
	 * 具有播放状态，节点事件，自动硬解码
	 */
	public final class LocalVideoPlayer extends StageVideoProxy
	{
		private var _state:String;
		private var _source:String;
		private var _pausing:Boolean = false;
		private var _playing:Boolean = false;
		
		private var _cueLength:uint = 0;
		private var _cuePoints:Vector.<Number>;
		private var _cuePointsLog:Vector.<Number>;
		
		protected var _netStream:NetStream;
		protected var _netConnection:NetConnection;
		
		private var _metadata:Object;
		private var _xmpdata:Object;
		private var _duration:Number = 0;
		private var _framerate:int = 0;
		
		private var _timer:Timer;
		
		
		/**
		 *	本地视频对象 
		 * @param width
		 * @param height
		 * @param index
		 */		
		public function LocalVideoPlayer(width:int=320, height:int=240, index:int=0)
		{
			super(width, height, index);
			initialize();
		}
		
		//initialize.
		private function initialize():void
		{
			var client:Object = {onBWDone:onBWDone, onMetaData:onMetaData, onCuePoint:onCuePoint, onXMPData:onXMPData};
			_netConnection = new NetConnection();
			_netConnection.connect(null);
			
			_netStream = new NetStream(_netConnection);
			_netStream.client = client;
			_netStream.inBufferSeek = true;
			_netStream.addEventListener(NetStatusEvent.NET_STATUS, onNetStatusEventHandler);
			
			_cuePointsLog = new Vector.<Number>();
			_timer = new Timer(20);
			_timer.addEventListener(TimerEvent.TIMER, onTimerEventHandler);
			
			super.attachNetStream(_netStream);
		}
		private function onNetStatusEventHandler(e:NetStatusEvent):void
		{
			_state = e.info.code;	//trace(_state);
			switch(_state)
			{
				case "NetStream.Play.Start":
					_timer.start();
					_playing = true;
					break;
				
				case "NetStream.Play.Stop":
					_playing = false;
					_timer.reset();
					_netStream.pause();					
					
					this.dispatchEvent(new Event(Event.COMPLETE));
					this.dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.COMPLETE));
					break;
				
				case "NetStream.Pause.Notify":
					_timer.reset();
					_pausing = true;
					_playing = false;
					break;
				
				case "NetStream.Unpause.Notify":
					_timer.start();
					_pausing = false;
					_playing = true;
					break;
				
				case "NetStream.SeekStart.Notify":
				case "NetStream.Seek.Notify":
					break;
				
				case "NetStream.Seek.Complete":
					if(_pausing)
						_netStream.resume();		
					break;				
			}
			
			this.dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.STATE_CHANGE));
		}
		private function onTimerEventHandler(e:TimerEvent):void
		{
			this.dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.UPDATE));
			this.dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, _netStream.time, _duration));
			
			//CuePoint Event
			if(_cuePoints == null || _cueLength == 0)		return;
			
			if(_cuePointsLog.length != _cueLength)
			{
				_cuePointsLog.fixed = false;
				_cuePointsLog.length = _cueLength;
				_cuePointsLog.fixed = true;
			}
			
			var dec:uint;
			var pos:Number;
			var time:Number = _netStream.time;
			
			for(var i:int = 0; i < _cueLength; i ++)
			{
				dec = getDecimalPlaces(_cuePoints[i].toString());	//获取原设置节点的小数点位
				pos = Math.floor(time * dec) / dec;		//计算当前位置的数据点，与设置的小数点位相同
				
				//计算值是否相等，如果相等就记录下来，如果不相等则记录为0
				if(_cuePoints[i] == pos && _cuePointsLog[i] != pos)
				{
					_cuePointsLog[i] = pos;
					this.dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.CUE_POINT, false, false, _cuePoints[i], i, time, 0));
					break;
				}
				else
				{
					if(_cuePointsLog[i] != pos)
						_cuePointsLog[i] = 0;
				}
			}
		}
		
		/**
		 *	  返回小数点后面的N个0000，例如:小数2.33返回100， 2.3333返回10000
		 */
		protected static function getDecimalPlaces(num:String):uint
		{
			var dec:int = 1;
			var len:int = num.indexOf(".") != -1 ? num.split(".")[1].length : 0;
			
			if(len > 0)
			{
				for(var i:int = 0; i < len; i ++)
					dec *= 10;
			}
			
			return dec;
		}
				
		/**
		 * 播放本地视频
		 */
		public function play(url:String = null):void
		{
			_playing = true;
			
			if(url != null)
			{
				clear();
				_source = url;
				_netStream.play(url);
				return;
			}
			
			if(url == null && _pausing)
				_netStream.resume();
		}
		
		/**
		 * 暂停视频
		 */
		public function pause():void
		{
			_netStream.pause();
		}
		
		/**
		 * 播放暂停
		 */
		public function togglePause():void
		{
			_netStream.togglePause()
		}
		
		/**
		 * 停止视频
		 */
		public function stop():void
		{
			_timer.reset();
			_netStream.pause();
			
			_cueLength = 0;
			_cuePoints = null;			
			
			_metadata = null;
			_xmpdata = null;
			_duration = 0;
			_framerate = 0;
			
			_state = null;
			_source = null;
			_pausing = false;
			_playing = false;
		}
		
		/**
		 * Clear.
		 */
		override public function clear():void
		{
			stop();
			
			super.clear();			
			_netStream.close();
			_netStream.dispose();
		}
		
		/**
		 * 跳到指定的时间节点处播放
		 */
		public function seek(offset:Number):void
		{
			_netStream.seek(offset);
		}
		
		/**
		 * 添加节点
		 */
		public function addCuePoint(time:Number):void
		{
			if(_cuePoints == null)
				_cuePoints = new Vector.<Number>();
			
			_cuePoints.fixed = false;
			_cuePoints.push(time);
			_cueLength = _cuePoints.length;
			_cuePoints.fixed = true;
		}		
		
		/** 视频播放头位置*/
		public function get playheadTime():Number{	return _netStream.time;		}
		public function set playheadTime(value:Number):void
		{
			seek(value);
		}
		
		/** 获取视频总时长*/
		public function get totalTime():Number{		return _duration;		}
		
		/** 获取视频metadata信息*/
		public function get metadata():Object{	return _metadata;	}
		
		/** 视频播放状态*/
		public function get playing():Boolean{	return _playing;		}
		
		
		//-----------------------------------------------------------------client
		private function onBWDone(info:Object = null):void
		{
			//trace(info);
		}
		private function onMetaData(info: Object):void
		{
			_metadata = info;
			
			_duration = info.duration;
			_framerate = info.framerate;
			
			/*
			trace("onMetadata");
			for(var prop:String in info)
				trace(prop + ">>" + info[prop]);
			//trace("metadata: duration=" + info.duration + " width=" + info.width + " height=" + info.height + " framerate=" + info.framerate);
			*/
		}
		private function onCuePoint(info: Object):void
		{
			trace("cuepoint: time=" + info.time + " name=" + info.name + " type=" + info.type);
		}
		private function onXMPData(info:Object):void
		{
			_xmpdata = info;
			
			/*
			trace("onXMPData");
			for(var prop:String in info)
				trace(prop + ">>" + info[prop]);
			*/
		}
		
	}
}